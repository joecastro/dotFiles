#!/usr/bin/env python3

# pylint: disable=too-many-arguments, missing-module-docstring, missing-function-docstring, missing-class-docstring, line-too-long

from __future__ import annotations

import argparse
import hashlib
import json
import os
import platform
import plistlib
import re
import shlex
import subprocess
import sys
from dataclasses import dataclass, field, fields, is_dataclass
from datetime import datetime
from functools import partial
from itertools import chain
from pathlib import Path
from textwrap import dedent
from typing import (Any, Callable, Iterable, Optional, Sequence,
                    TypeAlias, cast)


def mingify_path(path: str) -> str:
    path = re.sub(r'\\', '/', path)
    path = re.sub(r'^([A-Za-z]):', lambda m: f'/{m.group(1).lower()}', path)
    return path


def path_is_within(child: Path, parent: Path) -> bool:
    """Return True if `child` is located within `parent` (inclusive of deeper descendants).

    Resolves both paths to handle symlinks/relative segments. Returns False on mismatch.
    """
    try:
        child.resolve().relative_to(parent.resolve())
        return True
    except Exception:
        return False

CWD: Path = Path.cwd()
OS_CWD = mingify_path(os.getcwd())
OUT_DIR_ROOT: Path = CWD / 'out'
HOME_VAR_PATH = Path('"${HOME}"')
DOTFILES_CONFIG_ROOT = Path(os.environ.get('DOTFILES_CONFIG_ROOT', Path.home() / '.config/' / 'dotShell'))
XDG_CONFIG_HOME = Path(os.environ.get('XDG_CONFIG_HOME', Path.home() / '.config'))

DECLARE_SCRIPT_DIR_LINE = 'SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"'
SCRIPTDIR_VAR_PATH = Path('"${SCRIPT_DIR}"')

# Fixup mDNS hostname mangling on macOS
LOCALHOST_NAME = platform.uname().node if not platform.uname().node.endswith('.local') else platform.uname().node[:-6]

LOCALHOST_KERNEL = platform.uname().system.lower()

BASH_COMMAND_PREFIX = 'BASH_COMMAND: '

# Global flag toggled by CLI to influence Jsonnet ext vars
TRACE_STARTUP_FLAG = False


def make_shell_command(run_args: list[str]) -> str:
    def sanitize_arg(arg: str) -> str:
        if ' ' in arg or '$' in arg:
            return '"' + arg.replace('"', '') + '"'
        return arg

    return ' '.join([sanitize_arg(arg) for arg in run_args])


def capture_infocmp_definition(term: str) -> tuple[Optional[str], Optional[str]]:
    """Return the output of ``infocmp -x <term>`` or a warning string."""

    try:
        result = subprocess.run(
            ['infocmp', '-x', term],
            check=True,
            capture_output=True,
            text=True,
        )
    except FileNotFoundError:
        return None, 'WARN: infocmp not found; skipping Ghostty terminfo embedding.'
    except subprocess.CalledProcessError as exc:
        stderr = (exc.stderr or exc.stdout or str(exc)).strip()
        details = f' ({stderr})' if stderr else ''
        return None, f'WARN: infocmp failed for {term}{details}; skipping Ghostty terminfo embedding.'

    output = result.stdout.rstrip('\n')
    if not output:
        return None, f'WARN: infocmp returned no data for {term}; skipping Ghostty terminfo embedding.'

    return output, None

def json_ready(obj: Any) -> Any:
    if is_dataclass(obj):
        return {f.name: json_ready(getattr(obj, f.name)) for f in fields(obj)}
    elif isinstance(obj, dict):
        typed_obj = cast(dict[Any, Any], obj)
        return {json_ready(k): json_ready(v) for k, v in typed_obj.items()}
    elif isinstance(obj, (list, tuple)):
        seq = cast(list[Any], list(obj)) # type: ignore
        return [json_ready(item) for item in seq]
    elif isinstance(obj, set):
        return sorted(list(obj)) # type: ignore
    else:
        return obj

RunCmd: TypeAlias = list[str]
RunThunk: TypeAlias = Callable[[], Any]
RunOp: TypeAlias = str | RunCmd | RunThunk


@dataclass
# pylint: disable-next=too-many-instance-attributes
class Host:
    hostname: str
    config_dir: str
    home: str
    branch: Optional[str] = None
    kernel: str = 'linux'
    stage_only: bool = False
    file_maps: dict[str, str] = field(default_factory=dict[str, str])
    directory_maps: dict[str, str] = field(default_factory=dict[str, str])
    jsonnet_maps: dict[str, str] = field(default_factory=dict[str, str])
    jsonnet_multi_maps: dict[str, str] = field(default_factory=dict[str, str])
    curl_maps: dict[str, str] = field(default_factory=dict[str, str])
    macros: dict[str, list[str]] = field(default_factory=dict[str, list[str]])

    prestaged_files: set[str] = field(default_factory=set[str])
    prestaged_directories: set[str] = field(default_factory=set[str])

    is_localhost: bool = field(init=False, default=False)
    connection_host: Optional[str] = None
    aliases: list[str] = field(default_factory=list[str])
    # Host out layout
    local_out_dir: Path = field(init=False, default=Path())
    local_staging_dir: Path = field(init=False, default=Path())  # final staged files
    local_jsonnet_dir: Path = field(init=False, default=Path())  # cache for jsonnet outputs
    local_curl_dir: Path = field(init=False, default=Path())     # cache for curl downloads
    cache_json_path: Path = field(init=False, default=Path())
    remote_staging_dir: str = field(init=False, default='')
    # Cache validity flags computed on init
    jsonnet_cache_valid: bool = field(init=False, default=False)
    curl_cache_valid: bool = field(init=False, default=False)

    def __post_init__(self):

        self.home = mingify_path(self.home)
        if self.hostname == 'localhost':
            self.hostname = LOCALHOST_NAME
        if self.hostname == LOCALHOST_NAME:
            self.kernel = LOCALHOST_KERNEL
        raw_file_maps = self.file_maps
        self.file_maps = dict(raw_file_maps)
        # Promote jsonnet maps into file/directory maps without exposing cache dirs
        # Final staged paths are 'dest' directly; generation happens into cache dirs.
        promoted_jsonnet_entries: list[tuple[str, str, str]] = []
        if isinstance(self.jsonnet_maps, list):
            for (src, dest, target) in self.jsonnet_maps:
                self.file_maps[dest] = target
                self.prestaged_files.add(dest)
                promoted_jsonnet_entries.append((src, dest, target))
            self.jsonnet_maps = {src: dest for (src, dest, _) in promoted_jsonnet_entries}
        else:
            self.jsonnet_maps = dict(self.jsonnet_maps)

        # Promote jsonnet multicast directories similarly
        self.directory_maps = dict(self.directory_maps)
        promoted_multi_entries: list[tuple[str, str, str]] = []
        if isinstance(self.jsonnet_multi_maps, list):
            for (src, dest_dir, target_dir) in self.jsonnet_multi_maps:
                self.directory_maps[dest_dir] = target_dir
                self.prestaged_directories.add(dest_dir)
                promoted_multi_entries.append((src, dest_dir, target_dir))
            self.jsonnet_multi_maps = {src: dest_dir for (src, dest_dir, _) in promoted_multi_entries}
        else:
            self.jsonnet_multi_maps = dict(self.jsonnet_multi_maps)

        # Promote curl maps without exposing cache dirs
        promoted_curl_entries: list[tuple[str, str, str]] = []
        if isinstance(self.curl_maps, list):
            for (src, dest, target) in self.curl_maps:
                self.file_maps[dest] = target
                self.prestaged_files.add(dest)
                promoted_curl_entries.append((src, dest, target))
            self.curl_maps = {src: dest for (src, dest, _) in promoted_curl_entries}
        else:
            self.curl_maps = dict(self.curl_maps)

        values_to_coerce = [k for k, v in self.file_maps.items() if v.endswith('/')]
        for key in values_to_coerce:
            self.file_maps[key] = f'{self.file_maps[key]}{os.path.basename(key)}'

        self.is_localhost = self.hostname == LOCALHOST_NAME
        seen_aliases: set[str] = set()
        normalized_aliases: list[str] = []
        for candidate in [self.hostname, *self.aliases]:
            if not candidate:
                continue
            key = candidate.lower()
            if key in seen_aliases:
                continue
            seen_aliases.add(key)
            normalized_aliases.append(candidate)
        self.aliases = normalized_aliases
        self.connection_host = self.connection_host or self.hostname
        # Define host out layout
        self.local_out_dir = OUT_DIR_ROOT / f'{self.hostname}-dot'
        self.local_staging_dir = self.local_out_dir / 'staged'
        self.local_jsonnet_dir = self.local_out_dir / 'gen'
        self.local_curl_dir = self.local_out_dir / 'curl'
        self.cache_json_path = self.local_out_dir / 'cache.json'
        self.remote_staging_dir = f'{self.home}/{self.config_dir}-staging'

        # Establish cache validity on creation
        previous_hashes = self.read_cache_hashes()
        prev_jsonnet = previous_hashes.get('jsonnet_inputs_hash', '')
        prev_curl = previous_hashes.get('curl_inputs_hash', '')
        curr_jsonnet = self.compute_jsonnet_inputs_hash()
        curr_curl = self.compute_curl_inputs_hash()
        self.jsonnet_cache_valid = (
            curr_jsonnet == prev_jsonnet
            and self.local_jsonnet_dir.is_dir()
            and self._cached_jsonnet_outputs_exist()
        )
        self.curl_cache_valid = (
            curr_curl == prev_curl
            and self.local_curl_dir.is_dir()
            and self._cached_curl_outputs_exist()
        )

    def _cached_jsonnet_outputs_exist(self) -> bool:
        file_targets = [
            self.local_jsonnet_dir / rel_path
            for rel_path in self.jsonnet_maps.values()
        ]
        dir_targets = [
            self.local_jsonnet_dir / rel_dir
            for rel_dir in self.jsonnet_multi_maps.values()
        ]
        return all(path.is_file() for path in file_targets) and all(path.is_dir() for path in dir_targets)

    def _cached_curl_outputs_exist(self) -> bool:
        return all(
            (self.local_curl_dir / rel_path).is_file()
            for rel_path in self.curl_maps.values()
        )


    def __repr__(self) -> str:
        return self.hostname

    def compute_jsonnet_inputs_hash(self) -> str:
        """Compute a hash over Jsonnet-related inputs for this host.

        Includes ext vars, entry file names (maps + multimaps), and the content
        of all *.jsonnet/*.libsonnet files under source_dir excluding OUT_DIR_ROOT.
        """
        root = Path(CWD)
        out_root = OUT_DIR_ROOT.resolve()

        hasher = hashlib.sha256()

        # Include ext vars
        ext_vars = get_ext_vars(self)
        hasher.update(json.dumps(ext_vars, sort_keys=True).encode('utf-8'))

        # Entry file names for stability
        entry_files = sorted(set(self.jsonnet_maps.keys()) | set(self.jsonnet_multi_maps.keys()))
        for entry in entry_files:
            hasher.update(entry.encode('utf-8'))

        # Hash Jsonnet sources outside OUT_DIR_ROOT
        candidates = [p for p in root.rglob('*.jsonnet') if not path_is_within(p, out_root)]
        candidates += [p for p in root.rglob('*.libsonnet') if not path_is_within(p, out_root)]
        candidates.sort()
        for p in candidates:
            with open(p, 'rb') as f:
                hasher.update(f.read())

        return hasher.hexdigest()

    def read_cache_hashes(self) -> dict[str, str]:
        try:
            with open(self.cache_json_path, 'r', encoding='utf-8') as f:
                return json.load(f)
        except FileNotFoundError:
            return {}
        except json.JSONDecodeError:
            return {}

    def compute_curl_inputs_hash(self) -> str:
        """Compute a hash over curl-related inputs for this host.

        Since remote content is unknown here, this captures the mapping of
        source URLs to staged destination paths. Changing either triggers a refresh.
        """
        hasher = hashlib.sha256()
        # Normalize ordering for stability
        items = sorted(self.curl_maps.items(), key=lambda kv: kv[0])
        for src, staged in items:
            hasher.update(src.encode('utf-8'))
            hasher.update(staged.encode('utf-8'))
        return hasher.hexdigest()

    def update_cache_hashes(self) -> None:
        current = {
            'jsonnet_inputs_hash': self.compute_jsonnet_inputs_hash(),
            'curl_inputs_hash': self.compute_curl_inputs_hash(),
        }
        self.cache_json_path.parent.mkdir(parents=True, exist_ok=True)
        with open(self.cache_json_path, 'w', encoding='utf-8') as f:
            json.dump(current, f, indent=4, sort_keys=True)


    def get_inflated_macro(self, key: str, file_path: Path, pragma_arg: Optional[str] = None) -> list[str]:
        """Inflate a macro template defined in Jsonnet with built-in tokens.

        Supported tokens in templates:
        - @@FILE_NAME   -> uppercased stem of the file name being processed
        - @@NOW         -> current timestamp (YYYY-MM-DD HH:MM)
        - @@PRAGMA_ARG  -> argument following the pragma on the source line
        """
        arg_value = pragma_arg or ''
        now_value = datetime.now().strftime("%Y-%m-%d %H:%M")
        file_stem_upper = file_path.stem.upper()
        return [
            v.replace('@@FILE_NAME', file_stem_upper)
             .replace('@@NOW', now_value)
             .replace('@@PRAGMA_ARG', arg_value)
            for v in self.macros.get(key, [])
        ]

    def make_ops(self, ops: list[RunOp]) -> list[RunOp]:
        if self.is_localhost:
            return list(ops)

        converted: list[RunOp] = []
        for op in ops:
            if isinstance(op, list):
                op = cast(list[str], op)
                converted.append(['ssh', self.connection_host or self.hostname, make_shell_command(op)])
            elif isinstance(op, str):
                converted.append(op)
            else:
                raise TypeError('Callable operations cannot be proxied through SSH')
        return converted

    def add_alias(self, alias: Optional[str]) -> None:
        if not alias:
            return
        alias_key = alias.lower()
        if alias_key not in {a.lower() for a in self.aliases}:
            self.aliases.append(alias)

    def matches_token(self, token: str) -> bool:
        token_lower = token.lower()
        return token_lower in self._identifier_tokens()

    def _identifier_tokens(self) -> set[str]:
        tokens = {self.hostname.lower()}
        for alias in self.aliases:
            tokens.add(alias.lower())
        if self.connection_host:
            tokens.add(self.connection_host.lower())
            if '@' in self.connection_host:
                tokens.add(self.connection_host.split('@', 1)[-1].lower())
        return tokens


@dataclass
class Ec2WorkstationMetadata:
    instance_id: str
    volume_id: str
    instance_name: str
    instance_type: str
    region: str
    security_group: str
    key_name: str
    tag_key: str
    tag_value: str
    root_volume_size: int
    data_volume_size: int
    ssh_public_key: str
    ssh_cidr: str
    public_ip: str
    public_dns: str

    METADATA_PATH = XDG_CONFIG_HOME / '.ec2-devbox-meta.json'

    def __post_init__(self):
        if not self.public_ip:
            raise ValueError('Workstation metadata missing public_ip; cannot establish SSH connection')

    @staticmethod
    def load() -> Optional[Ec2WorkstationMetadata]:
        if not Ec2WorkstationMetadata.METADATA_PATH.is_file():
            return None

        with open(Ec2WorkstationMetadata.METADATA_PATH, 'r', encoding='utf-8') as f:
            data: dict[str, Any] = json.load(f)

        values: dict[str, Any] = {}
        valid_keys = {f.name for f in fields(Ec2WorkstationMetadata)}

        def merge_payload(payload: dict[str, str]) -> None:
            for key, value in payload.items():
                if key in valid_keys:
                    values[key] = value

        merge_payload(data)

        config_payload = data.get('config')
        if isinstance(config_payload, dict):
            config_payload = cast(dict[str, str], config_payload)
            merge_payload(config_payload)
        elif config_payload is not None:
            raise ValueError('EC2 workstation config must be a JSON object')

        return Ec2WorkstationMetadata(**values)

@dataclass
class Config:
    hosts: list[Host]
    workspace_overrides: dict[str, Any]
    vim_pack_plugin_start_repos: list[str]
    vim_pack_plugin_opt_repos: list[str]
    zsh_plugin_repos: list[str]

    @staticmethod
    def load() -> 'Config':
        """Parse and instantiate the apply configuration from Jsonnet."""
        config_path = Path.cwd() / 'apply_configs.jsonnet'
        if not config_path.is_file():
            raise ValueError(f'Missing config file: {config_path}')

        ext_vars = get_ext_vars()

        config_dict: dict[str, Any] = cast(dict[str, Any], parse_jsonnet_now(config_path, ext_vars))

        hosts_raw: list[dict[str, Any]] = config_dict.get('hosts', [])

        config_dict['hosts'] = [Host(**host) for host in hosts_raw]
        return Config(**config_dict)


    def get_localhost(self) -> Optional[Host]:
        return next((h for h in self.hosts if h.is_localhost), None)

    def find_host(self, token: Optional[str]) -> Optional[Host]:
        if token is None:
            return None
        token_lower = token.lower()
        for host in self.hosts:
            if host.matches_token(token_lower):
                return host
        return None

    def update(self, metadata: Ec2WorkstationMetadata) -> None:
        host = next(h for t in (metadata.instance_name, metadata.instance_id, 'ec2-workstation')
                    if (h := self.find_host(t)))

        host.add_alias('ec2-workstation')
        host.add_alias(metadata.public_ip)
        host.connection_host = f'ubuntu@{metadata.public_ip}'

        if metadata.instance_name:
            host.add_alias(metadata.instance_name)
        if metadata.instance_id:
            host.add_alias(metadata.instance_id)


def print_ops(ops: list[RunOp], quiet: bool = False) -> None:
    for entry in ops:
        if isinstance(entry, str):
            if entry.startswith(BASH_COMMAND_PREFIX):
                raise ValueError('Bash commands should be executed through a script')
            if not quiet:
                print(entry)
        elif isinstance(entry, list):
            entry = cast(list[str], entry)
            print(f'DEBUG: {" ".join(entry)}')
        elif callable(entry):
            func = getattr(entry, 'func', None)
            keywords = getattr(entry, 'keywords', None)
            if func and isinstance(keywords, dict):
                func_args = ', '.join(f"{k}={v}" for k, v in keywords.items()) # type: ignore
                print(f'DEBUG: invoking {func.__name__}({func_args})')
            else:
                fallback_name = getattr(entry, '__name__', repr(entry))
                print(f'DEBUG: invoking {fallback_name}()')
        else:
            raise TypeError('Unsupported operation type')


def run_ops(ops: list[RunOp], quiet: bool = False) -> None:
    for entry in ops:
        if isinstance(entry, str):
            if entry.startswith(BASH_COMMAND_PREFIX):
                raise ValueError('Bash commands should be executed through a script')
            if not quiet:
                print(entry)
        elif isinstance(entry, list):
            if not all(isinstance(arg, str) for arg in entry): # type: ignore
                raise TypeError(f'All elements of a command list must be strings: {entry}')
            entry = cast(list[str], entry)
            try:
                subprocess.run(make_shell_command(entry), shell=True, check=True)
            except subprocess.CalledProcessError:
                print(f'Failed running: {" ".join(entry)}')
                raise
            except FileNotFoundError:
                # Hacky workaround for running in Cygwin.
                if entry[0] == '/bin/bash':
                    print(f'! Failed running: "{" ".join(entry)}". Try again from the command line.')
                else:
                    raise
        elif callable(entry):
            entry()
        else:
            raise TypeError('Unsupported operation type')


def update_workspace_extensions() -> None:
    repo_workspace_extensions_location = 'vscode/dotFiles_extensions.json'

    completed_proc = subprocess.run(['code', '--list-extensions'], check=True, capture_output=True, text=True)
    installed_extensions = completed_proc.stdout.splitlines()
    if installed_extensions[0].startswith('Extensions installed on WSL'):
        raise ValueError('Running this way is not supported. Use the WSL terminal.')

    extensions_node = {
        'recommendations': sorted(installed_extensions, key=str.lower)
    }

    with open(repo_workspace_extensions_location, 'w', encoding='utf-8') as f:
        json.dump(extensions_node, f, indent=4, sort_keys=True)


def update_workspace_settings() -> None:
    repo_settings_path = Path('vscode/dotFiles_settings.json')
    if not repo_settings_path.is_file():
        raise FileNotFoundError(f'Missing repository workspace settings: {repo_settings_path}')

    localhost = config.get_localhost()
    if localhost is None:
        raise ValueError('Local host not defined; cannot update VSCode settings')

    template_path = 'vscode/user_settings.jsonnet'
    target_jsonnet_entry = localhost.jsonnet_maps.get(template_path)
    if not target_jsonnet_entry:
        raise ValueError('Local host does not define a VSCode user settings Jsonnet mapping')

    target_file_entry = localhost.file_maps.get(target_jsonnet_entry)
    if not target_file_entry:
        raise ValueError('Local host does not define a VSCode user settings file mapping')

    source_path = Path(target_file_entry)
    if not source_path.is_absolute():
        source_path = Path.home() / source_path
    if not source_path.is_file():
        raise FileNotFoundError(f'VSCode settings not found at {source_path}')

    with open(source_path, encoding='utf-8') as f:
        host_settings = json.load(f)
    if not isinstance(host_settings, dict):
        raise TypeError('VSCode settings JSON must evaluate to an object')

    with open(repo_settings_path, encoding='utf-8') as f:
        repo_settings = json.load(f)
    if not isinstance(repo_settings, dict):
        raise TypeError('Repository VSCode settings JSON must evaluate to an object')

    def merge_maps(primary: Any, secondary: Any) -> Any:
        if isinstance(primary, dict) and isinstance(secondary, dict):
            primary = cast(dict[Any, Any], primary)
            secondary = cast(dict[Any, Any], secondary)
            merged: dict[Any, Any] = {key: merge_maps(primary[key], secondary.get(key)) for key in primary}
            for key, value in secondary.items():
                if key not in merged:
                    merged[key] = value
            return merged
        return cast(Any, primary)

    merged_settings = merge_maps(host_settings, repo_settings)

    with open(repo_settings_path, 'w', encoding='utf-8') as f:
        json.dump(merged_settings, f, indent=4, sort_keys=True)
        f.write('\n')

    print(f'Updated {repo_settings_path.as_posix()} from {source_path.as_posix()}')


def generate_derived_workspace() -> None:
    if not config.workspace_overrides:
        print('Skipping workspace generation because no overrides were specified.')
        return

    workspace = {}
    with open('vscode/dotFiles_settings.json', encoding='utf-8') as ws_settings:
        workspace['settings'] = json.load(ws_settings)
    with open('vscode/dotFiles_extensions.json', encoding='utf-8') as ws_extensions:
        workspace['extensions'] = json.load(ws_extensions)

    workspace['folders'] = config.workspace_overrides.get('folders', [])
    if config.workspace_overrides.get('settings'):
        workspace['settings'].update(config.workspace_overrides['settings'])

    print(json.dumps(workspace, indent=4, sort_keys=True))


def generate_hosts_config() -> None:
    print(json.dumps(json_ready(config), indent=4, sort_keys=True))


def get_plugin_relative_target_path(repo: str) -> Path:
    match = re.search(r"([^/]+)\.git$", repo)
    if not match:
        raise ValueError(f'Invalid repository URL: {repo}')
    target_suffix = Path(match.group(1))

    # To prevent these from being deleted on push, keep them out of the dotShell config directory.
    directory_prefixes = {
        'vim_start': Path('.vim/pack/plugins/start'),
        'vim_opt': Path('.vim/pack/plugins/opt'),
        'zsh_ext': Path('.config/zshext'),
    }

    if repo in config.vim_pack_plugin_start_repos:
        target_prefix = directory_prefixes['vim_start']
    elif repo in config.vim_pack_plugin_opt_repos:
        target_prefix = directory_prefixes['vim_opt']
    elif repo in config.zsh_plugin_repos:
        target_prefix = directory_prefixes['zsh_ext']
    else:
        raise ValueError(f'Unknown plugin repository: {repo}')

    return target_prefix / target_suffix


def make_install_plugins_bash_commands(plugin_type: str, repo_list: list[str], install_root: Path) -> list[RunOp]:
    ops: list[RunOp] = []
    ops.append(f'>> Updating {len(repo_list)} {plugin_type}')

    # Remove any surrounding quotes because this is consistently wrapping the combined paths.
    install_root = Path(install_root.name.replace('"', ''))

    repo_targets = [(install_root / get_plugin_relative_target_path(repo), repo) for repo in repo_list]
    directories_to_ensure = {t.parent for t, _ in repo_targets}
    dir_ops = ensure_directories_exist_ops(directories_to_ensure)
    for cmd in dir_ops:
        ops.append(BASH_COMMAND_PREFIX + make_shell_command(cast(RunCmd, cmd)))

    for target_path, repo in repo_targets:
        bash_command_block = dedent(f'''\
            if [ -d "{target_path}" ]; then
                cd "{target_path}"
            if [ -f .git/FETCH_HEAD ] && find .git/FETCH_HEAD -mtime -1 >/dev/null 2>&1; then
                echo "Skipping recent fetch: {target_path}"
            else
                git pull
            fi
            cd - > /dev/null
            else
            git clone "{repo}" "{target_path}"
            fi
            ''')
        for line in bash_command_block.splitlines():
            ops.append(BASH_COMMAND_PREFIX + line)

    return ops


def remove_parents_from_set(paths: set[Path]) -> set[Path]:
    return {d for d in paths if not any(subdir != d and path_is_within(subdir, d) for subdir in paths)}


def ensure_directories_exist_ops(paths: Iterable[Path | str], already_exists_ok: bool = True) -> list[RunOp]:
    normalized_paths = {
        path if isinstance(path, Path) else Path(path)
        for path in paths
    }
    targets = sorted(remove_parents_from_set(normalized_paths))
    ops: list[RunOp] = []
    if not already_exists_ok:
        ops.extend([['rm', '-rf', t.as_posix()] for t in targets])
    ops.extend([['mkdir', '-p', t.as_posix()] for t in targets])
    return ops


def remove_children_from_set(paths: set[str]) -> list[str]:
    return sorted({d for d in paths if not any(subdir != d and d.startswith(subdir) for subdir in paths)})


def copy_directories_local(
    source_root: Path | str,
    source_dirs: Iterable[str],
    dest_root: Path | str,
    dest_dirs: Iterable[str],
) -> list[RunOp]:
    src_root_path = source_root if isinstance(source_root, Path) else Path(source_root)
    dest_root_path = dest_root if isinstance(dest_root, Path) else Path(dest_root)
    source_dir_list = list(source_dirs)
    dest_dir_list = list(dest_dirs)

    ops: list[RunOp] = []
    ops.extend(ensure_directories_exist_ops({(dest_root_path / d) for d in dest_dir_list}))
    ops.extend([
        ['cp', '-a', (src_root_path / src).as_posix() + '/.', (dest_root_path / dest).as_posix()]
        for src, dest in zip(source_dir_list, dest_dir_list)
    ])

    return ops


def parse_jsonnet_now(jsonnet_file: Path, ext_vars: dict[str, str], output_string: bool = False) -> dict[str, Any] | list[Any] | str:
    try:
        result = subprocess.run(
            parse_jsonnet(jsonnet_file, ext_vars, None, output_string=output_string),
            capture_output=True,
            check=True,
            text=True
        )
        return result.stdout if output_string else json.loads(result.stdout)
    except subprocess.CalledProcessError as e:
        print(f"Error running jsonnet command: {make_shell_command(parse_jsonnet(jsonnet_file, ext_vars, None))}")
        print(f"Error details: {e.stderr}")
        raise


def parse_jsonnet(jsonnet_file: Path, ext_vars: dict[str, str], output_path: Optional[Path] = None, is_multicast: bool = False, output_string: bool = False) -> list[str]:
    proc_args = ['jsonnet']

    if output_string or (output_path and (output_path.suffix == '.sh' or output_path.suffix == '.ini')):
        proc_args.append('-S')

    if output_path:
        proc_args.extend(['-m', output_path.as_posix()] if is_multicast else ['-o', output_path.as_posix()])

    for key, val in ext_vars.items():
        proc_args.extend(['-V', f'{key}={val}'])

    proc_args.append(jsonnet_file.as_posix())
    return proc_args


def get_ext_vars(host: Optional[Host] = None) -> dict[str, str]:
    standard_ext_vars = {
        'is_localhost': 'true',
        'hostname': LOCALHOST_NAME,
        'kernel': LOCALHOST_KERNEL,
        'cwd': OS_CWD,
        'home': str(Path.home()),
        'trace_startup': str(TRACE_STARTUP_FLAG).lower(),
        'ec2_workstation_hostname': '',
    }
    if host:
        standard_ext_vars.update({
            'is_localhost': str(host.is_localhost).lower(),
            'hostname': host.hostname,
            'kernel': host.kernel,
        })
    return standard_ext_vars


def preprocess_curl_files(host: Host, verbose: bool = False) -> list[RunOp]:
    if not host.curl_maps:
        return [cast(RunOp, 'No curl maps found')]

    full_paths = {src: (host.local_curl_dir / dest) for src, dest in host.curl_maps.items()}
    ops: list[RunOp] = []
    ops.extend(ensure_directories_exist_ops({p.parent for p in full_paths.values()}))

    # Build robust curl commands that fail on HTTP errors and verify file exists
    def make_curl_check_cmd(src: str, dest: Path) -> RunCmd:
        flags = ['-fL']  # fail on HTTP errors, follow redirects
        if not verbose:
            flags.extend(['-s', '-S'])  # silent but show errors
        curl_cmd = ['curl', *flags, '-o', dest.as_posix(), src]

        # Verify the output file is non-empty; remove if invalid
        quoted_dest = shlex.quote(dest.as_posix())
        quoted_src = shlex.quote(src)
        check_snippet = (
            f"[ -s {quoted_dest} ] || {{ echo 'ERROR: Failed to download ' {quoted_src} '->' {quoted_dest} 1>&2; rm -f {quoted_dest}; exit 1; }}"
        )
        # Use sh -c to chain commands with a post-check
        return ['sh', '-c', f"{make_shell_command(curl_cmd)} && {check_snippet}"]

    ops.extend([make_curl_check_cmd(src, dest) for src, dest in full_paths.items()])

    return ops


def preprocess_jsonnet_files(host: Host, source_dir: Path, staging_dir: Path, verbose: bool = False) -> list[RunOp]:
    if not host.jsonnet_maps:
        return [cast(RunOp, 'No jsonnet maps found')]

    full_paths = [(source_dir / src, staging_dir / dest) for src, dest in host.jsonnet_maps.items()]

    ops: list[RunOp] = []
    ops.extend(ensure_directories_exist_ops({p.parent for _, p in full_paths}))
    jsonnet_commands: list[RunOp] = [parse_jsonnet(src, get_ext_vars(host), dest) for src, dest in full_paths]

    if verbose:
        annotated_jsonnet_commands: list[RunOp] = [
            make_shell_command(cast(RunCmd, cmd)) for cmd in jsonnet_commands
        ]
        interleaved: list[RunOp] = []
        for annotation, command in zip(annotated_jsonnet_commands, jsonnet_commands):
            interleaved.append(annotation)
            interleaved.append(command)
        jsonnet_commands = interleaved

    ops.extend(jsonnet_commands)
    return ops

def preprocess_jsonnet_directories(host: Host, source_dir: Path, staging_dir: Path, verbose: bool=False) -> list[RunOp]:
    if not host.jsonnet_multi_maps:
        return [cast(RunOp, 'No jsonnet multimaps found')]

    full_paths: list[tuple[Path, Path]] = [(source_dir / src, staging_dir / dest) for src, dest in host.jsonnet_multi_maps.items()]
    staging_dests = {p for _, p in full_paths}

    ops: list[RunOp] = []
    ops.extend(ensure_directories_exist_ops(staging_dests))
    jsonnet_commands: list[RunOp] = [
        parse_jsonnet(src, get_ext_vars(host), dest, is_multicast=True, output_string=True) for src, dest in full_paths
    ]

    if verbose:
        annotated_jsonnet_commands: list[RunOp] = [
            f"DEBUG: {make_shell_command(cast(RunCmd, cmd))}" for cmd in jsonnet_commands
        ]
        interleaved_dirs: list[RunOp] = []
        for annotation, command in zip(annotated_jsonnet_commands, jsonnet_commands):
            interleaved_dirs.append(annotation)
            interleaved_dirs.append(command)
        jsonnet_commands = interleaved_dirs

    ops.extend(jsonnet_commands)
    return ops


# TODO: There were guards here to avoid copying files onto themselves
# in the cygwin case prior to Path conversions. Investigate that when I'm back on Windows.
def copy_files_local(
    source_root: Path | str,
    source_files: Iterable[str],
    dest_root: Path | str,
    dest_files: Iterable[str],
    annotate: bool = False,
) -> list[RunOp]:
    src_root_path = source_root if isinstance(source_root, Path) else Path(source_root)
    dest_root_path = dest_root if isinstance(dest_root, Path) else Path(dest_root)
    source_list = list(source_files)
    dest_list = list(dest_files)

    full_path_sources = [src_root_path / src for src in source_list]
    full_path_dests = [dest_root_path / dest for dest in dest_list]

    ops: list[RunOp] = []
    ops.extend(ensure_directories_exist_ops({dest.parent for dest in full_path_dests}))

    copy_ops: list[RunOp]
    copy_ops = [['cp', src.as_posix(), dest.as_posix()] for src, dest in zip(full_path_sources, full_path_dests)]
    if annotate:
        annotated_copy_ops: list[RunOp] = [f"DEBUG: {make_shell_command(cast(RunCmd, cmd))}" for cmd in copy_ops]
        interleaved: list[RunOp] = []
        for debug_line, command in zip(annotated_copy_ops, copy_ops):
            interleaved.append(debug_line)
            interleaved.append(command)
        copy_ops = interleaved

    ops.extend(copy_ops)
    return ops


def make_finish_script(command_ops: Sequence[RunOp], script_path: Path, verbose: bool) -> list[RunOp]:
    def write_script() -> None:
        with open(script_path, 'w', encoding='utf-8') as f:
            f.write('#!/bin/bash\n\n')
            f.write('set -e\n\n')
            if verbose:
                f.write('set -x\n\n')
            f.write(DECLARE_SCRIPT_DIR_LINE + '\n\n')
            for op in command_ops:
                if isinstance(op, str):
                    line = op[len(BASH_COMMAND_PREFIX):] if op.startswith(BASH_COMMAND_PREFIX) else f'echo "{op}"'
                elif isinstance(op, list):
                    line = make_shell_command(cast(RunCmd, op))
                else:
                    raise TypeError('Finish script operations must be strings or command lists')
                f.write(line + '\n')

    ops: list[RunOp] = [partial(write_script)]
    if verbose:
        ops.append(f"DEBUG: Generated finish script at {script_path}")
    ops.append(['chmod', 'u+x', script_path.as_posix()])

    return ops


def clean_remote_dotfiles(host: Host, treat_as_localhost: bool = False) -> list[RunOp]:
    ops: list[RunOp] = []
    ops.append(f'>> Cleaning existing configuration files for {host.hostname}')

    home = Path(host.home) if not treat_as_localhost else HOME_VAR_PATH

    dirs_to_remove = [f"{home}/{d}" for d in remove_children_from_set({host.config_dir}.union(host.directory_maps.values()))]
    files_to_remove = {f"{home}/{f}" for f in host.file_maps.values()}
    files_to_remove = [f for f in remove_children_from_set(files_to_remove.union(dirs_to_remove)) if not f in dirs_to_remove]

    ops.extend([['rm', '-rf', d] for d in dirs_to_remove])
    ops.extend([['rm', '-f', f] for f in files_to_remove])

    if not treat_as_localhost:
        ops = host.make_ops(ops)

    return ops


def push_remote_staging(host: Host) -> list[RunOp]:
    ops: list[RunOp] = []
    ops.append(f'Syncing dotFiles for {host.hostname} from local staging directory')
    ops.append(f'>> Copying {len(host.file_maps) + 1} files and {len(host.directory_maps)} folders to {host.hostname} home directory')
    ops.extend(host.make_ops([['mkdir', '-p', host.remote_staging_dir]]))

    if host.is_localhost:
        ops.extend([
            ['rm', '-rf', host.remote_staging_dir],
            ['mkdir', '-p', host.remote_staging_dir],
            ['cp', '-r', f"{(host.local_staging_dir).as_posix()}/.", host.remote_staging_dir]
        ])
    else:
        ops.append(['rsync', '-axv', '--numeric-ids', '--delete', '--progress', f"{(host.local_staging_dir).as_posix()}/", f'{host.connection_host}:{host.remote_staging_dir}'])

    remote_finish_path = f'{host.remote_staging_dir}/finish.sh'
    ops.append(f'>> Running finish script on {host.hostname}: /bin/bash {remote_finish_path}')
    ops.extend(host.make_ops([['/bin/bash', remote_finish_path]]))

    return ops


def process_macros_for_staged_file(host: Host, file: Path) -> None:
    is_modified = False
    modified_content: list[str] = []
    with open(file, 'r', encoding='utf-8') as f:
        lines = f.read().splitlines()
        for line in lines:
            # Expand macros (supports arguments after the keyword)
            matched_macro = next((k for k in host.macros if line.startswith(k)), None)
            if matched_macro is not None:
                is_modified = True
                pragma_arg = line[len(matched_macro):].strip()
                modified_content.extend(host.get_inflated_macro(matched_macro, file, pragma_arg=pragma_arg))
            else:
                modified_content.append(line)
    if is_modified:
        with open(file, 'w', encoding='utf-8') as f:
            f.writelines(line + '\n' for line in modified_content)


def stage_local(host: Host, verbose: bool = False, skip_cache: bool = False) -> list[RunOp]:
    ops: list[RunOp] = []
    ops.append(f'Staging dotFiles for {host.hostname} in {host.local_staging_dir.as_posix()}')

    # Decide if preprocessing is necessary based on host cache validity
    if skip_cache:
        needs_jsonnet_preprocess = True
        needs_curl_preprocess = True
    else:
        needs_jsonnet_preprocess = not host.jsonnet_cache_valid
        needs_curl_preprocess = not host.curl_cache_valid

    # No need to preserve cache subdirs; they live outside staged output now.

    files_to_stage = [file for file in host.file_maps.keys() if file not in host.prestaged_files]
    directories_to_stage = [directory for directory in host.directory_maps.keys() if directory not in host.prestaged_directories]

    ghostty_terminfo_definition, ghostty_terminfo_warning = capture_infocmp_definition('xterm-ghostty')
    if ghostty_terminfo_warning:
        ops.append(ghostty_terminfo_warning)
    if ghostty_terminfo_definition:
        ops.append('>> Captured Ghostty terminfo definition from local machine')
    else:
        fallback_path = CWD / 'ghostty' / 'xterm-ghostty.terminfo'
        ghostty_terminfo_definition = fallback_path.read_text(encoding='utf-8').rstrip('\n')
        ops.append('>> Using repository Ghostty terminfo fallback for embedding')

    if needs_curl_preprocess:
        ops.append('>> Preprocessing curl files')
        ops.extend(preprocess_curl_files(host, verbose=verbose))
    else:
        ops.append('>> Skipping curl preprocessing (using preserved cache)')

    if needs_jsonnet_preprocess:
        ops.append('>> Preprocessing jsonnet files')
        ops.extend(preprocess_jsonnet_files(host, CWD, host.local_jsonnet_dir, verbose=verbose))
        ops.extend(preprocess_jsonnet_directories(host, CWD, host.local_jsonnet_dir, verbose=verbose))
    else:
        ops.append('>> Skipping jsonnet preprocessing (no source changes)')

    # Persist updated cache hashes (after any preprocessing decisions)
    ops.append(host.update_cache_hashes)

    # Stage prestaged outputs from caches into staging dir
    # - Copy jsonnet directories
    if host.jsonnet_multi_maps:
        ops.extend(copy_directories_local(host.local_jsonnet_dir, host.jsonnet_multi_maps.values(), host.local_staging_dir, host.jsonnet_multi_maps.values()))
    # - Copy jsonnet single-file outputs
    if host.jsonnet_maps:
        src_files = [(host.local_jsonnet_dir / d).as_posix() for d in host.jsonnet_maps.values()]
        dst_paths = [(host.local_staging_dir / d) for d in host.jsonnet_maps.values()]
        dst_files = [p.as_posix() for p in dst_paths]
        ops.extend(ensure_directories_exist_ops({p.parent for p in dst_paths}))
        ops.extend([['cp', s, d] for s, d in zip(src_files, dst_files)])
    # - Copy curl downloads
    if host.curl_maps:
        curl_src_files = [(host.local_curl_dir / d).as_posix() for d in host.curl_maps.values()]
        curl_dst_paths = [(host.local_staging_dir / d) for d in host.curl_maps.values()]
        curl_dst_files = [p.as_posix() for p in curl_dst_paths]
        ops.extend(ensure_directories_exist_ops({p.parent for p in curl_dst_paths}))
        ops.extend([['cp', s, d] for s, d in zip(curl_src_files, curl_dst_files)])

    ops.append('>> Staging directories and files')
    if verbose:
        ops.append(f'Directories to stage: {directories_to_stage}')
        ops.append(f'Files to stage: {files_to_stage}')
    ops.extend(copy_directories_local(CWD, directories_to_stage, host.local_staging_dir, directories_to_stage))
    ops.extend(copy_files_local(CWD, files_to_stage, host.local_staging_dir, files_to_stage))

    if host.macros:
        def is_path_eligible_for_macros(path: Path) -> bool:
            if not path.is_file():
                return False
            return path.suffix.lower() not in {'.png', '.jpg', '.svg', '.jpeg', '.gif'}

        files_to_process: set[Path] = set()

        for file in host.file_maps.keys():
            candidate = host.local_staging_dir / file
            if is_path_eligible_for_macros(candidate):
                files_to_process.add(candidate)

        for directory in directories_to_stage:
            staged_dir = host.local_staging_dir / directory
            if staged_dir.is_dir():
                for candidate in staged_dir.rglob('*'):
                    if is_path_eligible_for_macros(candidate):
                        files_to_process.add(candidate)

        # Include any pre-staged files generated from jsonnet outputs.
        for file in host.prestaged_files:
            candidate = host.local_staging_dir / file
            if is_path_eligible_for_macros(candidate):
                files_to_process.add(candidate)

        if files_to_process:
            ops.append('>> Preprocessing macros in local staged files')
            for f in sorted(files_to_process):
                if verbose:
                    ops.append(f'Processing macros in {f}')
                ops.append(partial(process_macros_for_staged_file, host=host, file=f))

    finish_ops: list[RunOp] = []

    finish_ops.extend(clean_remote_dotfiles(host, treat_as_localhost=True))

    finish_ops.extend(copy_directories_local(SCRIPTDIR_VAR_PATH, host.directory_maps.keys(), HOME_VAR_PATH, host.directory_maps.values()))
    finish_ops.extend(copy_files_local(SCRIPTDIR_VAR_PATH, host.file_maps.keys(), HOME_VAR_PATH, host.file_maps.values()))

    finish_ops.append('>> Installing Ghostty terminfo entry')
    finish_ops.append(BASH_COMMAND_PREFIX + "cat <<'EOF' | tic -x -\n" + ghostty_terminfo_definition + "\nEOF")

    finish_ops.append('>> Updating Vim and Zsh plugins')
    finish_ops.extend(make_install_plugins_bash_commands('Vim startup plugin(s)', config.vim_pack_plugin_start_repos, HOME_VAR_PATH))
    finish_ops.extend(make_install_plugins_bash_commands('Vim operational plugin(s)', config.vim_pack_plugin_opt_repos, HOME_VAR_PATH))
    finish_ops.extend(make_install_plugins_bash_commands('Zsh plugin(s)', config.zsh_plugin_repos, HOME_VAR_PATH))

    finish_script = host.local_staging_dir / 'finish.sh'
    ops.extend(make_finish_script(finish_ops, finish_script, verbose=verbose))

    return ops


def pull_remote(host: Host) -> list[RunOp]:
    snapshot_dir = host.local_staging_dir
    ops: list[RunOp] = []
    ops.append(f'>> Recreating staged dotFiles for {host.hostname}')

    ops.extend(ensure_directories_exist_ops({snapshot_dir}, already_exists_ok=False))
    ops.extend(host.make_ops(ensure_directories_exist_ops({Path(host.remote_staging_dir)}, already_exists_ok=False)))

    remote_ops: list[RunOp] = []
    remote_ops.append('>> Unstaging directories and files')
    remote_ops.extend(copy_directories_local(host.home, host.directory_maps.values(), host.remote_staging_dir, host.directory_maps.keys()))
    remote_ops.extend(copy_files_local(host.home, host.file_maps.values(), host.remote_staging_dir, host.file_maps.keys()))

    unfinish_script_path = snapshot_dir / 'unfinish.sh'
    ops.extend(make_finish_script(remote_ops, unfinish_script_path, verbose=False))

    ops.append(f'>> Copying unfinish script to {host.hostname}')
    if host.is_localhost:
        ops.append(['cp', unfinish_script_path.as_posix(), host.remote_staging_dir])
    else:
        ops.append(['scp', unfinish_script_path.as_posix(), f'{host.connection_host}:{host.remote_staging_dir}'])

    ops.extend(host.make_ops([['/bin/bash', f'{host.remote_staging_dir}/unfinish.sh']]))

    if host.is_localhost:
        ops.append(['cp', '-r', f'{host.remote_staging_dir}/.', snapshot_dir.as_posix()])
    else:
        ops.append(['rsync', '-axv', '--numeric-ids', '--delete', '--progress', f'{host.connection_host}:{host.remote_staging_dir}/', snapshot_dir.as_posix()])

    return ops

def bootstrap_windows() -> list[RunOp]:
    """Apply environment settings for a new Windows machine."""
    return [cast(RunOp, ['SETX', 'DOTFILES_SRC_DIR', OS_CWD])]


def iterm2_prefs_plist_location() -> str:
    """Retrieve the location of the iTerm2 preferences plist file."""
    plist_pref_file_proc = subprocess.run(
        ['defaults', 'read', 'com.googlecode.iterm2', 'PrefsCustomFolder'],
        check=True,
        capture_output=True,
        text=True
    )
    return f'{plist_pref_file_proc.stdout.strip()}/com.googlecode.iterm2.plist'


def build_iterm2_prefs_json() -> dict[str, Any]:
    """Build the iTerm2 preferences from the repo's JSONNet file."""
    ext_vars = get_ext_vars(config.get_localhost())
    metadata = Ec2WorkstationMetadata.load()
    if metadata is not None:
        if metadata.instance_name:
            ext_vars['ec2_workstation_hostname'] = metadata.instance_name
    prefs: dict[str, Any] = parse_jsonnet_now(CWD / 'iterm2/com.googlecode.iterm2.plist.jsonnet', ext_vars) # type: ignore
    return prefs


def snapshot_iterm2_prefs_json(out_path: str = 'out/com.googlecode.iterm2.active.json') -> None:
    """Snapshot the current iTerm2 preferences into a JSON file."""
    print(f'Writing iTerm2 preferences to {out_path}')
    with open(iterm2_prefs_plist_location(), 'rb') as f:
        plist_prefs = plistlib.load(f)
    with open(out_path, 'w', encoding='utf-8') as out:
        json.dump(plist_prefs, out, indent=4, sort_keys=False)


def push_iterm2_prefs() -> None:
    """Build and apply the repo's iTerm2 preferences."""
    localhost = config.get_localhost()
    if localhost is None:
        raise ValueError('Local host not defined; cannot push iTerm2 preferences')
    iterm2_config_root = Path.home() / localhost.config_dir / 'iterm2'
    run_ops([
        ['mkdir', '-p', str(iterm2_config_root)],
        ['defaults', 'write', 'com.googlecode.iterm2', 'PrefsCustomFolder', '-string', str(iterm2_config_root)],
        ['defaults', 'write', 'com.googlecode.iterm2', 'LoadPrefsFromCustomFolder', '-bool', 'true']
    ])

    out_path = iterm2_prefs_plist_location()
    print(f'Writing iTerm2 preferences to {out_path}')
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    with open(out_path, 'wb') as f:
        plistlib.dump(build_iterm2_prefs_json(), f)


def compare_iterm2_prefs() -> None:
    """Compare the current iTerm2 preferences with the generated preferences."""
    snapshot_path = 'out/com.googlecode.iterm2.active.json'
    gen_path = 'out/com.googlecode.iterm2.gen.json'
    snapshot_iterm2_prefs_json(snapshot_path)
    with open(gen_path, 'w', encoding='utf-8') as f:
        json.dump(build_iterm2_prefs_json(), f, indent=4, sort_keys=False)

    print(f'diff {snapshot_path} {gen_path}')


def compare_user_settings(host: Host) -> None:
    """Compare the current user settings with the generated settings."""
    template_path = 'vscode/user_settings.jsonnet'
    target_jsonnet_map_entry = host.jsonnet_maps.get(template_path)
    if not target_jsonnet_map_entry:
        print(f'No vscode user settings for {host.hostname}')
        return

    target_file_map_entry = host.file_maps.get(target_jsonnet_map_entry)
    if not target_file_map_entry:
        raise ValueError(f'No vscode user settings file for {host.hostname}')

    stem = Path(target_jsonnet_map_entry).stem
    gen_path = host.local_staging_dir / f'{stem}.gen.json'
    original_path = Path.home() / target_file_map_entry
    snapshot_path = host.local_staging_dir / f'{stem}.snapshot.json'

    with open(gen_path, 'w', encoding='utf-8') as f:
        gen_user_settings = parse_jsonnet_now(Path(template_path), get_ext_vars(host))
        if not isinstance(gen_user_settings, dict):
            raise TypeError('VSCode user settings Jsonnet must evaluate to an object')
        json.dump(gen_user_settings, f, indent=4, sort_keys=True)

    with open(original_path, encoding='utf-8') as in_path:
        current_settings = json.load(in_path)
    with open(snapshot_path, 'w', encoding='utf-8') as out_path:
        json.dump(current_settings, out_path, indent=4, sort_keys=True)

    print(f'diff "{snapshot_path.as_posix()}" "{gen_path.as_posix()}"')


def push_sublimetext_windows_plugins() -> list[RunOp]:
    """Setup Sublime Text plugins for Windows."""
    return [cast(RunOp, ['cp', 'sublime_text\\*', '%APPDATA%\\Sublime Text 2\\Packages\\User'])]


def push_gnome_settings() -> list[RunOp]:
    """Apply GNOME settings using dconf."""
    dconf_settings = parse_jsonnet_now(
        Path('gnome/dconf_settings.jsonnet'),
        get_ext_vars(config.get_localhost()),
        output_string=True
    )
    if not isinstance(dconf_settings, str):
        raise TypeError('Expected dconf Jsonnet to render to a string')
    subprocess.run(['dconf', 'load'], check=True, input=dconf_settings.encode('utf-8'))
    return [cast(RunOp, 'dconf settings applied')]


def parse_hosts_from_args(host_args: list[str]) -> list[Host]:
    if not host_args:
        return []
    normalized = [arg for arg in host_args if arg not in {'--all', '--local'}]
    if len(host_args) == 1 and host_args[0] == '--all':
        return config.hosts
    if len(host_args) == 1 and host_args[0] == '--local':
        localhost = config.get_localhost()
        if localhost is None:
            raise ValueError('Local host not defined')
        return [localhost]

    hosts: list[Host] = []
    for token in normalized:
        host = config.find_host(token)
        if host is None:
            raise ValueError(f'Unknown host: {token}')
        if host not in hosts:
            hosts.append(host)
    return hosts


config: Config = Config.load()

def main(args: list[str]) -> int:
    """Apply dotFiles operations."""
    host_operations = [
        'clean',
        'pull',
        'push',
        'push-only',
        'stage'
    ]
    workspace_operations = [
        'bootstrap-windows',
        'compare-iterm2-prefs',
        'compare-user-settings',
        'generate-workspace',
        'generate-hosts-config',
        'install-sublime-plugins',
        'push-gnome-settings',
        'push-iterm2-prefs',
        'snapshot-iterm2-prefs',
        'update-workspace-settings',
        'update-workspace-extensions'
    ]
    ec2_workstation_operations = {
        'push-ec2-workstation': 'push',
        'stage-ec2-workstation': 'stage',
    }

    operation_choices = sorted(
        host_operations
        + workspace_operations
        + list(ec2_workstation_operations)
        + [f'{op}-local' for op in host_operations]
        + [f'{op}-all' for op in host_operations]
    )

    parser = argparse.ArgumentParser(description='Apply dotFiles operations')
    parser.add_argument('operation', help='Operation to perform', choices=operation_choices)
    parser.add_argument('--hosts', nargs='+', help='Hosts to apply the operation to')
    host_group = parser.add_mutually_exclusive_group()
    host_group.add_argument('--all', action='store_true', help='Apply to all hosts')
    host_group.add_argument('--local', action='store_true', help='Apply to the local host')
    parser.add_argument('--dry-run', action='store_true', help='Print operations without executing them')
    parser.add_argument('--skip-cache', action='store_true', help='Skip caches and rebuild curl/jsonnet artifacts')
    parser.add_argument('--working-dir', help='Set the working directory')
    parser.add_argument('--verbose', '-v', action='store_true', help='Enable verbose output')
    parser.add_argument('--quiet', '-q', action='store_true', help='Suppress output')
    parser.add_argument('--trace-startup', action='store_true', help='Enable tracing in shell scripts by default')

    parsed_args = parser.parse_args(args)

    if parsed_args.working_dir:
        os.chdir(parsed_args.working_dir)

    global TRACE_STARTUP_FLAG
    TRACE_STARTUP_FLAG = bool(getattr(parsed_args, 'trace_startup', False)) # type: ignore

    operation_arg = parsed_args.operation
    if operation_arg.endswith('-local'):
        operation_arg = operation_arg.removesuffix('-local')
        parsed_args.local = True
    elif operation_arg.endswith('-all'):
        operation_arg = operation_arg.removesuffix('-all')
        parsed_args.all = True

    if parsed_args.local and parsed_args.all:
        raise ValueError('Cannot specify both --local and --all')

    use_ec2_shorthand = operation_arg in ec2_workstation_operations
    metadata_required = use_ec2_shorthand

    if metadata_required:
        metadata = Ec2WorkstationMetadata.load()
        if metadata is None:
            raise ValueError('EC2 workstation metadata required but not found; are you running on the EC2 workstation?')
        config.update(metadata)

    hosts: list[Host] = []
    if use_ec2_shorthand:
        if parsed_args.hosts:
            raise ValueError('Cannot specify --hosts with EC2 workstation shortcuts')
        if parsed_args.local or parsed_args.all:
            raise ValueError('Cannot combine --local/--all with EC2 workstation shortcuts')
        ec2_host = config.find_host('ec2-workstation')
        if ec2_host is None:
            raise ValueError('EC2 workstation host not defined; ensure apply_configs.jsonnet includes the alias')
        hosts = [ec2_host]
    elif parsed_args.local:
        if parsed_args.hosts:
            raise ValueError('Cannot specify --local and hosts')
        localhost = config.get_localhost()
        if localhost is None:
            raise ValueError('Local host not defined; ensure apply_configs.jsonnet defines a localhost entry')
        hosts = [localhost]
    elif parsed_args.all:
        if parsed_args.hosts:
            raise ValueError('Cannot specify --all and hosts')
        hosts = config.hosts
    elif parsed_args.hosts:
        hosts = parse_hosts_from_args(parsed_args.hosts)

    effective_operation = ec2_workstation_operations.get(operation_arg, operation_arg)

    if effective_operation in host_operations and not hosts:
        raise ValueError('No hosts specified')

    ops: list[RunOp] = []

    skip_cache = bool(getattr(parsed_args, 'skip_cache', False))
    verbose_flag = bool(getattr(parsed_args, 'verbose', False))

    match effective_operation:
        case 'bootstrap-windows':
            ops.extend(bootstrap_windows())
        case 'clean':
            ops.extend(chain.from_iterable(clean_remote_dotfiles(host) for host in hosts if not host.stage_only))
        case 'compare-iterm2-prefs':
            ops.append(compare_iterm2_prefs)
        case 'compare-user-settings':
            localhost = config.get_localhost()
            if localhost is None:
                raise ValueError('Local host not defined; cannot compare user settings')
            ops.append(partial(compare_user_settings, host=localhost))
        case 'generate-workspace':
            ops.append(generate_derived_workspace)
        case 'generate-hosts-config':
            ops.append(generate_hosts_config)
        case 'install-sublime-plugins':
            ops.extend(push_sublimetext_windows_plugins())
        case 'pull':
            if len(hosts) != 1:
                raise ValueError('Cannot pull from multiple hosts')
            ops.extend(pull_remote(hosts[0]))
        case 'push':
            ops.extend(chain.from_iterable(stage_local(host, verbose=verbose_flag, skip_cache=skip_cache) for host in hosts))
            ops.extend(chain.from_iterable(push_remote_staging(host) for host in hosts if not host.stage_only))
            if any(host.is_localhost and host.kernel == 'darwin' for host in hosts):
                ops.append(push_iterm2_prefs)
        case 'push-gnome-settings':
            ops.extend(push_gnome_settings())
        case 'push-iterm2-prefs':
            ops.append(push_iterm2_prefs)
        case 'push-only':
            ops.extend(chain.from_iterable(push_remote_staging(host) for host in hosts if not host.stage_only))
        case 'snapshot-iterm2-prefs':
            ops.append(snapshot_iterm2_prefs_json)
        case 'stage':
            ops.extend(chain.from_iterable(stage_local(host, verbose=verbose_flag, skip_cache=skip_cache) for host in hosts))
        case 'update-workspace-settings':
            ops.append(update_workspace_settings)
        case 'update-workspace-extensions':
            ops.append(update_workspace_extensions)
        case _:
            print('<unknown arg>')
            return 1

    if parsed_args.dry_run:
        print_ops(ops, quiet=parsed_args.quiet)
    else:
        run_ops(ops, quiet=parsed_args.quiet)
    return 0


if __name__ == "__main__":
    os.makedirs('out', exist_ok=True)
    if len(sys.argv) < 2:
        print('<missing args>')
        sys.exit(1)
    sys.exit(main(sys.argv[1:]))

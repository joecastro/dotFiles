#!/usr/bin/env python3

# pylint: disable=too-many-arguments, missing-module-docstring, missing-function-docstring, missing-class-docstring, line-too-long

import argparse
import json
import os
import platform
import plistlib
import re
import subprocess
import sys
from dataclasses import dataclass, field, fields, is_dataclass
from datetime import datetime
from functools import partial
from itertools import chain
from pathlib import Path
from typing import Any

def mingify_path(path: str) -> str:
    path = re.sub(r'\\', '/', path)
    path = re.sub(r'^([A-Za-z]):', lambda m: f'/{m.group(1).lower()}', path)
    return path

HOME = str(Path.home())
CWD = '.'
OS_CWD = mingify_path(os.getcwd())
OUT_DIR_ROOT = f'{CWD}/out'
GIT_PLUGINS_DIR = f'{OUT_DIR_ROOT}/plugins'

LOCALHOST_NAME = platform.uname().node
# Fixup mDNS hostname mangling on macOS
if LOCALHOST_NAME.endswith('.local'):
    LOCALHOST_NAME = LOCALHOST_NAME[:-6]
LOCALHOST_KERNEL = platform.uname().system.lower()

BASH_COMMAND_PREFIX = 'BASH_COMMAND: '


def make_joined_path(path: str, root: str | None) -> str:
    if not path.startswith('/') and root != None:
        return f'{root}/{path}'
    return path


def make_shell_command(run_args: list[str]) -> str:
    return ' '.join([arg if ' ' not in arg else f'"{arg}"' for arg in run_args])


def json_ready(obj: Any) -> Any:
    if is_dataclass(obj):
        return {f.name: json_ready(getattr(obj, f.name)) for f in fields(obj)}
    elif isinstance(obj, dict):
        return {json_ready(k): json_ready(v) for k, v in obj.items()}
    elif isinstance(obj, (list, tuple)):
        return [json_ready(item) for item in obj]
    elif isinstance(obj, set):
        return sorted(list(obj))
    else:
        return obj


@dataclass
# pylint: disable-next=too-many-instance-attributes
class Host:
    hostname: str
    config_dir: str
    home: str
    branch: str | None = None
    kernel: str = 'linux'
    file_maps: list[tuple[str, str]] | dict[str, str] = field(default_factory=list)
    directory_maps: list[tuple[str, str]] | dict[str, str] = field(default_factory=list)
    jsonnet_maps: list[tuple[str, str, str]] | dict[str, str] = field(default_factory=list)
    jsonnet_multi_maps: list[tuple[str, str, str]] | dict[str, str] = field(default_factory=list)
    curl_maps: list[tuple[str, str, str]] | dict[str, str] = field(default_factory=list)
    macros: dict[str, list[str]] = field(default_factory=dict)
    post_install_commands: list[str] = field(default_factory=list)

    prestaged_files: set[str] = field(default_factory=set)
    prestaged_directories: set[str] = field(default_factory=set)

    is_localhost: bool = field(init=False, default=False)
    local_staging_dir: str = field(init=False, default='')
    remote_staging_dir: str = field(init=False, default='')

    def __post_init__(self):

        self.home = mingify_path(self.home)
        if self.hostname == 'localhost':
            self.hostname = LOCALHOST_NAME
        if self.hostname == LOCALHOST_NAME:
            self.kernel = LOCALHOST_KERNEL
        self.file_maps = dict(self.file_maps)
        self.file_maps |= {item2:item3 for (_, item2, item3) in self.jsonnet_maps}
        self.prestaged_files.update([item2 for (_, item2, _) in self.jsonnet_maps])
        self.jsonnet_maps = {item1:item2 for (item1, item2, _) in self.jsonnet_maps}
        self.directory_maps = dict(self.directory_maps)
        self.directory_maps |= {item2:item3 for (_, item2, item3) in self.jsonnet_multi_maps}
        self.prestaged_directories.update([item2 for (_, item2, _) in self.jsonnet_multi_maps])
        self.jsonnet_multi_maps = {item1:item2 for (item1, item2, _) in self.jsonnet_multi_maps}
        self.file_maps |= {item2:item3 for (_, item2, item3) in self.curl_maps}
        self.prestaged_files.update([item2 for (_, item2, _) in self.curl_maps])
        self.curl_maps = {item1:item2 for (item1, item2, _) in self.curl_maps}

        values_to_coerce = [k for k, v in self.file_maps.items() if v.endswith('/')]
        for key in values_to_coerce:
            self.file_maps[key] = f'{self.file_maps[key]}{os.path.basename(key)}'

        self.is_localhost = self.hostname == LOCALHOST_NAME
        self.local_staging_dir = f'{CWD}/out/{self.hostname}-dot'
        self.remote_staging_dir = f'{self.home}/{self.config_dir}-staging'


    def __repr__(self) -> str:
        return self.hostname


    def get_inflated_macro(self, key: str, file_path: str) -> list[str]:
        return [
            v.replace('@@FILE_NAME', Path(file_path).stem.upper())
             .replace('@@NOW', datetime.now().strftime("%Y-%m-%d %H:%M"))
            for v in self.macros.get(key, [])
        ]

    def is_reachable(self) -> bool:
        if self.is_localhost:
            return True
        return subprocess.run(
            ['ssh', '-o', 'ConnectTimeout=10', '-t', self.hostname, 'echo "ping check"'],
            capture_output=True,
            check=False
        ).returncode == 0

    def does_directory_exist(self, path: str) -> bool:
        if self.is_localhost:
            return os.path.exists(path)
        return subprocess.run(
            ['ssh', self.hostname, f'test -d {path}'],
            capture_output=True,
            check=False
        ).returncode == 0

    def make_ops(self, ops: list[list | str]) -> list:
        if self.is_localhost:
            return ops
        return [
            ['ssh', self.hostname, ' '.join(op)] if isinstance(op, list) else op
            for op in ops
        ]

    def expand_local_file_path(self, file_path: str) -> str:
        return make_joined_path(file_path, self.home)

@dataclass
class Config:
    hosts: list[Host]
    workspace_overrides: dict
    vim_pack_plugin_start_repos: list[str]
    vim_pack_plugin_opt_repos: list[str]
    zsh_plugin_repos: list[str]

    def __post_init__(self):
        self.hosts = [Host(**host) for host in self.hosts]

    def get_localhost(self) -> Host | None:
        return next((h for h in self.hosts if h.is_localhost), None)


config: Config = None


def print_ops(ops: list, quiet: bool = False) -> None:
    for entry in ops:
        if isinstance(entry, str):
            if entry.startswith(BASH_COMMAND_PREFIX):
                raise ValueError('Bash commands should be executed through a script')
            if not quiet:
                print(entry)
        elif isinstance(entry, list):
            print(f'DEBUG: {" ".join(entry)}')
        elif callable(entry):
            try:
                func_args = ', '.join(f"{k}={v}" for k, v in entry.keywords.items())
                print(f'DEBUG: invoking {entry.func.__name__}({func_args})')
            except AttributeError:
                print(f'DEBUG: invoking {entry.__name__}()')
        else:
            raise TypeError('Unsupported operation type')


def run_ops(ops: list, quiet: bool = False) -> None:
    for entry in ops:
        if isinstance(entry, str):
            if entry.startswith(BASH_COMMAND_PREFIX):
                raise ValueError('Bash commands should be executed through a script')
            if not quiet:
                print(entry)
        elif isinstance(entry, list):
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


def get_plugin_relative_target_path(repo: str) -> str:
    match = re.search(r"([^/]+)\.git$", repo)
    if not match:
        raise ValueError(f'Invalid repository URL: {repo}')
    target_suffix = match.group(1)

    # To prevent these from being deleted on push, keep them out of the dotShell config directory.
    directory_prefixes = {
        'vim_start': '.vim/pack/plugins/start',
        'vim_opt': '.vim/pack/plugins/opt',
        'zsh_ext': '.config/zshext',
    }

    if repo in config.vim_pack_plugin_start_repos:
        target_prefix = directory_prefixes['vim_start']
    elif repo in config.vim_pack_plugin_opt_repos:
        target_prefix = directory_prefixes['vim_opt']
    elif repo in config.zsh_plugin_repos:
        target_prefix = directory_prefixes['zsh_ext']
    else:
        raise ValueError(f'Unknown plugin repository: {repo}')

    return f"{target_prefix}/{target_suffix}"


def make_post_install_commands(host: Host) -> list[str]:
    if not host.post_install_commands:
        return []

    ops = ['>> Running post-install commands']
    ops.extend([BASH_COMMAND_PREFIX + cmd for cmd in host.post_install_commands])

    return ops


def make_install_plugins_bash_commands(plugin_type: str, repo_list: list[str], install_root: str) -> list[str]:
    ops = [f'>> Updating {len(repo_list)} {plugin_type}']
    for repo in repo_list:
        target_path = f"{install_root}/{get_plugin_relative_target_path(repo)}"
        bash_commands = [
            f'if [ -d "{target_path}" ]; then',
            f'    cd "{target_path}"',
            '    git pull',
            '    cd - > /dev/null',
            'else',
            f'    mkdir -p "{os.path.dirname(target_path)}"',
            f'    git clone "{repo}" "{target_path}"',
            'fi'
        ]
        ops.extend([BASH_COMMAND_PREFIX + line for line in bash_commands])

    return ops


def ensure_directories_exist_ops(paths: list[str], path_root: str=None, already_exists_ok: bool=True) -> list[str]:
    def remove_parents_from_set(paths: set[str]) -> set[str]:
        return {d for d in paths if not any(subdir != d and subdir.startswith(d) for subdir in paths)}

    expanded_paths = sorted(remove_parents_from_set({make_joined_path(path, path_root) for path in paths}))

    ops = []
    if not already_exists_ok:
        ops.extend([['rm', '-rf', path] for path in expanded_paths])
    ops.extend([['mkdir', '-p', path] for path in expanded_paths])

    return ops


def remove_children_from_set(paths: set[str]) -> list[str]:
    return sorted({d for d in paths if not any(subdir != d and d.startswith(subdir) for subdir in paths)})


def copy_directories_local(source_root: str, source_dirs: list[str], dest_root: str, dest_dirs: list[str]) -> list:
    ops = []

    ops.extend(ensure_directories_exist_ops(dest_dirs, dest_root))
    ops.extend([['cp', '-r', f'{make_joined_path(src, source_root)}/.', make_joined_path(dest, dest_root)]
                for src, dest in zip(source_dirs, dest_dirs)])

    return ops


def parse_jsonnet_now(jsonnet_file: str, ext_vars: dict, output_string: bool = False) -> dict | list | str:
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


def parse_jsonnet(jsonnet_file: str, ext_vars: dict, output_path: str | None = None, is_multicast: bool = False, output_string: bool = False) -> list[str]:
    proc_args = ['jsonnet']

    if output_string or (output_path and (output_path.endswith('.sh') or output_path.endswith('.ini'))):
        proc_args.append('-S')

    if output_path:
        proc_args.extend(['-m', output_path] if is_multicast else ['-o', output_path])

    for key, val in ext_vars.items():
        proc_args.extend(['-V', f'{key}={val}'])

    proc_args.append(jsonnet_file)
    return proc_args


def get_ext_vars(host: Host | None = None) -> dict:
    standard_ext_vars = {
        'is_localhost': 'true',
        'hostname': LOCALHOST_NAME,
        'kernel': LOCALHOST_KERNEL,
        'cwd': OS_CWD,
        'home': HOME,
    }
    if host:
        standard_ext_vars.update({
            'is_localhost': str(host.is_localhost).lower(),
            'hostname': host.hostname,
            'kernel': host.kernel,
        })
    return standard_ext_vars


def preprocess_curl_files(host: Host, verbose: bool = False) -> list:
    if not host.curl_maps:
        return ['No curl maps found']

    full_paths = {src: make_joined_path(dest, host.local_staging_dir)
                   for src, dest in host.curl_maps.items()}
    ops = ensure_directories_exist_ops([os.path.dirname(d) for d in full_paths.values()])

    curl_prefix = ['curl', '-s', '-S'] if not verbose else ['curl']
    ops.extend([curl_prefix + ['-L', src, '-o', dest] for src, dest in full_paths.items()])

    return ops


def preprocess_jsonnet_files(host: Host, source_dir: str, staging_dir: str, verbose: bool = False) -> list:
    if not host.jsonnet_maps:
        return ['No jsonnet maps found']

    full_paths = {make_joined_path(src, source_dir): make_joined_path(dest, staging_dir) for src, dest in host.jsonnet_maps.items()}

    ops = ensure_directories_exist_ops([os.path.dirname(d) for d in full_paths.values()])
    jsonnet_commands = [parse_jsonnet(src, get_ext_vars(host), dest) for src, dest in full_paths.items()]

    if verbose:
        annotated_jsonnet_commands = [make_shell_command(cmd) for cmd in jsonnet_commands]
        jsonnet_commands = [item for sublist in zip(annotated_jsonnet_commands, jsonnet_commands) for item in sublist]

    ops.extend(jsonnet_commands)
    return ops

def preprocess_jsonnet_directories(host, source_dir, staging_dir, verbose=False) -> list:
    if not host.jsonnet_multi_maps:
        return ['No jsonnet multimaps found']

    full_paths = [(make_joined_path(src, source_dir), make_joined_path(dest + '/', staging_dir)) for src, dest in host.jsonnet_multi_maps.items()]
    staging_dests = {os.path.dirname(dest) for _, dest in full_paths}

    ops = [['mkdir', '-p', dest] for dest in staging_dests]
    jsonnet_commands = [parse_jsonnet(src, get_ext_vars(host), dest, is_multicast=True, output_string=True) for src, dest in full_paths]

    if verbose:
        annotated_jsonnet_commands = [f"DEBUG: {make_shell_command(cmd)}" for cmd in jsonnet_commands]
        jsonnet_commands = [item for sublist in zip(annotated_jsonnet_commands, jsonnet_commands) for item in sublist]

    ops.extend(jsonnet_commands)
    return ops


def copy_files_local(source_root, source_files, dest_root, dest_files, annotate: bool = False) -> list:
    full_path_sources = [make_joined_path(src, source_root) for src in source_files]
    full_path_dests = [make_joined_path(dest, dest_root) for dest in dest_files]

    # Filter out files that would overwrite files in the current working directory
    filtered_sources, filtered_dests = zip(*[
        (src, dest) for src, dest in zip(full_path_sources, full_path_dests)
        if not mingify_path(dest).startswith(OS_CWD)
    ]) if full_path_sources else ([], [])

    ops = ensure_directories_exist_ops([os.path.dirname(dest) for dest in filtered_dests], None)

    copy_ops = [['cp', src, dest] for src, dest in zip(filtered_sources, filtered_dests)]
    if annotate:
        annotated_copy_ops = [f"DEBUG: {make_shell_command(cmd)}" for cmd in copy_ops]
        copy_ops = [item for sublist in zip(annotated_copy_ops, copy_ops) for item in sublist]

    ops.extend(copy_ops)
    return ops


def install_vscode_extensions(host, verbose=False) -> list:
    if host.is_localhost:
        return []

    with open('vscode/dotFiles_extensions.json', encoding='utf-8') as f:
        extensions_list = json.load(f).get('recommendations', [])

    completed_proc = subprocess.run(['ssh', host.hostname, 'code --list-extensions'], check=False, capture_output=True, text=True)
    if completed_proc.returncode != 0:
        return [f"Failed listing vscode extensions on {host.hostname}"]

    installed_extensions_list = completed_proc.stdout.splitlines()

    extensions_to_install = [ext for ext in extensions_list if ext not in installed_extensions_list]
    extensions_to_remove = [ext for ext in installed_extensions_list if ext not in extensions_list]

    if not extensions_to_install and not extensions_to_remove:
        return ['>> No vscode extensions to install or remove'] if verbose else []

    ops = []
    if extensions_to_install:
        ops.append(f">> Installing {len(extensions_to_install)} vscode extensions")
        ops.append(['ssh', host.hostname, ' && '.join([f'code --install-extension {ext}' for ext in extensions_to_install])])

    if extensions_to_remove:
        ops.append(f">> Removing {len(extensions_to_remove)} vscode extensions")
        ops.append(['ssh', host.hostname, ' && '.join([f'code --uninstall-extension {ext}' for ext in extensions_to_remove])])

    return ops


def make_finish_script(command_ops, script_path: str, verbose: bool) -> list:
    def write_script():
        with open(script_path, 'w', encoding='utf-8') as f:
            f.write('#!/bin/bash\n\n')
            f.write('set -e\n\n')
            if verbose:
                f.write('set -x\n\n')
            for op in command_ops:
                if isinstance(op, str):
                    op = op[len(BASH_COMMAND_PREFIX):] if op.startswith(BASH_COMMAND_PREFIX) else f'echo "{op}"'
                elif isinstance(op, list):
                    op = make_shell_command(op)
                f.write(op + '\n')

    ops = [partial(write_script)]
    if verbose:
        ops.append(f"DEBUG: Generated finish script at {script_path}")
    ops.append(['chmod', 'u+x', script_path])

    return ops


def clean_remote_dotfiles(host: Host, treat_as_localhost: bool=False) -> list:
    ops = [f'>> Cleaning existing configuration files for {host.hostname}']

    dirs_to_remove = [make_joined_path(d, host.home) for d in remove_children_from_set({host.config_dir}.union(host.directory_maps.values()))]
    files_to_remove = {make_joined_path(f, host.home) for f in host.file_maps.values()}
    files_to_remove = [f for f in remove_children_from_set(files_to_remove.union(dirs_to_remove)) if not f in dirs_to_remove]

    ops.extend([['rm', '-rf', d] for d in dirs_to_remove])
    ops.extend([['rm', '-f', f] for f in files_to_remove])

    if not treat_as_localhost:
        ops = host.make_ops(ops)

    return ops


def push_remote_staging(host: Host) -> list:
    ops = [f'Syncing dotFiles for {host.hostname} from local staging directory']

    ops.append(f'>> Copying {len(host.file_maps) + 1} files and {len(host.directory_maps)} folders to {host.hostname} home directory')
    ops.extend(host.make_ops([['mkdir', '-p', host.remote_staging_dir]]))

    if host.is_localhost:
        ops.extend([
            ['rm', '-rf', host.remote_staging_dir],
            ['mkdir', '-p', host.remote_staging_dir],
            ['cp', '-r', f'{host.local_staging_dir}/.', host.remote_staging_dir]
        ])
    else:
        ops.append(['rsync', '-axv', '--numeric-ids', '--delete', '--progress', f'{host.local_staging_dir}/', f'{host.hostname}:{host.remote_staging_dir}'])

    remote_finish_path = f'{host.remote_staging_dir}/finish.sh'
    ops.append(f'>> Running finish script on {host.hostname}: /bin/bash {remote_finish_path}')
    ops.extend(host.make_ops([['/bin/bash', remote_finish_path]]))

    return ops


def process_macros_for_staged_file(host: Host, file: str) -> None:
    is_modified = False
    modified_content = []
    with open(file, 'r', encoding='utf-8') as f:
        lines = f.read().splitlines()
        for line in lines:
            if line in host.macros:
                is_modified = True
                modified_content.extend(host.get_inflated_macro(line, file))
            else:
                modified_content.append(line)
    if is_modified:
        with open(file, 'w', encoding='utf-8') as f:
            f.writelines(line + '\n' for line in modified_content)


def stage_local(host: Host, verbose: bool = False, use_cache: bool = False) -> list:
    ops = [f'Staging dotFiles for {host.hostname} in {host.local_staging_dir}']

    if not use_cache:
        ops.append(['rm', '-rf', host.local_staging_dir])

    files_to_stage = [file for file in host.file_maps.keys() if file not in host.prestaged_files]
    directories_to_stage = [dir for dir in host.directory_maps.keys() if dir not in host.prestaged_directories]

    if use_cache:
        ops.append('>> Using cache for jsonnet and curl files')
    else:
        ops.append('>> Precaching curl files')
        ops.extend(preprocess_curl_files(host, verbose=verbose))
        ops.append('>> Preprocessing jsonnet files')
        ops.extend(preprocess_jsonnet_files(host, CWD, host.local_staging_dir, verbose=verbose))
        ops.extend(preprocess_jsonnet_directories(host, CWD, host.local_staging_dir, verbose=verbose))

    ops.append('>> Staging directories and files')
    ops.extend(copy_directories_local(CWD, directories_to_stage, host.local_staging_dir, directories_to_stage))
    ops.extend(copy_files_local(CWD, files_to_stage, host.local_staging_dir, files_to_stage))

    if host.macros:
        def is_path_eligible_for_macros(file: str) -> bool:
            return not any(file.endswith(ext) for ext in ['.png', '.jpg', '.svg'])

        files_to_process = [make_joined_path(file, host.local_staging_dir) for file in host.file_maps.keys() if is_path_eligible_for_macros(file) and file not in host.prestaged_files]
        ops.append('>> Preprocessing macros in local staged files')
        for f in files_to_process:
            if verbose:
                ops.append(f'Processing macros in {f}')
            ops.append(partial(process_macros_for_staged_file, host=host, file=f))

    finish_ops = []

    finish_ops.extend(clean_remote_dotfiles(host, treat_as_localhost=True))

    finish_ops.extend(copy_directories_local(host.remote_staging_dir, host.directory_maps.keys(), host.home, host.directory_maps.values()))
    finish_ops.extend(copy_files_local(host.remote_staging_dir, host.file_maps.keys(), host.home, host.file_maps.values()))
    finish_ops.append('>> Updating Vim and Zsh plugins')
    finish_ops.extend(make_install_plugins_bash_commands('Vim startup plugin(s)', config.vim_pack_plugin_start_repos, host.home))
    finish_ops.extend(make_install_plugins_bash_commands('Vim operational plugin(s)', config.vim_pack_plugin_opt_repos, host.home))
    finish_ops.extend(make_install_plugins_bash_commands('Zsh plugin(s)', config.zsh_plugin_repos, host.home))
    finish_ops.extend(make_post_install_commands(host))

    finish_script = f'{host.local_staging_dir}/finish.sh'
    ops.extend(make_finish_script(finish_ops, finish_script, verbose=verbose))

    return ops


def pull_remote(host: Host) -> list:
    snapshot_dir = host.local_staging_dir
    ops = [f'>> Recreating staged dotFiles for {host.hostname}']

    ops.extend(ensure_directories_exist_ops([snapshot_dir], None, already_exists_ok=False))
    ops.extend(host.make_ops(ensure_directories_exist_ops([host.remote_staging_dir], None, already_exists_ok=False)))

    remote_ops = ['>> Unstaging directories and files']
    remote_ops.extend(copy_directories_local(host.home, host.directory_maps.values(), host.remote_staging_dir, host.directory_maps.keys()))
    remote_ops.extend(copy_files_local(host.home, host.file_maps.values(), host.remote_staging_dir, host.file_maps.keys()))

    unfinish_script = f'{snapshot_dir}/unfinish.sh'
    ops.extend(make_finish_script(remote_ops, unfinish_script, verbose=False))

    ops.append(f'>> Copying unfinish script to {host.hostname}')
    if host.is_localhost:
        ops.append(['cp', unfinish_script, host.remote_staging_dir])
    else:
        ops.append(['scp', unfinish_script, f'{host.hostname}:{host.remote_staging_dir}'])

    ops.extend(host.make_ops([['/bin/bash', f'{host.remote_staging_dir}/unfinish.sh']]))

    if host.is_localhost:
        ops.append(['cp', '-r', f'{host.remote_staging_dir}/.', snapshot_dir])
    else:
        ops.append(['rsync', '-axv', '--numeric-ids', '--delete', '--progress', f'{host.hostname}:{host.remote_staging_dir}/', snapshot_dir])

    return ops

def bootstrap_windows() -> list:
    """Apply environment settings for a new Windows machine."""
    return [['SETX', 'DOTFILES_SRC_DIR', OS_CWD]]


def iterm2_prefs_plist_location() -> str:
    """Retrieve the location of the iTerm2 preferences plist file."""
    plist_pref_file_proc = subprocess.run(
        ['defaults', 'read', 'com.googlecode.iterm2', 'PrefsCustomFolder'],
        check=True,
        capture_output=True,
        text=True
    )
    return f'{plist_pref_file_proc.stdout.strip()}/com.googlecode.iterm2.plist'


def build_iterm2_prefs_json() -> dict:
    """Build the iTerm2 preferences from the repo's JSONNet file."""
    return parse_jsonnet_now(
        'iterm2/com.googlecode.iterm2.plist.jsonnet',
        get_ext_vars(config.get_localhost())
    )


def snapshot_iterm2_prefs_json(out_path: str = 'out/com.googlecode.iterm2.active.json') -> None:
    """Snapshot the current iTerm2 preferences into a JSON file."""
    print(f'Writing iTerm2 preferences to {out_path}')
    with open(iterm2_prefs_plist_location(), 'rb') as f:
        plist_prefs = plistlib.load(f)
    with open(out_path, 'w', encoding='utf-8') as out:
        json.dump(plist_prefs, out, indent=4, sort_keys=False)


def push_iterm2_prefs() -> None:
    """Build and apply the repo's iTerm2 preferences."""
    iterm2_config_root = Path.home() / config.get_localhost().config_dir / 'iterm2'
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

    gen_path = f'{host.local_staging_dir}/{os.path.splitext(target_jsonnet_map_entry)[0]}.gen.json'
    original_path = f'{HOME}/{target_file_map_entry}'
    snapshot_path = f'{host.local_staging_dir}/{os.path.splitext(target_jsonnet_map_entry)[0]}.snapshot.json'

    with open(gen_path, 'w', encoding='utf-8') as f:
        gen_user_settings = parse_jsonnet_now(template_path, get_ext_vars(host))
        json.dump(gen_user_settings, f, indent=4, sort_keys=True)

    with open(original_path, encoding='utf-8') as in_path:
        current_settings = json.load(in_path)
    with open(snapshot_path, 'w', encoding='utf-8') as out_path:
        json.dump(current_settings, out_path, indent=4, sort_keys=True)

    print(f'diff "{snapshot_path}" "{gen_path}"')


def push_sublimetext_windows_plugins() -> list:
    """Setup Sublime Text plugins for Windows."""
    return [['cp', 'sublime_text\\*', '%APPDATA%\\Sublime Text 2\\Packages\\User']]


def push_gnome_settings() -> list:
    """Apply GNOME settings using dconf."""
    dconf_settings = parse_jsonnet_now(
        'gnome/dconf_settings.jsonnet',
        get_ext_vars(config.get_localhost()),
        output_string=True
    )
    subprocess.run(['dconf', 'load'], check=True, input=dconf_settings.encode('utf-8'))
    return ['dconf settings applied']


def parse_hosts_from_args(host_args: list[str]) -> list[Host]:
    if not host_args:
        return []
    if len(host_args) == 1:
        match host_args[0]:
            case '--all':
                return config.hosts
            case '--local':
                return [config.get_localhost()]
            case _:
                return [next(h for h in config.hosts if h.hostname == host_args[0])]
    return [h for h in config.hosts if h.hostname in host_args]


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
        'update-workspace-extensions'
    ]

    parser = argparse.ArgumentParser(description='Apply dotFiles operations')
    parser.add_argument(
        'operation',
        help='Operation to perform',
        choices=sorted(host_operations
            + workspace_operations
            + [f'{op}-local' for op in host_operations]
            + [f'{op}-all' for op in host_operations])
    )
    parser.add_argument('--hosts', nargs='+', help='Hosts to apply the operation to')
    host_group = parser.add_mutually_exclusive_group()
    host_group.add_argument('--all', action='store_true', help='Apply to all hosts')
    host_group.add_argument('--local', action='store_true', help='Apply to the local host')
    parser.add_argument('--dry-run', action='store_true', help='Print operations without executing them')
    parser.add_argument('--use-cache', action='store_true', help='Use previously generated jsonnet output and curled files when staging')
    parser.add_argument('--working-dir', help='Set the working directory')
    parser.add_argument('--verbose', '-v', action='store_true', help='Enable verbose output')
    parser.add_argument('--quiet', '-q', action='store_true', help='Suppress output')

    parsed_args = parser.parse_args(args)

    if parsed_args.working_dir:
        os.chdir(parsed_args.working_dir)

    operation_arg = parsed_args.operation
    if operation_arg.endswith('-local'):
        operation_arg = operation_arg.removesuffix('-local')
        parsed_args.local = True
    elif operation_arg.endswith('-all'):
        operation_arg = operation_arg.removesuffix('-all')
        parsed_args.all = True

    if parsed_args.local and parsed_args.all:
        raise ValueError('Cannot specify both --local and --all')

    hosts = []
    if parsed_args.local:
        if parsed_args.hosts:
            raise ValueError('Cannot specify --local and hosts')
        hosts = [config.get_localhost()]
    elif parsed_args.all:
        if parsed_args.hosts:
            raise ValueError('Cannot specify --all and hosts')
        hosts = config.hosts
    elif parsed_args.hosts:
        hosts = parse_hosts_from_args(parsed_args.hosts)

    if operation_arg in host_operations and not hosts:
        raise ValueError('No hosts specified')

    ops = []
    match operation_arg:
        case 'bootstrap-windows':
            ops.extend(bootstrap_windows())
        case 'clean':
            ops.extend(chain.from_iterable(clean_remote_dotfiles(host) for host in hosts))
        case 'compare-iterm2-prefs':
            ops.append(compare_iterm2_prefs)
        case 'compare-user-settings':
            ops.append(partial(compare_user_settings, host=config.get_localhost()))
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
            ops.extend(chain.from_iterable(stage_local(host, verbose=parsed_args.verbose, use_cache=parsed_args.use_cache) for host in hosts))
            ops.extend(chain.from_iterable(push_remote_staging(host) for host in hosts))
            if any(host.is_localhost and host.kernel == 'darwin' for host in hosts):
                ops.append(push_iterm2_prefs)
        case 'push-gnome-settings':
            ops.extend(push_gnome_settings())
        case 'push-iterm2-prefs':
            ops.append(push_iterm2_prefs)
        case 'push-only':
            ops.extend(chain.from_iterable(push_remote_staging(host) for host in hosts))
        case 'snapshot-iterm2-prefs':
            ops.append(snapshot_iterm2_prefs_json)
        case 'stage':
            ops.extend(chain.from_iterable(stage_local(host, verbose=parsed_args.verbose) for host in hosts))
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


def process_apply_configs() -> Config:
    """Process any config files that need to be initialized."""
    config_file = Path.cwd() / 'apply_configs.jsonnet'
    if not config_file.is_file():
        raise ValueError('Missing config file')

    config_dict = parse_jsonnet_now(str(config_file), get_ext_vars())
    return Config(**config_dict)


if __name__ == "__main__":
    os.makedirs('out', exist_ok=True)
    config = process_apply_configs()

    if len(sys.argv) < 2:
        print('<missing args>')
        sys.exit(1)
    sys.exit(main(sys.argv[1:]))

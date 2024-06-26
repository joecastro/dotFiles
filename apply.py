#!/usr/bin/env python3

# pylint: disable=too-many-arguments, missing-module-docstring, missing-function-docstring, missing-class-docstring, line-too-long

from datetime import datetime
from dataclasses import dataclass, field
from functools import partial
from itertools import chain
import json
import os
from pathlib import Path
import platform
import plistlib
import re
import shutil
import subprocess
import sys

HOME = str(Path.home())
CWD = '.'

@dataclass
# pylint: disable-next=too-many-instance-attributes
class Host:
    hostname: str
    kernel: str = 'linux'
    abstract_wallpaper: dict = None
    android_wallpaper: dict = None
    branch: str = 'none'
    color: str = 'default'
    file_maps: list[tuple[str, str]] | dict[str, str] = field(default_factory=list)
    jsonnet_maps: list[tuple[str, str, str]] | dict[str, str] = field(default_factory=list)
    curl_maps: list[tuple[str, str, str]] | dict[str, str] = field(default_factory=list)
    macros: dict[str, list[str]] = field(default_factory=dict)

    def __post_init__(self):
        if self.hostname == 'localhost':
            self.hostname = platform.uname().node
            self.kernel = platform.uname().system.lower()
        self.file_maps = dict(self.file_maps)
        self.file_maps |= {item2:item3 for (_, item2, item3) in self.jsonnet_maps}
        self.jsonnet_maps = {item1:item2 for (item1, item2, _) in self.jsonnet_maps}
        self.file_maps |= {item2:item3 for (_, item2, item3) in self.curl_maps}
        self.curl_maps = {item1:item2 for (item1, item2, _) in self.curl_maps}

    def is_localhost(self) -> bool:
        return self.hostname == platform.uname().node

    def get_staging_dir(self, suffix='dot') -> str:
        return os.path.join(CWD, 'out', f'{self.hostname}-{suffix}')

    def get_inflated_macro(self, key, file_path) -> list[str]:
        return [v.replace('@@FILE_NAME', Path(file_path).stem.upper())
                 .replace('@@NOW', datetime.now().strftime("%Y-%m-%d %H:%M")) for v in self.macros[key]]

    def is_reachable(self) -> bool:
        if self.is_localhost():
            return True
        return subprocess.run(['ssh', '-o', 'ConnectTimeout=10', '-t',  self.hostname, 'echo "ping check"'], capture_output=True).returncode == 0

    def does_directory_exist(self, path) -> bool:
        if self.is_localhost():
            return os.path.exists(path)
        return subprocess.run(['ssh', self.hostname, f'test -d {path}'], capture_output=True).returncode == 0

    def make_ops(self, ops: list) -> list:
        if self.is_localhost():
            return ops

        return [['ssh', self.hostname, ' '.join(op)] if isinstance(op, list) else op for op in ops]


@dataclass
class Config:
    hosts: list[Host]
    config_root: str
    workspace_overrides: dict
    vim_pack_plugin_start_repos: list
    vim_pack_plugin_opt_repos: list
    zsh_plugin_repos: list

    def __post_init__(self):
        self.hosts = [Host(**host) for host in self.hosts]

    def get_localhost(self) -> Host | None:
        return next(h for h in self.hosts if h.is_localhost())


config:Config = None


def print_ops(ops: list, quiet=False) -> None:
    for entry in ops:
        if isinstance(entry, str):
            if not quiet:
                print(entry)
        elif isinstance(entry, list):
            print(f'DEBUG: {" ".join(entry)}')
        elif callable(entry):
            print(f'DEBUG: invoking function {entry}')
        else:
            raise TypeError('Bad operation type')


def run_ops(ops: list, quiet=False) -> None:
    for entry in ops:
        if isinstance(entry, str):
            if not quiet:
                print(entry)
        elif isinstance(entry, list):
            try:
                subprocess.run(entry, check=True)
            except:
                print(f'Failed running: {" ".join(entry)}')
                raise

        elif callable(entry):
            entry()
        else:
            raise TypeError('Bad operation type')


def ensure_out_dir() -> None:
    out_dir = 'out'
    if not os.path.exists(out_dir):
        os.makedirs(out_dir)


def update_workspace_extensions() -> None:
    repo_workspace_extensions_location = os.path.join('vscode', 'dotFiles_extensions.json')

    completed_proc = subprocess.run(['code', '--list-extensions'], check=True, capture_output=True)
    installed_extensions = completed_proc.stdout.decode('utf-8').splitlines()

    extensions_node = {
        'recommendations': sorted(installed_extensions, key=lambda x: x.lower())
    }

    with open(repo_workspace_extensions_location, 'w', encoding='utf-8') as f:
        json.dump(extensions_node, f, indent=4, sort_keys=True)


def push_vscode_user_settings() -> None:
    repo_user_settings_location = os.path.join('vscode', 'user_settings.json')
    mac_settings_location = f'{HOME}/Library/Application Support/Code/User/settings.json'

    # Open this as a json file first, just to make sure it parses properly.
    with open(repo_user_settings_location, encoding='utf-8') as f:
        json.load(f)

    shutil.copyfile(repo_user_settings_location, mac_settings_location)


def pull_vscode_user_settings() -> None:
    dotfiles_settings_location = 'vscode/user_settings.json'
    mac_settings_location = f'{HOME}/Library/Application Support/Code/User/settings.json'

    with open(mac_settings_location, encoding='utf-8') as f:
        settings = json.load(f)

    sorted_settings = json.dumps(settings, indent=4, sort_keys=True)

    with open(dotfiles_settings_location, 'w', encoding='utf-8') as f:
        f.write(sorted_settings)


def generate_derived_workspace() -> None:
    if not config.workspace_overrides:
        print('Skipping workspace generation because no overrides were specified.')
        return

    workspace = {}
    with open('vscode/dotFiles_settings.json', encoding='utf-8') as ws_settings:
        workspace['settings'] = json.load(ws_settings)
    with open('vscode/dotFiles_extensions.json', encoding='utf-8') as ws_extensions:
        workspace['extensions'] = json.load(ws_extensions)

    workspace['folders'] = config.workspace_overrides['folders']
    if config.workspace_overrides.get('settings'):
        for (key, value) in config.workspace_overrides['settings'].items():
            workspace['settings'][key] = value

    print(json.dumps(workspace, indent=4, sort_keys=True))


def install_git_plugins(host: Host, plugin_type: str, repo_list: list[str], install_root: str, verbose=False) -> list:
    pattern = re.compile("([^/]+)\\.git$")
    plugin_root = os.path.join(HOME if host.is_localhost() else ".", install_root)

    ops = [f'>> Cloning {len(repo_list)} {plugin_type} for {host.hostname}']
    ops.append(['rm', '-rf', plugin_root])
    git_prefix = ['git', 'clone', '-q'] if not verbose else ['git', 'clone']
    for (repo, target_path) in [(r, os.path.join(plugin_root, pattern.search(r).group(1))) for r in repo_list]:
        ops.append(f'Cloning into {target_path}...')
        ops.append(git_prefix + [repo, target_path])

    return host.make_ops(ops)


def copy_files(source_host, source_root, source_files, dest_host, dest_root, dest_files, annotate=False, verbose=False) -> list:
    if source_host.is_localhost() and dest_host.is_localhost():
        return copy_files_local(source_root, source_files, dest_root, dest_files, annotate)

    if not dest_host.is_localhost() and dest_root == HOME:
        dest_root = CWD
    if not source_host.is_localhost() and source_root == HOME:
        source_root = CWD

    source_prefix = source_root if source_host.is_localhost() else f'{source_host.hostname}:{source_root}'
    dest_prefix = dest_root if dest_host.is_localhost() else f'{dest_host.hostname}:{dest_root}'

    dest_subfolders = {os.path.dirname(d) for d in dest_files if os.path.dirname(d)}

    ops = dest_host.make_ops([['mkdir', '-p', f'{dest_root}/{sub}'] for sub in dest_subfolders])
    scp_prefix = ['scp', '-q'] if not verbose else ['scp']
    copy_ops = [scp_prefix + [f'{source_prefix}/{src}', f'{dest_prefix}/{dest}']
                 for (src, dest) in zip(source_files, dest_files)]

    if annotate:
        annotated_copy_ops = [" ".join(o) for o in copy_ops]
        copy_ops = [item for sublist in zip(annotated_copy_ops, copy_ops) for item in sublist]

    ops.extend(copy_ops)

    return ops


def parse_jsonnet_now(jsonnet_file, ext_vars) -> dict | list:
    try:
        result = subprocess.run(
            parse_jsonnet(jsonnet_file, ext_vars, None),
            capture_output=True,
            check=True,
            text=True)
        return json.loads(result.stdout)
    except subprocess.CalledProcessError as e:
        print(f'Error running jsonnet command: "{" ".join(parse_jsonnet(jsonnet_file, ext_vars, None))}"')
        # try again, but just let the error be printed.
        subprocess.run(
            parse_jsonnet(jsonnet_file, ext_vars, None),
            capture_output=False,
            check=False,
            text=True)
        raise


def parse_jsonnet(jsonnet_file, ext_vars, output_file) -> list:
    proc_args = ['jsonnet']

    if output_file is not None:
        #-'-SS   --##u
        if output_file.endswith('.ini'):
            proc_args.append('-S')
        proc_args.extend(['-o', output_file])

    for (key, val) in ext_vars.items():
        proc_args.extend(['-V', f'{key}={val}'])
    proc_args.append(jsonnet_file)

    return proc_args


def get_ext_vars(host:Host=None) -> list:
    standard_ext_vars = {
        'is_localhost': 'true',
        'cwd': os.getcwd(),
        'home': HOME,
    }
    ret_vars = {} | standard_ext_vars
    if host is not None:
        ret_vars |= {
            'is_localhost': str(host.is_localhost()).lower(),
            'kernel': host.kernel,
            'branch': host.branch,
            'color': host.color,
            'android_wallpaper': os.getcwd() + '/' + host.android_wallpaper.get('local_path') if host.android_wallpaper else '',
        }
    return ret_vars


def preprocess_curl_files(host, staging_dir, verbose=False) -> list:
    if not host.curl_maps:
        return ['No curl maps found']

    full_paths = [(src, os.path.join(staging_dir, dest)) for (src, dest) in host.curl_maps.items()]
    staging_dests = set([os.path.dirname(d) for (_, d) in full_paths])

    ops = [partial(os.makedirs, name=d, exist_ok=True) for d in staging_dests]
    curl_prefix = ['curl', '-s', '-S'] if not verbose else ['curl']
    ops.extend(curl_prefix + ['-L', s, '-o', d] for (s, d) in full_paths)

    return ops

def preprocess_jsonnet_files(host, staging_dir, verbose=False) -> list:
    if not host.jsonnet_maps:
        return ['No jsonnet maps found']

    full_paths = [(os.path.join(Path.cwd(), src), os.path.join(staging_dir, dest)) for (src, dest) in host.jsonnet_maps.items()]
    staging_dests = set([os.path.dirname(d) for (_, d) in full_paths])

    ops = [partial(os.makedirs, name=d, exist_ok=True) for d in staging_dests]
    jsonnet_commands = [parse_jsonnet(s, get_ext_vars(host), d) for (s, d) in full_paths]

    if verbose:
        annotated_jsonnet_commands = [' '.join(j) for j in jsonnet_commands]
        jsonnet_commands = [item for sublist in zip(annotated_jsonnet_commands, jsonnet_commands) for item in sublist]

    ops.extend(jsonnet_commands)

    return ops


def copy_files_local(source_root, source_files, dest_root, dest_files, annotate: bool = False):

    full_path_sources = [os.path.join(source_root, src) for src in source_files]
    full_path_dests = [os.path.join(dest_root, dest) for dest in dest_files]
    ops = [partial(os.makedirs, name=d, exist_ok=True) for d in {os.path.dirname(d) for d in full_path_dests}]

    copy_ops = [partial(shutil.copyfile, src=src, dst=dest) for (src, dest) in zip(full_path_sources, full_path_dests)]
    if annotate:
        annotated_copy_ops = [f'local: cp {src} {dest}' for (src, dest) in zip(full_path_sources, full_path_dests)]
        copy_ops = [item for sublist in zip(annotated_copy_ops, copy_ops) for item in sublist]

    ops.extend(copy_ops)
    return ops


def push_remote(host, shallow, verbose=False) -> list:
    ops = [f'>> Synching dotFiles for {host.hostname}']
    if not host.is_reachable():
        ops.append(f'Host {host.hostname} is not reachable')
        return ops

    ops.append(partial(shutil.rmtree, path=host.get_staging_dir(), ignore_errors=True))

    ops.extend(stage_local(host, verbose=verbose))

    ops.append(f'Copying {len(host.file_maps)} files to {host.hostname} home directory')
    ops.extend(copy_files(config.get_localhost(), host.get_staging_dir(), host.file_maps.keys(), host, HOME, host.file_maps.values(), annotate=True, verbose=verbose))

    if not shallow:
        ops.extend(install_git_plugins(host, 'Vim startup plugin(s)', config.vim_pack_plugin_start_repos, os.path.join('.vim', 'pack', 'plugins', 'start'), verbose=verbose))
        ops.extend(install_git_plugins(host, 'Vim optional plugin(s)', config.vim_pack_plugin_opt_repos, os.path.join('.vim', 'pack', 'plugins', 'opt'), verbose=verbose))
        ops.extend(install_git_plugins(host, 'Zsh plugin(s)', config.zsh_plugin_repos, '.zshext', verbose=verbose))

    ops.append(f'Finished pushing files to {host.hostname}')
    return ops


def process_staged_files(host, files) -> None:
    if not host.macros:
        return

    for file in [f for f in files if Path(f).suffix not in ['.png', '.jpg']]:
        is_modified = False
        modified_content = []
        with open (file, 'r', encoding='utf-8') as f:
            lines:list[str] = f.read().splitlines()
            for line in lines:
                if line in host.macros:
                    is_modified = True
                    modified_content.extend(host.get_inflated_macro(line, file))
                else:
                    modified_content.append(line)
        if is_modified:
            with open(file, 'w', encoding='utf-8') as f:
                f.writelines(line + '\n' for line in modified_content)


def stage_local(host, verbose=False) -> list[str]:
    ops = []

    files_to_stage = list(host.file_maps.keys())
    ops.append('Precaching curl files')
    ops.extend(preprocess_curl_files(host, CWD, verbose=verbose))
    ops.append('Preprocessing jsonnet files')
    ops.extend(preprocess_jsonnet_files(host, CWD, verbose=verbose))
    ops.extend(copy_files_local(CWD, files_to_stage, host.get_staging_dir(), files_to_stage))
    ops.append('Preprocessing macros in local staged files')
    ops.append(partial(process_staged_files, host=host, files=[f'{host.get_staging_dir()}/{file}' for file in files_to_stage]))

    return ops


def pull_remote(host) -> list:
    staging_dir = host.get_staging_dir('ingest')

    ops = [f'>> Snapshotting dotFiles from {host.hostname} into {staging_dir}']
    ops.extend(partial(shutil.rmtree, path=staging_dir, ignore_errors=True))
    # This doesn't decompose the files back into jsonnet. But the directories are diffable with the local staged copies
    ops.extend(copy_files(host, HOME, host.file_maps.values(), config.get_localhost(), staging_dir, host.file_maps.keys()))

    return ops


def bootstrap_windows() -> list:
    ''' Apply environment settings for a new Windows machine. '''
    return [
        ['SETX', 'DOTFILES_SRC_DIR', os.getcwd()]]


def bootstrap_iterm2() -> list:
    ''' Associate the plist for iTerm2 with the dotFiles. '''
    return [
        # Specify the preferences directory
        ['mkdir', '-p', f'{config.config_root}/iterm2'],
        ['defaults', 'write', 'com.googlecode.iterm2', 'PrefsCustomFolder', '-string', f'{config.config_root}/iterm2'],
        # Tell iTerm2 to use the custom preferences in the directory
        ['defaults', 'write', 'com.googlecode.iterm2', 'LoadPrefsFromCustomFolder', '-bool', 'true']]


def iterm2_prefs_plist_location() -> str:
    plist_pref_file_proc = subprocess.run(['defaults', 'read', 'com.googlecode.iterm2', 'PrefsCustomFolder'], check=True, capture_output=True)
    return plist_pref_file_proc.stdout.decode('utf-8').strip() + '/com.googlecode.iterm2.plist'


def build_iterm2_prefs_json() -> dict:
    '''
    Build the repo's iTerm2 preferences, leaving the format in JSON, because it's easier to read...
    '''
    return parse_jsonnet_now('iterm2/com.googlecode.iterm2.plist.jsonnet', get_ext_vars(config.get_localhost()))


def snapshot_iterm2_prefs_json(out_path=None) -> None:
    ''' Snapshot the current iTerm2 preferences json file. '''
    if out_path is None:
        out_path = 'out/com.googlecode.iterm2.active.json'
        print(f'Writing iTerm2 preferences to {out_path}')
    with open(iterm2_prefs_plist_location(), 'rb') as f:
        plist_prefs = plistlib.load(f)
        with open(out_path, 'w', encoding='utf-8') as out:
            json.dump(plist_prefs, out, indent=4, sort_keys=False)


def push_iterm2_prefs(out_path=None) -> None:
    '''
    Build and apply the repo's iTerm2 preferences.
    Requires iTerm2 to not be running or else it will overwrite the output.
    '''
    if out_path is None:
        out_path = iterm2_prefs_plist_location()
    print(f'Writing iTerm2 preferences to {out_path}')
    with open(out_path, 'wb') as f:
        plistlib.dump(build_iterm2_prefs_json(), f)


def compare_iterm2_prefs() -> None:
    snapshot_path = 'out/com.googlecode.iterm2.active.json'
    gen_path = 'out/com.googlecode.iterm2.gen.json'
    snapshot_iterm2_prefs_json(snapshot_path)
    with open(gen_path, 'w', encoding='utf-8') as f:
        json.dump(build_iterm2_prefs_json(), f, indent=4, sort_keys=False)

    print(f'diff {snapshot_path} {gen_path}')


def push_sublimetext_windows_plugins() -> list:
    ''' Setup any Sublime Text plugins for Windows. '''
    return [
        ['cp', 'sublime_text\\*', '"%APPDATA%\\Sublime Text 2\\Packages\\User"']
    ]


def parse_hosts_from_args(host_args) -> list:
    match len(host_args):
        case 0:
            return []
        case 1:
            match host_args[0]:
                case '--all':
                    return config.hosts
                case '--local':
                    return [config.get_localhost()]
                case _:
                    return [ next(h for h in config.hosts if h.hostname == host_args[0]) ]
        case _:
            return [h for h in config.hosts if h.hostname in host_args]


def main(args) -> int:
    ''' Apply dotFiles operations '''
    print_only = False
    if '--dry-run' in args:
        print_only = True
        args.remove('--dry-run')
    shallow = False
    if '--shallow' in args:
        shallow = True
        args.remove('--shallow')
    if '--working-dir' in args:
        index = args.index('--working-dir')
        working_dir = args[index + 1]
        args.remove('--working-dir')
        args.remove(working_dir)
        os.chdir(working_dir)
    verbose=False
    if '--verbose' in args:
        verbose = True
        args.remove('--verbose')
    if '-v' in args:
        verbose = True
        args.remove('-v')
    quiet=False
    if '--quiet' in args:
        quiet = True
        args.remove('--quiet')
    if '-q' in args:
        quiet = True
        args.remove('-q')

    option = args[0]
    host_args = args[1:]

    if option.endswith('-local'):
        option = option[:len(option)-len('-local')]
        host_args = ['--local']
    elif option.endswith('-all'):
        option = option[:len(option)-len('-all')]
        host_args = ['--all']

    if option in ['--push', '--pull', '--stage']:
        all_hosts = parse_hosts_from_args(host_args)
        if len(all_hosts) == 0:
            raise ValueError(f'No hosts found in "{host_args}"')
        # This has the additional benefit of frontloading any ssh related prompts
        remote_hosts = [h for h in all_hosts if not h.is_localhost()]
        if not quiet:
            print(f'Checking reachability of {len(remote_hosts)} hosts...')
        hosts = [h for h in all_hosts if h.is_reachable()]
        if len(hosts) == 0:
            raise ValueError(f'No reachable hosts found in "{host_args}"')
        if all_hosts != hosts:
            print(f'Warning: skipping unreachable hosts: {", ".join(h.hostname for h in all_hosts if h not in hosts)}')

    ops = []
    match option:
        case '--compare-iterm2-prefs':
            ops.append(compare_iterm2_prefs)
        case '--pull-vscode-settings':
            ops.append(pull_vscode_user_settings)
        case '--push-vscode-settings':
            ops.append(push_vscode_user_settings)
        case '--update-workspace-extensions':
            ops.append(update_workspace_extensions)
        case '--generate-workspace':
            ops.append(generate_derived_workspace)
        case '--bootstrap-iterm2':
            ops.extend(bootstrap_iterm2())
        case '--snapshot-iterm2-prefs-json':
            ops.append(snapshot_iterm2_prefs_json)
        case '--push-iterm2-prefs':
            ops.append(push_iterm2_prefs)
        case '--bootstrap-windows':
            ops.extend(bootstrap_windows())
        case '--install-sublime-plugins':
            ops.extend(push_sublimetext_windows_plugins())
        case '--push':
            ops.extend(chain.from_iterable([push_remote(host, shallow, verbose=verbose) for host in hosts]))
        case '--stage':
            ops.extend(chain.from_iterable([stage_local(host, verbose=verbose) for host in hosts]))
        case '--pull':
            if len(hosts) != 1:
                raise ValueError('Cannot pull from multiple hosts')
            ops.extend(pull_remote(hosts[0]))
        case _:
            print('<unknown arg>')
            return 1

    if print_only:
        print_ops(ops, quiet=quiet)
    else:
        run_ops(ops, quiet=quiet)
    return 0


def process_apply_configs() -> Config:
    ''' Process any config files that need to be initialized. '''
    config_file = Path.joinpath(Path.cwd(), 'apply_configs.jsonnet')
    if not Path.is_file(config_file):
        raise ValueError('Missing config file')

    config_dict = parse_jsonnet_now(str(config_file), get_ext_vars())
    return Config(**config_dict)


if __name__ == "__main__":
    ensure_out_dir()
    config = process_apply_configs()

    if len(sys.argv) < 2:
        print('<missing args>')
        sys.exit(1)
    else:
        sys.exit(main(sys.argv[1:]))

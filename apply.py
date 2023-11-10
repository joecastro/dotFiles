#!/usr/bin/env python3

# pylint: disable=too-many-arguments, missing-module-docstring, missing-function-docstring, line-too-long

from itertools import chain
import json
import os
from pathlib import Path
import plistlib
import re
import shutil
import subprocess
import sys
import _jsonnet

HOME = str(Path.home())
CWD = '.'

config = {}

def is_localhost(host) -> bool:
    return host['hostname'] == os.uname().nodename


def get_localhost() -> dict:
    return next(h for h in config['hosts'] if h['hostname'] == os.uname().nodename)


def annotate_ops(ops) -> list:
    ret = []
    for op_list in ops:
        ret.append(f'local: {" ".join(op_list)}')
        ret.append(op_list)

    return ret


def print_ops(ops) -> None:
    for entry in ops:
        if isinstance(entry, str):
            print(entry)
        elif isinstance(entry, list):
            print(f'DEBUG: {" ".join(entry)}')
        elif callable(entry):
            print(f'DEBUG: invoking function {entry}')
        else:
            raise TypeError('Bad operation type')


def run_ops(ops) -> None:
    for entry in ops:
        if isinstance(entry, str):
            print(entry)
        elif isinstance(entry, list):
            subprocess.run(entry, check=True)
        elif callable(entry):
            entry()
        else:
            raise TypeError('Bad operation type')


def ensure_out_dir() -> None:
    out_dir = 'out'
    if not os.path.exists(out_dir):
        os.makedirs(out_dir)


def update_workspace_extensions() -> None:
    workspace_path = config.get('workspace')
    with open(workspace_path, encoding='utf-8') as f:
        workspace = json.load(f)

    completed_proc = subprocess.run(['code', '--list-extensions'], check=True, capture_output=True)
    installed_extensions = completed_proc.stdout.decode('utf-8').splitlines()

    workspace['extensions']['recommendations'] = installed_extensions

    with open(workspace_path, 'w', encoding='utf-8') as f:
        json.dump(workspace, f, indent=4, sort_keys=False)


def push_vscode_user_settings() -> None:
    dotfiles_settings_location = 'vscode/settings.json'
    mac_settings_location = f'{HOME}/Library/Application Support/Code/User/settings.json'

    # Open this as a json file first, just to make sure it parses properly.
    with open(dotfiles_settings_location, encoding='utf-8') as f:
        json.load(f)

    shutil.copyfile(dotfiles_settings_location, mac_settings_location)


def generate_derived_workspace() -> None:
    base_workspace_path = config.get('workspace')
    workspace_overrides = config.get('workspace_overrides')
    if not base_workspace_path or not workspace_overrides:
        print('Skipping workspace generation because no overrides were specified.')
        return

    # code-workspaces are JSON files that support comments.
    # If I want to support that, jsmin will strip comments and make the content json compliant.
    with open(base_workspace_path, encoding='utf-8') as original_workspace:
        workspace = json.load(original_workspace)

    workspace['folders'] = workspace_overrides['folders']
    if workspace_overrides.get('settings'):
        for (key, value) in workspace_overrides['settings'].items():
            workspace['settings'][key] = value

    print(json.dumps(workspace, indent=4, sort_keys=False))


def install_zsh_plugin_ops(host, zsh_plugin_repos) -> list:
    hostname = host['hostname']

    ops = [f'>> Cloning {len(zsh_plugin_repos)} Zsh plugins for {hostname}']
    plugin_root = f'{HOME}/.zshext' if is_localhost(host) else './.zshext'
    ops.append(['rm', '-rf', plugin_root])
    pattern = re.compile("([^/]+)\\.git$")
    for repo in zsh_plugin_repos:
        target_path = f'{plugin_root}/{pattern.search(repo).group(1)}'
        ops.append(f'Cloning into {target_path}...')
        ops.append(['git', 'clone', '-q', repo, target_path])

    if is_localhost(host):
        return ops

    return [['ssh', hostname, ' '.join(op)] if isinstance(op, list) else op for op in ops]


def install_vim_plugin_ops(host, vim_pack_plugin_start_repos, vim_pack_plugin_opt_repos) -> list:
    hostname = host['hostname']

    ops = [f'>> Cloning {len(vim_pack_plugin_start_repos) + len(vim_pack_plugin_opt_repos)} Vim plugins for {hostname}']
    pack_root = f'{HOME}/.vim/pack' if is_localhost(host) else './.vim/pack'
    ops.append(['rm', '-rf', pack_root])
    pattern = re.compile("([^/]+)\\.git$")
    for (infix, repos) in [('plugins/start', vim_pack_plugin_start_repos),
                           ('plugins/opt', vim_pack_plugin_opt_repos)]:
        for plugin_repo in repos:
            target_path = f'{pack_root}/{infix}/{pattern.search(plugin_repo).group(1)}'
            ops.append(f'Cloning into {target_path}...')
            ops.append(['git', 'clone', '-q', plugin_repo, target_path])

    if is_localhost(host):
        return ops

    return [['ssh', hostname, ' '.join(op)] if isinstance(op, list) else op for op in ops]


def copy_files(source_host, source_root, source_files, dest_host, dest_root, dest_files, annotate=False) -> list:
    is_remote_target = dest_host is not None and not is_localhost(dest_host)
    is_remote_source = source_host is not None and not is_localhost(source_host)

    if is_remote_target and dest_root == HOME:
        dest_root = CWD
    if is_remote_source and source_root == HOME:
        source_root = CWD

    if not is_remote_target and not is_remote_source:
        return copy_files_local(source_root, source_files, dest_root, dest_files, annotate)

    if not is_remote_source:
        source_prefix = source_root
    else:
        source_prefix = source_host['hostname'] + ':' + source_root

    if not is_remote_target:
        dest_prefix = dest_root
    else:
        dest_prefix = dest_host['hostname'] + ':' + dest_root

    ops = []

    dest_subfolders = {os.path.dirname(d) for d in dest_files if os.path.dirname(d)}
    mkdir_ops = [['mkdir', '-p', f'{dest_root}/{sub}'] for sub in dest_subfolders]

    if is_remote_target:
        mkdir_ops = [['ssh', dest_host['hostname'], ' '.join(op)] for op in mkdir_ops]

    ops.extend(mkdir_ops)

    ops.extend([['scp', f'{source_prefix}/{src}', f'{dest_prefix}/{dest}']
                 for (src, dest) in zip(source_files, dest_files)])

    return ops


def parse_jsonnet_now(jsonnet_file, ext_vars) -> dict | list:
    return json.loads(_jsonnet.evaluate_file(jsonnet_file, ext_vars=ext_vars))


def parse_jsonnet(jsonnet_file, ext_vars, output_file) -> list:
    proc_args = ['jsonnet']

    #-'-SS   --##u
    if output_file.endswith('.ini'):
        proc_args.append('-S')
    proc_args.extend(['-o', output_file])

    for (key, val) in ext_vars.items():
        proc_args.extend(['-V', f'{key}={val}'])
    proc_args.append(jsonnet_file)

    return proc_args


def get_ext_vars(host) -> list:
    return {
        'hostname': host.get('hostname'),
        'cwd': os.getcwd(),
        'home': HOME,
        'branch': host.get('branch', 'none'),
        'color': host.get('color', 'default')
    }

def preprocess_jsonnet_files(host, staging_dir) -> list:
    jsonnet_maps = host['jsonnet_maps']
    if not jsonnet_maps:
        return []

    full_paths = [(str(Path.joinpath(Path.cwd(), src)), f'{staging_dir}/{dest}') for (src, dest) in jsonnet_maps]
    staging_dests = set([os.path.dirname(d) for (_, d) in full_paths])

    ext_vars = get_ext_vars(host)

    ops = [['mkdir', '-p', d] for d in staging_dests]
    ops.extend(parse_jsonnet(s, ext_vars, d) for (s, d) in full_paths)

    return ops


def copy_files_local(source_root, source_files, dest_root, dest_files, annotate: bool = False):
    full_paths = [(f'{source_root}/{src}', f'{dest_root}/{dest}') for (src, dest) in zip(source_files, dest_files)]

    copy_ops = [['cp', src, dest] for (src, dest) in full_paths]

    if annotate:
        copy_ops = annotate_ops(copy_ops)

    dest_subfolders = {os.path.dirname(d) for (_, d) in full_paths}
    ops = [['mkdir', '-p', d] for d in dest_subfolders]
    ops.extend(copy_ops)
    return ops


def get_staging_dir(host):
    return f'{CWD}/out/{host["hostname"]}-dot'


def push_remote(host, shallow):
    hostname = host['hostname']
    file_maps = dict(host['file_maps'])

    staging_dir = get_staging_dir(host)
    ops = [f'>> Synching dotFiles for {hostname}']
    ops.append(['rm', '-rf', staging_dir])

    ops.extend(stage_local(host, staging_dir))

    ops.append(f'Copying {len(file_maps)} files to {hostname} home directory')
    ops.extend(copy_files(None, staging_dir, file_maps.keys(), host, HOME, file_maps.values(), annotate=True))

    if not shallow:
        ops.extend(install_vim_plugin_ops(host, config.get('vim_pack_plugin_start_repos'), config.get('vim_pack_plugin_opt_repos')))
        ops.extend(install_zsh_plugin_ops(host, config.get('zsh_plugin_repos')))

    return ops


def stage_local(host, staging_dir):
    ops = []
    file_maps = dict(host['file_maps'])

    ops.append('Preprocessing jsonnet files')
    ops.extend(preprocess_jsonnet_files(host, CWD))
    ops.extend(copy_files_local(CWD, file_maps.keys(), staging_dir, file_maps.keys()))

    return ops


def stage_remote(host, staging_dir):
    hostname = host['hostname']
    file_maps = dict(host['file_maps'])

    ops = [f'>> Snapshotting dotFiles from {hostname} into {staging_dir}']
    ops.extend(['rm', '-rf', staging_dir])
    # This doesn't decompose the files back into jsonnet. But the directories are diffable with the local staged copies
    ops.extend(copy_files(host, HOME, file_maps.values(), None, staging_dir, file_maps.keys()))

    return ops


def pull_remote(host) -> list:
    hostname = host['hostname']
    staging_dir = f'{CWD}/out/{hostname}-ingest'
    return stage_remote(host, staging_dir)


def bootstrap_windows() -> list:
    ''' Apply environment settings for a new Windows machine. '''
    return [
        ['SETX', 'DOTFILES_SRC_DIR', os.getcwd()]]


def bootstrap_iterm2() -> list:
    ''' Associate the plist for iTerm2 with the dotFiles. '''
    return [
        # Specify the preferences directory
        ['defaults', 'write', 'com.googlecode.iterm2', 'PrefsCustomFolder', '-string', f'{os.getcwd()}/iterm2'],
        # Tell iTerm2 to use the custom preferences in the directory
        ['defaults', 'write', 'com.googlecode.iterm2', 'LoadPrefsFromCustomFolder', '-bool', 'true']]


def iterm2_prefs_plist_location() -> str:
    plist_pref_file_proc = subprocess.run(['defaults', 'read', 'com.googlecode.iterm2', 'PrefsCustomFolder'], check=True, capture_output=True)
    return plist_pref_file_proc.stdout.decode('utf-8').strip() + '/com.googlecode.iterm2.plist'


def build_iterm2_prefs_json() -> dict:
    '''
    Build the repo's iTerm2 preferences, leaving the format in JSON, because it's easier to read...
    '''
    return parse_jsonnet_now('iterm2/com.googlecode.iterm2.plist.jsonnet', get_ext_vars(get_localhost()))


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
                    return config['hosts']
                case '--local':
                    return [get_localhost()]
        case _:
            return [h for h in config['hosts'] if h['hostname'] in host_args]


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

    option = args[0]
    host_args = args[1:]

    if option.endswith('-local'):
        option = option[:len('-local')]
        host_args = ['--local']

    if option in ['--push', '--pull', '--stage']:
        hosts = parse_hosts_from_args(host_args)
        if len(hosts) == 0:
            raise ValueError(f'No hosts found in "{host_args}"')

    ops = []
    match option:
        case '--compare-iterm2-prefs':
            ops.append(compare_iterm2_prefs)
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
            ops.extend(chain.from_iterable([push_remote(host, shallow) for host in hosts]))
        case '--stage':
            ops.extend(chain.from_iterable([stage_local(host, get_staging_dir(host)) for host in hosts]))
        case '--pull':
            if len(hosts) != 1:
                raise ValueError('Cannot pull from multiple hosts')
            ops.extend(pull_remote(hosts[0]))
        case _:
            print('<unknown arg>')
            return 1

    if print_only:
        print_ops(ops)
    else:
        run_ops(ops)
    return 0


def process_apply_configs() -> dict:
    ''' Process any config files that need to be initialized. '''
    config_file = Path.joinpath(Path.cwd(), 'apply_configs.jsonnet')
    if not Path.is_file(config_file):
        raise ValueError('Missing config file')

    return parse_jsonnet_now(str(config_file), get_ext_vars({'hostname': os.uname().nodename}))


if __name__ == "__main__":
    ensure_out_dir()
    config = process_apply_configs()

    if len(sys.argv) < 2:
        print('<missing args>')
        sys.exit(1)
    else:
        sys.exit(main(sys.argv[1:]))

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

BASH_COMMAND_PREFIX = 'BASH_COMMAND: '
@dataclass
# pylint: disable-next=too-many-instance-attributes
class Host:
    hostname: str
    branch: str | None = None
    kernel: str = 'linux'
    config_dir: str = None
    file_maps: list[tuple[str, str]] | dict[str, str] = field(default_factory=list)
    directory_maps: list[tuple[str, str]] | dict[str, str] = field(default_factory=list)
    jsonnet_maps: list[tuple[str, str, str]] | dict[str, str] = field(default_factory=list)
    jsonnet_multi_maps: list[tuple[str, str, str]] | dict[str, str] = field(default_factory=list)
    curl_maps: list[tuple[str, str, str]] | dict[str, str] = field(default_factory=list)
    macros: dict[str, list[str]] = field(default_factory=dict)

    prestaged_files: set[str] = field(default_factory=set)
    prestaged_directories: set[str] = field(default_factory=set)

    def __post_init__(self):
        if self.hostname == 'localhost':
            self.hostname = platform.uname().node
        if self.hostname == platform.uname().node:
            self.kernel = platform.uname().system.lower()
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

    def __repr__(self) -> str:
        return self.hostname

    def is_localhost(self) -> bool:
        return self.hostname == platform.uname().node

    def get_local_staging_dir(self, suffix='dot') -> str:
        return os.path.join(CWD, 'out', f'{self.hostname}-{suffix}')

    def get_remote_staging_dir(self) -> str:
        if self.is_localhost():
            return self.get_local_staging_dir()
        return os.path.join(self.config_dir, 'staging')

    def get_inflated_macro(self, key, file_path) -> list[str]:
        return [v.replace('@@FILE_NAME', Path(file_path).stem.upper())
                 .replace('@@NOW', datetime.now().strftime("%Y-%m-%d %H:%M")) for v in self.macros[key]]

    def is_reachable(self) -> bool:
        if self.is_localhost():
            return True
        return subprocess.run(['ssh', '-o', 'ConnectTimeout=10', '-t',  self.hostname, 'echo "ping check"'], capture_output=True, check=False).returncode == 0

    def does_directory_exist(self, path) -> bool:
        if self.is_localhost():
            return os.path.exists(path)
        return subprocess.run(['ssh', self.hostname, f'test -d {path}'], capture_output=True, check=False).returncode == 0

    def make_ops(self, ops: list[list]) -> list:
        if self.is_localhost():
            return ops

        return [['ssh', self.hostname, ' '.join(op)] if isinstance(op, list) else op for op in ops]


@dataclass
class Config:
    hosts: list[Host]
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
            if str.startswith(entry, BASH_COMMAND_PREFIX):
                raise ValueError('Any Bash commands should have been shelled out through a script')
            if not quiet:
                print(entry)
        elif isinstance(entry, list):
            print(f'DEBUG: {" ".join(entry)}')
        elif callable(entry):
            func_args = ', '.join([k+"="+str(v) for k, v in entry.keywords.items()])
            print(f'DEBUG: invoking {entry.func.__name__}({func_args})')
        else:
            raise TypeError('Bad operation type')


def run_ops(ops: list, quiet=False) -> None:
    for entry in ops:
        if isinstance(entry, str):
            if str.startswith(entry, BASH_COMMAND_PREFIX):
                raise ValueError('Any Bash commands should have been shelled out through a script')
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


def install_git_plugins_local(plugin_type: str, repo_list: list[str], install_root: str, clean: bool=False) -> list:
    pattern = re.compile("([^/]+)\\.git$")

    if clean:
        ops = [f'>> Cloning {len(repo_list)} {plugin_type}']
        ops.append(['rm', '-rf', install_root])
        for (repo, target_path) in [(r, os.path.join(install_root, pattern.search(r).group(1))) for r in repo_list]:
            ops.append(['git', 'clone', '-q', repo, target_path])

        return ops

    ops = [f'>> Updating {len(repo_list)} {plugin_type}']
    ops.append(['mkdir', '-p', f'"{install_root}"'])
    ops.append(['cd', install_root])
    for (repo, target_path) in [(r, os.path.join(install_root, pattern.search(r).group(1))) for r in repo_list]:
        ops.append(f'''{BASH_COMMAND_PREFIX}
if [ -d "{target_path}" ]; then
    cd "{target_path}"
    git pull -q
    cd - > /dev/null
else
    git clone -q "{repo}" "{target_path}"
fi''')

    return ops


def remove_parents_from_set(paths: set[str]) -> set[str]:
    return {d for d in paths if not any(subdir != d and subdir.startswith(d) for subdir in paths)}


def remove_children_from_set(paths: set[str], root: str = '') -> set[str]:
    return {d for d in paths if not any(subdir != d and d.startswith(subdir) for subdir in paths) and not d.startswith(root)}


def copy_directories_local(source_root, source_dirs, dest_root, dest_dirs, use_cp, verbose=False) -> list:
    ops = []

    full_destination_paths = remove_parents_from_set({os.path.join(dest_root, dest) for dest in dest_dirs})

    ops.extend([['mkdir', '-p', d] for d in full_destination_paths])
    for src, dest in zip(source_dirs, dest_dirs):
        src_path = os.path.join(source_root, src)
        dest_path = os.path.join(dest_root, dest)
        if verbose:
            ops.append(f'local: cp -r {src_path}/* {dest_path}')
        if use_cp:
            ops.append(['cp', '-r', f'{src_path}/*', dest_path])
        else:
            ops.append(partial(shutil.copytree, src=src_path, dst=dest_path, dirs_exist_ok=True))

    return ops


def parse_jsonnet_now(jsonnet_file, ext_vars, output_string=False) -> dict | list | str:
    try:
        result = subprocess.run(
            parse_jsonnet(jsonnet_file, ext_vars, None, output_string=output_string),
            capture_output=True,
            check=True,
            text=True)
        if output_string:
            return result.stdout
        return json.loads(result.stdout)
    except subprocess.CalledProcessError:
        print(f'Error running jsonnet command: "{" ".join(parse_jsonnet(jsonnet_file, ext_vars, None))}"')
        # try again, but just let the error be printed.
        subprocess.run(
            parse_jsonnet(jsonnet_file, ext_vars, None),
            capture_output=False,
            check=False,
            text=True)
        raise


def parse_jsonnet(jsonnet_file, ext_vars, output_path, is_multicast=False, output_string=False) -> list:
    proc_args = ['jsonnet']

    if output_path is not None:
        output_string |= output_path.endswith('.sh') or output_path.endswith('.ini')

    if output_string:
        proc_args.append('-S')

    if not is_multicast:
        if output_path is not None:
            proc_args.extend(['-o', output_path])
    else:
        proc_args.extend(['-m', output_path])


    for (key, val) in ext_vars.items():
        proc_args.extend(['-V', f'{key}={val}'])
    proc_args.append(jsonnet_file)

    return proc_args


def get_ext_vars(host:Host=None) -> list:
    standard_ext_vars = {
        'is_localhost': 'true',
        'hostname': platform.uname().node,
        'kernel': platform.uname().system.lower(),
        'cwd': os.getcwd(),
        'home': HOME,
    }
    ret_vars = {} | standard_ext_vars
    if host is not None:
        ret_vars |= {
            'is_localhost': str(host.is_localhost()).lower(),
            'hostname': host.hostname,
            'kernel': host.kernel,
        }
    return ret_vars


def preprocess_curl_files(host, staging_dir, verbose=False) -> list:
    if not host.curl_maps:
        return ['No curl maps found']

    full_paths = [(src, os.path.join(staging_dir, dest)) for (src, dest) in host.curl_maps.items()]
    staging_dests = set([os.path.dirname(d) for (_, d) in full_paths])

    ops = [['mkdir', '-p', d] for d in staging_dests]
    curl_prefix = ['curl', '-s', '-S'] if not verbose else ['curl']
    ops.extend(curl_prefix + ['-L', s, '-o', d] for (s, d) in full_paths)

    return ops

def preprocess_jsonnet_files(host, source_dir, staging_dir, verbose=False) -> list:
    if not host.jsonnet_maps:
        return ['No jsonnet maps found']

    full_paths = [(os.path.join(source_dir, src), os.path.join(staging_dir, dest)) for (src, dest) in host.jsonnet_maps.items()]
    staging_dests = set([os.path.dirname(d) for (_, d) in full_paths])

    ops = [['mkdir', '-p', d] for d in staging_dests]
    jsonnet_commands = [parse_jsonnet(s, get_ext_vars(host), d) for (s, d) in full_paths]

    if verbose:
        annotated_jsonnet_commands = [' '.join(j) for j in jsonnet_commands]
        jsonnet_commands = [item for sublist in zip(annotated_jsonnet_commands, jsonnet_commands) for item in sublist]

    ops.extend(jsonnet_commands)

    return ops


def preprocess_jsonnet_directories(host, source_dir, staging_dir, verbose=False) -> list:
    if not host.jsonnet_multi_maps:
        return ['No jsonnet multimaps found']

    full_paths = [(os.path.join(source_dir, src), os.path.join(staging_dir, dest)) for (src, dest) in host.jsonnet_multi_maps.items()]
    staging_dests = set([d for (_, d) in full_paths])

    ops = [['mkdir', '-p', d] for d in staging_dests]
    jsonnet_commands = [parse_jsonnet(s, get_ext_vars(host), d, is_multicast=True, output_string=True) for (s, d) in full_paths]

    if verbose:
        annotated_jsonnet_commands = [' '.join(j) for j in jsonnet_commands]
        jsonnet_commands = [item for sublist in zip(annotated_jsonnet_commands, jsonnet_commands) for item in sublist]

    ops.extend(jsonnet_commands)

    return ops


def copy_files_local(source_root, source_files, dest_root, dest_files, annotate: bool = False):
    full_path_sources = [os.path.join(source_root, src) for src in source_files]
    full_path_dests = [os.path.join(dest_root, dest) for dest in dest_files]

    for i in range(len(full_path_sources)-1, -1, -1):
        if full_path_dests[i].startswith(os.getcwd()):
            del full_path_sources[i]
            del full_path_dests[i]

    full_path_directories = remove_parents_from_set({os.path.dirname(d) for d in full_path_dests})

    ops = [['mkdir', '-p', d] for d in full_path_directories]

    copy_ops = [['cp', src, dest] for (src, dest) in zip(full_path_sources, full_path_dests)]
    if annotate:
        annotated_copy_ops = [f'local: cp {src} {dest}' for (src, dest) in zip(full_path_sources, full_path_dests)]
        copy_ops = [item for sublist in zip(annotated_copy_ops, copy_ops) for item in sublist]

    ops.extend(copy_ops)
    return ops


def install_vscode_extensions(host, verbose=False) -> list:
    if host.is_localhost():
        return []

    extensions_list = []
    with open(os.path.join('vscode', 'dotFiles_extensions.json'), encoding='utf-8') as f:
        extensions_json = json.load(f)
        extensions_list = extensions_json.get('recommendations', [])

    completed_proc = subprocess.run(['ssh', host.hostname, 'code --list-extensions'], check=False, capture_output=True)
    if completed_proc.returncode != 0:
        return [f'Failed listing vscode extensions on {host.hostname}']

    installed_extensions_list = completed_proc.stdout.decode('utf-8').splitlines()

    extensions_to_install = [ext for ext in extensions_list if ext not in installed_extensions_list]
    extensions_to_remove = [ext for ext in installed_extensions_list if ext not in extensions_list]
    if not extensions_to_install and not extensions_to_remove:
        if verbose:
            return ['>> No vscode extensions to install']
        return []

    if extensions_to_install:
        ops = [
            f'>> Installing {len(extensions_to_install)} vscode extensions',
            ['ssh', host.hostname, '; '.join([f'code --install-extension {ext}' for ext in extensions_to_install])]]

    if extensions_to_remove:
        ops = [
            f'>> Removing {len(extensions_to_remove)} vscode extensions',
            ['ssh', host.hostname, '; '.join([f'code --uninstall-extension {ext}' for ext in extensions_to_remove])]]
    return ops


def make_finish_script(host, command_ops, script_path: str, verbose) -> list:

    def do_write():
        with open(script_path, 'w', encoding='utf-8') as f:
            f.write('#!/bin/bash\n')
            f.write('\n')
            f.write('set -e\n')
            f.write('\n')
            if verbose:
                f.write('set -x\n')
                f.write('\n')
            for op in command_ops:
                if isinstance(op, str):
                    if op.startswith(BASH_COMMAND_PREFIX):
                        op = op[len(BASH_COMMAND_PREFIX):]
                        for line in op.split('\n'):
                            if line:
                                f.write(f'{line}\n')
                    else:
                        f.write('echo "' + op + '"\n')
                else:
                    f.write(' '.join([o.replace(' ', '\\ ') for o in op]) + '\n')

    ops = [partial(do_write)]

    if verbose:
        ops.append(f'Generated finish script at {script_path}')
    ops.append(['chmod', 'u+x', script_path])

    return ops


def push_remote_staging(host, verbose=False) -> list:
    ops = [f'Synching dotFiles for {host.hostname} from local staging directory']

    # Clean the remote dotFiles
    root_files_to_remove = []
    root_files_to_remove.extend(host.file_maps.values())
    root_files_to_remove.extend(host.directory_maps.values())
    root_files_to_remove.append(host.config_dir)

    if host.is_localhost():
        root_files_to_remove = {os.path.join(HOME, f) for f in root_files_to_remove}
    else:
        root_files_to_remove.append(host.get_remote_staging_dir())
        root_files_to_remove = set(root_files_to_remove)

    root_files_to_remove = list(remove_children_from_set(root_files_to_remove, os.getcwd()))
    # Trying to overall minimize the number of SSH handshakes...
    ops.append(f'>> Cleaning existing configuration files for {host.hostname}: {", ".join(root_files_to_remove)}')
    # 1
    ops.extend(host.make_ops([['rm', '-rf'] + root_files_to_remove]))

    if not host.is_localhost():
        ops.append(f'>> Copying {len(host.file_maps) + 1} files and {len(host.directory_maps)} folders to {host.hostname} home directory')
        # 2
        ops.extend(host.make_ops([['mkdir', '-p', host.get_remote_staging_dir()]]))
        if verbose:
            ops.append(f'>> Copying staging directory to {host.hostname} ({host.get_remote_staging_dir()})')
        # 3
        scp_prefix = ['scp', '-r', '-q'] if not verbose else ['scp', '-r']
        ops.append(scp_prefix + [f'{host.get_local_staging_dir()}/.', f'{host.hostname}:{host.get_remote_staging_dir()}'])

    ops.append(f'>> Running finish script on {host.hostname}: {host.get_remote_staging_dir()}/finish.sh')
    # 4
    ops.extend(host.make_ops([['/bin/bash', host.get_remote_staging_dir() + '/finish.sh']]))

    return ops


def process_staged_file(host, file) -> None:
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


def stage_local(host, shallow, verbose=False) -> list[str]:
    ops = [f'Staging dotFiles for {host.hostname} in {host.get_local_staging_dir()}']

    ops.append(['rm', '-rf', host.get_local_staging_dir()])

    files_to_stage = [file for file in host.file_maps.keys() if file not in host.prestaged_files]
    directories_to_stage = [dir for dir in host.directory_maps.keys() if dir not in host.prestaged_directories]
    ops.append('>> Precaching curl files')
    ops.extend(preprocess_curl_files(host, host.get_local_staging_dir(), verbose=verbose))
    ops.append('>> Preprocessing jsonnet files')
    ops.extend(preprocess_jsonnet_files(host, CWD, host.get_local_staging_dir(), verbose=verbose))
    ops.extend(preprocess_jsonnet_directories(host, CWD, host.get_local_staging_dir(), verbose=verbose))
    # Copy directories first. Any files that may be explicitly copied can overwrite these.
    ops.append('>> Staging directories and files')
    ops.extend(copy_directories_local(CWD, directories_to_stage, host.get_local_staging_dir(), directories_to_stage, False))
    ops.extend(copy_files_local(CWD, files_to_stage, host.get_local_staging_dir(), files_to_stage))
    if host.macros:
        files_to_process = [f'{host.get_local_staging_dir()}/{file}' for file in host.file_maps.keys() if Path(file).suffix not in ['.png', '.jpg', '.svg']]
        ops.append('>> Preprocessing macros in local staged files')
        process_ops = []
        for f in files_to_process:
            if verbose:
                process_ops.append(f'Processing macros in {f}')
            process_ops.append(partial(process_staged_file, host=host, file=f))
        ops.extend(process_ops)

    finish_ops = []
    finish_ops.extend(copy_files_local(host.get_remote_staging_dir(), host.file_maps.keys(), '~', host.file_maps.values()))
    finish_ops.extend(copy_directories_local(host.get_remote_staging_dir(), host.directory_maps.keys(), '~', host.directory_maps.values(), True))

    if not shallow:
        finish_ops.extend(install_git_plugins_local('Vim startup plugin(s)', config.vim_pack_plugin_start_repos, os.path.join('$HOME', '.vim', 'pack', 'plugins', 'start')))
        finish_ops.extend(install_git_plugins_local('Vim optional plugin(s)', config.vim_pack_plugin_opt_repos, os.path.join('$HOME', '.vim', 'pack', 'plugins', 'opt')))
        finish_ops.extend(install_git_plugins_local('Zsh plugin(s)', config.zsh_plugin_repos, os.path.join('$HOME', '.zshext')))

    # Skip this for now because of the extra SSH calls it triggers.
    # finish_ops.append(f'>> Pushing vscode extensions to {host.hostname}')
    # finish_ops.extend(install_vscode_extensions(host, verbose=verbose))
    # finish_ops.append(f'Finished pushing files to {host.hostname}')

    finish_script = os.path.join(host.get_local_staging_dir(), 'finish.sh')
    ops.extend(make_finish_script(host, finish_ops, finish_script, verbose=verbose))

    return ops


def pull_remote(host: Host) -> list[str]:
    snapshot_dir = host.get_local_staging_dir('ingest')
    ops = [
        f'Recreating staged dotFiles for {host.hostname}',
        partial(shutil.rmtree, path=snapshot_dir, ignore_errors=True),
        ['mkdir', '-p', snapshot_dir]]

    ops.extend(host.make_ops([
        ['rm', '-rf', host.get_remote_staging_dir()],
        ['mkdir', '-p', host.get_remote_staging_dir()]
    ]))

    if host.is_localhost():
        ops.extend(copy_directories_local('~', host.directory_maps.values(),  snapshot_dir, host.directory_maps.keys(), True))
        ops.extend(copy_files_local('~', host.file_maps.values(), snapshot_dir, host.file_maps.keys()))
    else:
        remote_ops = ['>> Unstaging directories and files']
        remote_ops.extend(copy_directories_local('~', host.directory_maps.values(),  host.get_remote_staging_dir(), host.directory_maps.keys(), True))
        remote_ops.extend(copy_files_local('~', host.file_maps.values(), host.get_remote_staging_dir(), host.file_maps.keys()))

        unfinish_script = os.path.join(snapshot_dir, 'unfinish.sh')
        ops.extend(make_finish_script(host, remote_ops, unfinish_script, verbose=False))

        ops.append(f'>> Copying unfinish script to {host.hostname}')
        ops.append(['scp', unfinish_script, f'{host.hostname}:{host.get_remote_staging_dir()}'])

        ops.extend(host.make_ops([['/bin/bash', './' + host.get_remote_staging_dir() + '/unfinish.sh']]))

        ops.append(['scp', '-r', f'{host.hostname}:{host.get_remote_staging_dir()}/.', snapshot_dir])

    return ops


def bootstrap_windows() -> list:
    ''' Apply environment settings for a new Windows machine. '''
    return [
        ['SETX', 'DOTFILES_SRC_DIR', os.getcwd()]]


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


def push_iterm2_prefs() -> None:
    '''
    Build and apply the repo's iTerm2 preferences.
    Requires iTerm2 to not be running or else it will overwrite the output.
    '''

    ''' Associate the plist for iTerm2 with the dotFiles. '''
    iterm2_config_root = Path.joinpath(Path.home(), config.get_localhost().config_dir, 'iterm2')
    run_ops([
        # Specify the preferences directory
        ['mkdir', '-p', iterm2_config_root],
        ['defaults', 'write', 'com.googlecode.iterm2', 'PrefsCustomFolder', '-string', iterm2_config_root],
        # Tell iTerm2 to use the custom preferences in the directory
        ['defaults', 'write', 'com.googlecode.iterm2', 'LoadPrefsFromCustomFolder', '-bool', 'true']])

    out_path = iterm2_prefs_plist_location()
    print(f'Writing iTerm2 preferences to {out_path}')
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    with open(out_path, 'wb') as f:
        plistlib.dump(build_iterm2_prefs_json(), f)


def compare_iterm2_prefs() -> None:
    snapshot_path = 'out/com.googlecode.iterm2.active.json'
    gen_path = 'out/com.googlecode.iterm2.gen.json'
    snapshot_iterm2_prefs_json(snapshot_path)
    with open(gen_path, 'w', encoding='utf-8') as f:
        json.dump(build_iterm2_prefs_json(), f, indent=4, sort_keys=False)

    print(f'diff {snapshot_path} {gen_path}')


def compare_user_settings(host) -> None:
    target_jsonnet_map_entry = next((entry for entry in host.jsonnet_maps.items() if entry[0] == 'vscode/user_settings.jsonnet'), None)
    if not target_jsonnet_map_entry:
        print(f'No vscode user settings for {host.hostname}')
    target_target_jsonnet_map_entry = next((entry for entry in host.file_maps.items() if entry[0] == target_jsonnet_map_entry[1]), None)
    if not target_target_jsonnet_map_entry:
        raise ValueError(f'No vscode user settings file for {host.hostname}')

    template_path = target_jsonnet_map_entry[0]
    gen_path = os.path.join(host.get_local_staging_dir(), os.path.splitext(target_jsonnet_map_entry[1])[0] + '.gen.json')
    original_path = os.path.join(HOME, target_target_jsonnet_map_entry[1])
    snapshot_path = os.path.join(host.get_local_staging_dir(), os.path.splitext(target_jsonnet_map_entry[1])[0] + '.snapshot.json')

    with open(gen_path, 'w', encoding='utf-8') as f:
        gen_user_settings = parse_jsonnet_now(template_path, get_ext_vars(host))
        json.dump(gen_user_settings, f, indent=4, sort_keys=True)

    with open(original_path, encoding='utf-8') as in_path:
        current_settings = json.load(in_path)
        with open(snapshot_path, 'w', encoding='utf-8') as out_path:
            json.dump(current_settings, out_path, indent=4, sort_keys=True)

    print(f'diff "{snapshot_path}" "{gen_path}"')


def push_sublimetext_windows_plugins() -> list:
    ''' Setup any Sublime Text plugins for Windows. '''
    return [
        ['cp', 'sublime_text\\*', '"%APPDATA%\\Sublime Text 2\\Packages\\User"']
    ]


def push_gnome_settings() -> list:
    dconf_settings = parse_jsonnet_now('gnome/dconf_settings.jsonnet', get_ext_vars(config.get_localhost()), output_string=True)
    subprocess.run(['dconf', 'load'], check=True, stdin=dconf_settings.encode('utf-8'))
    return ['dconf settings applied']


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
        hosts = parse_hosts_from_args(host_args)
        if len(hosts) == 0:
            raise ValueError(f'No hosts found in "{host_args}"')

    ops = []
    match option:
        case '--compare-iterm2-prefs':
            ops.append(compare_iterm2_prefs)
        case '--compare-user-settings':
            ops.append(partial(compare_user_settings, host=config.get_localhost()))
        case '--update-workspace-extensions':
            ops.append(update_workspace_extensions)
        case '--generate-workspace':
            ops.append(generate_derived_workspace)
        case '--snapshot-iterm2-prefs':
            ops.append(snapshot_iterm2_prefs_json)
        case '--push-iterm2-prefs':
            ops.append(push_iterm2_prefs)
        case '--push-gnome-settings':
            ops.extend(push_gnome_settings())
        case '--bootstrap-windows':
            ops.extend(bootstrap_windows())
        case '--install-sublime-plugins':
            ops.extend(push_sublimetext_windows_plugins())
        case '--push':
            ops.extend(chain.from_iterable([stage_local(host, shallow, verbose=verbose) for host in hosts]))
            ops.extend(chain.from_iterable([push_remote_staging(host, verbose=verbose) for host in hosts]))
            if any(host.is_localhost() and host.kernel == 'darwin' for host in hosts):
                ops.append(push_iterm2_prefs)
        case '--stage':
            ops.extend(chain.from_iterable([stage_local(host, shallow, verbose=verbose) for host in hosts]))
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

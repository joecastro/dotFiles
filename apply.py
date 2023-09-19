#!/usr/bin/env python3

# pylint: disable=too-many-arguments, missing-module-docstring, missing-function-docstring, line-too-long

import json
import os
from pathlib import Path
import re
import subprocess
import sys

ZSHENV_PREAMBLE = '# === BEGIN_DYNAMIC_SECTION ==='
ZSHENV_CONCLUSION = '# === END_DYNAMIC_SECTION ==='
ZSHENV_SUB = '#<DOTFILES_HOME_SUBST>'

HOME = str(Path.home())
CWD = '.'

# zshenv is handled special after relocation to support dynamic content.
ZSHENV_SRC = 'zsh/zshenv.zsh'
ZSHENV_DEST = '.zshenv'
GITCONFIG_SRC = 'out/gitconfig.ini'


def is_localhost(host):
    return host['hostname'] == os.uname().nodename


def annotate_ops(ops):
    ret = []
    for op_list in ops:
        ret.append(f'local: {" ".join(op_list)}')
        ret.append(op_list)

    return ret

def print_ops(ops):
    for entry in ops:
        if isinstance(entry, str):
            print(entry)
        elif isinstance(entry, list):
            print(f'DEBUG: {" ".join(entry)}')
        elif callable(entry):
            print(f'DEBUG: invoking function {entry}')
        else:
            raise TypeError('Bad operation type')


def run_ops(ops):
    for entry in ops:
        if isinstance(entry, str):
            print(entry)
        elif isinstance(entry, list):
            subprocess.run(entry, check=True)
        elif callable(entry):
            entry()
        else:
            raise TypeError('Bad operation type')


def fixup_source_zshenv():
    with open(ZSHENV_SRC, 'r', encoding='utf-8') as file:
        content = file.read()

    zshenv_re_sub = f'{re.escape(ZSHENV_PREAMBLE)}.*{re.escape(ZSHENV_CONCLUSION)}'
    result = re.search(zshenv_re_sub, content, re.DOTALL)

    # This will be None if pulled from a remote host without content substituted in.
    if result is None:
        return

    content = content.replace(result.group(0), ZSHENV_SUB)

    with open(ZSHENV_SRC, 'w', encoding='utf-8') as file:
        file.write(content)


def expand_zshenv(host, target_file):
    if not host.get('zshenv_sub'):
        return

    zshenv_dynamic_content = ZSHENV_PREAMBLE
    for line in host['zshenv_sub']:
        zshenv_dynamic_content += '\n' + line
    zshenv_dynamic_content += '\n' + ZSHENV_CONCLUSION

    with open(target_file, 'r', encoding='utf-8') as file:
        content = file.read()

    with open(target_file, 'w', encoding='utf-8') as file:
        file.write(content.replace(ZSHENV_SUB, zshenv_dynamic_content))


def process_gitconfig(host):
    with open(GITCONFIG_SRC, encoding='utf-8', mode='w') as out_file:
        subprocess.run(['jsonnet', '-S', '--ext-str', f'hostname="{host["hostname"]}', 'git/gitconfig.jsonnet'], check=True, stdout=out_file)


def install_zsh_plugin_ops(host, zsh_plugin_repos):
    hostname = host['hostname']

    ops = [f'>> Cloning {len(zsh_plugin_repos)} Zsh plugins for {hostname}']
    plugin_root = f'{HOME}/.zshext' if is_localhost(host) else './.zshext'
    ops.append(['rm', '-rf', plugin_root])
    pattern = re.compile("([^/]+)\\.git$")
    for repo in zsh_plugin_repos:
        ops.append(['git', 'clone', repo, f'{plugin_root}/{pattern.search(repo).group(1)}'])

    if is_localhost(host):
        return ops

    return [['ssh', hostname, ' '.join(op)] if isinstance(op, list) else op for op in ops]


def install_vim_plugin_ops(host, vim_pack_plugin_start_repos, vim_pack_plugin_opt_repos):
    hostname = host['hostname']

    ops = [f'>> Cloning {len(vim_pack_plugin_start_repos) + len(vim_pack_plugin_opt_repos)} Vim plugins for {hostname}']
    pack_root = f'{HOME}/.vim/pack' if is_localhost(host) else './.vim/pack'
    ops.append(['rm', '-rf', pack_root])
    pattern = re.compile("([^/]+)\\.git$")
    for (infix, repos) in [('plugins/start', vim_pack_plugin_start_repos),
                           ('plugins/opt', vim_pack_plugin_opt_repos)]:
        ops.extend([['git', 'clone', plugin_repo, f'{pack_root}/{infix}/{pattern.search(plugin_repo).group(1)}']
                    for plugin_repo in repos])

    if is_localhost(host):
        return ops

    return [['ssh', hostname, ' '.join(op)] if isinstance(op, list) else op for op in ops]


def copy_files(source_host, source_root, source_files, dest_host, dest_root, dest_files, annotate=False):
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
        ops.extend([['ssh', dest_host['hostname'], ' '.join(op)] for op in mkdir_ops])
    else:
        ops.extend(mkdir_ops)

    ops.extend([['scp', f'{source_prefix}/{repo_file}', f'{dest_prefix}/{dot_file}']
                 for (repo_file, dot_file) in zip(source_files, dest_files)])

    return ops

def copy_files_local(source_root, source_files, dest_root, dest_files, annotate: bool = False):
    ops = [
        ['mkdir', '-p', dest_root]]

    dest_subfolders = {os.path.dirname(d) for d in dest_files if os.path.dirname(d)}
    ops.extend([['mkdir', '-p', f'{dest_root}/{sub}'] for sub in dest_subfolders])
    copy_ops = []
    for (repo_file, dot_file) in zip(source_files, dest_files):
        copy_ops.append(['cp', f'{source_root}/{repo_file}', f'{dest_root}/{dot_file}'])

    if annotate:
        copy_ops = annotate_ops(copy_ops)

    ops.extend(copy_ops)
    return ops


def push_remote(host, shallow):
    hostname = host['hostname']
    file_maps = dict(host['file_maps'])

    if GITCONFIG_SRC in file_maps.keys():
        process_gitconfig(host)

    staging_dir = f'{CWD}/out/{host["hostname"]}-dot'
    ops = [f'>> Synching dotFiles for {hostname}']
    ops.extend(copy_files_local(CWD, file_maps.keys(), staging_dir, file_maps.keys()))

    # fixup the zshenv to include dynamic content
    ops.append(lambda: expand_zshenv(host, f'{staging_dir}/{ZSHENV_SRC}'))

    ops.append(f'Copying {len(file_maps)} files to {hostname} home directory')
    ops.extend(copy_files(None, staging_dir, file_maps.keys(), host, HOME, file_maps.values(), annotate=True))
    ops.append(['rm', '-rf', staging_dir])

    if not shallow:
        ops.extend(install_vim_plugin_ops(host, config.get('vim_pack_plugin_start_repos'), config.get('vim_pack_plugin_opt_repos')))
        ops.extend(install_zsh_plugin_ops(host, config.get('zsh_plugin_repos')))

    return ops


def pull_remote(host):
    hostname = host['hostname']
    file_maps = dict(host['file_maps'])

    ops = [f'>> Snapshotting dotFiles from {hostname}']
    ops.extend(copy_files(host, HOME, file_maps.values(), None, CWD, file_maps.keys()))

    # fixup the zshenv to exclude the dynamic content
    ops.append(fixup_source_zshenv)

    return ops


def bootstrap_windows():
    ''' Apply environment settings for a new Windows machine. '''
    return [
        ['SETX', 'DOTFILES_SRC_DIR', os.getcwd()]]


def bootstrap_iterm2():
    ''' Associate the plist for iTerm2 with the dotFiles. '''
    return [
        # Specify the preferences directory
        ['defaults', 'write', 'com.googlecode.iterm2', 'PrefsCustomFolder', '-string', f'{os.getcwd()}/iterm2'],
        # Tell iTerm2 to use the custom preferences in the directory
        ['defaults', 'write', 'com.googlecode.iterm2', 'LoadPrefsFromCustomFolder', '-bool', 'true']]


def push_sublimetext_windows_plugins():
    ''' Setup any Sublime Text plugins for Windows. '''
    return [
        ['cp', 'sublime_text\\*', '"%APPDATA%\\Sublime Text 2\\Packages\\User"']
    ]


def main(args):
    ''' Apply dotFiles operations '''
    print_only = False
    if '--dry-run' in args:
        print_only = True
        args.remove('--dry-run')
    shallow = False
    if '--shallow' in args:
        shallow = True
        args.remove('--shallow')

    local_host = next(h for h in config['hosts'] if h['hostname'] == os.uname().nodename)

    ops = []
    match args[0]:
        case '--push':
            if len(args) < 2:
                ops.extend(push_remote(local_host, shallow))
            elif args[1] == '--all':
                for host in config['hosts']:
                    ops.extend(push_remote(host, shallow))
            else:
                host = next(h for h in config['hosts'] if h['hostname'] == args[1])
                ops.extend(push_remote(host, shallow))
        case '--push-local':
            ops.extend(push_remote(local_host, shallow))
        case '--pull':
            if len(args) < 2:
                ops.extend(pull_remote(local_host))
            else:
                host = next(h for h in config['hosts'] if h['hostname'] == args[1])
                ops.extend(pull_remote(host))
        case '--bootstrap-iterm2':
            ops.extend(bootstrap_iterm2())
        case '--bootstrap-windows':
            ops.extend(bootstrap_windows())
        case '--install-sublime-plugins':
            push_sublimetext_windows_plugins()
        case _:
            print('<unknown arg>')
            return 1

    if print_only:
        print_ops(ops)
    else:
        run_ops(ops)
    return 0


def process_jsonnet_configs():
    ''' Process any config files that need to be initialized. '''
    config_file = 'apply_configs.jsonnet'
    if not Path.is_file(Path.joinpath(Path.cwd(), config_file)):
        raise ValueError('Missing config file')

    ext_vars = [
        ('hostname', os.uname().nodename),
        ('cwd', os.getcwd()),
        ('home', HOME)
    ]
    proc_args = ['jsonnet']
    for (key, val) in ext_vars:
        proc_args.extend(['--ext-str', f'{key}={val}'])
    proc_args.append(config_file)
    completed_proc = subprocess.run(proc_args, check=True, capture_output=True)
    return json.loads(completed_proc.stdout)


if __name__ == "__main__":
    try:
        os.mkdir('out')
    except FileExistsError:
        pass

    config = process_jsonnet_configs()

    if len(sys.argv) < 2:
        print('<missing args>')
        sys.exit(1)
    else:
        sys.exit(main(sys.argv[1:]))

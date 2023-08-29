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

LOCAL_DEBUG_PREFIX = 'local: '

HOME = str(Path.home())
CWD = '.'

# zshenv is handled special after relocation to support dynamic content.
ZSHENV_SRC = 'zsh/zshenv.zsh'
ZSHENV_DEST = '.zshenv'

hosts = [
    {
        'hostname': 'localhost',
        'zshenv_sub': [
            "LOCALHOST_PREFERRED_DISPLAY="
                + ("workbook" if os.uname().nodename.startswith('joecastro-macbookpro') else ""),
            f"DOTFILES_SRC_HOME={os.getcwd()}",
            "alias dotGo='pushd $DOTFILES_SRC_HOME'",
            "",
            "ANDROID_REPO_BRANCH=main",
            f"ANDROID_REPO_PATH={HOME}/source/android"
        ],
        'file_maps_exclude': [
            'bash/',
            'konsole/',
            'verify_fonts.py'
        ]
    }
]

local_host = hosts[0]

global_file_maps = [
    ['bash/bashrc.sh', '.bashrc'],
    ['bash/profile.sh', '.profile'],
    ['bash/bash_profile.sh', '.bash_profile'],
    ['zsh/zshrc.zsh', '.zshrc'],
    ['zsh/zprofile.zsh', '.zprofile'],
    [ZSHENV_SRC, ZSHENV_DEST],
    ['zsh/android_funcs.zsh', '.android_funcs.zsh'],
    ['zsh/osx_funcs.zsh', '.osx_funcs.zsh'],
    ['zsh/util_funcs.zsh', '.util_funcs.zsh'],
    ['vim/vimrc.vim', '.vimrc'],
    ['vim/colors/molokai.vim', '.vim/colors/molokai.vim'],
    ['tmux/tmux.conf', '.tmux.conf'],
    ['verify_fonts.py', 'dotScripts/verify_fonts.py']
]

vim_pack_plugin_start_repos = [
    # Syntax highlighting for AOSP specific files
    'https://github.com/rubberduck203/aosp-vim.git',
    # Lean & mean status/tabline for vim that's light as air
    'https://github.com/vim-airline/vim-airline.git',
    # Kotlin plugin for Vim. Featuring: syntax highlighting, basic indentation, Syntastic support
    'https://github.com/udalov/kotlin-vim.git',
    # A tree explorer plugin for vim.
    'https://github.com/preservim/nerdtree.git',
    # A Vim plugin which shows git diff markers in the sign column
    # and stages/previews/undoes hunks and partial hunks.
    'https://github.com/airblade/vim-gitgutter.git',
    # 💻 Terminal manager for (neo)vim
    'https://github.com/voldikss/vim-floaterm.git',
    # Check syntax in Vim asynchronously and fix files, with Language Server Protocol (LSP) support
    'https://github.com/dense-analysis/ale.git'
]

vim_pack_plugin_opt_repos = [
    # A dark Vim/Neovim color scheme inspired by Atom's One Dark syntax theme.
    'https://github.com/joshdick/onedark.vim.git'
]

zsh_plugin_repos = [
    # Fish shell like syntax highlighting for Zsh.
    'https://github.com/zsh-users/zsh-syntax-highlighting.git'
]

iterm_substitutions = []

SYS_COMMAND_PREFIX = 'sys_command: '


def make_sys_op(command):
    return SYS_COMMAND_PREFIX + command


def print_ops(ops):
    for entry in ops:
        if isinstance(entry, str):
            if entry.startswith(SYS_COMMAND_PREFIX):
                print(f'DEBUG SYSCALL: {entry}')
            else:
                print(f'>> {entry}')
        elif isinstance(entry, list):
            print(f'DEBUG: {" ".join(entry)}')
        elif callable(entry):
            print(f'DEBUG: invoking function {entry}')
        else:
            raise TypeError('Bad operation type')


def run_ops(ops):
    for entry in ops:
        if isinstance(entry, str):
            if entry.startswith(SYS_COMMAND_PREFIX):
                os.system(entry.removeprefix(SYS_COMMAND_PREFIX))
            else:
                if not entry.startswith('local'):
                    entry = '>> ' + entry
                print(entry)
        elif isinstance(entry, list):
            subprocess.run(entry, check=False)
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


def install_zsh_plugin_ops(host):
    hostname = host['hostname']

    ops = [f'Cloning {len(zsh_plugin_repos)} Zsh plugins for {hostname}']
    plugin_root = f'{HOME}/.zshext' if host == local_host else './.zshext'
    ops.append(['rm', '-rf', plugin_root])
    pattern = re.compile("([^/]+)\\.git$")
    for repo in zsh_plugin_repos:
        ops.append(['git', 'clone', repo, f'{plugin_root}/{pattern.search(repo).group(1)}'])

    if host == local_host:
        return ops

    return [['ssh', hostname, ' '.join(op)] if isinstance(op, list) else op for op in ops]


def install_vim_plugin_ops(host):
    hostname = host['hostname']

    ops = [f'Cloning {len(vim_pack_plugin_start_repos) + len(vim_pack_plugin_opt_repos)} Vim plugins for {hostname}']
    pack_root = f'{HOME}/.vim/pack' if host == local_host else './.vim/pack'
    ops.append(['rm', '-rf', pack_root])
    pattern = re.compile("([^/]+)\\.git$")
    for (infix, repos) in [('plugins/start', vim_pack_plugin_start_repos),
                           ('plugins/opt', vim_pack_plugin_opt_repos)]:
        ops.extend([['git', 'clone', plugin_repo, f'{pack_root}/{infix}/{pattern.search(plugin_repo).group(1)}']
                    for plugin_repo in repos])

    if host == local_host:
        return ops

    return [['ssh', hostname, ' '.join(op)] if isinstance(op, list) else op for op in ops]


def copy_files(source_host, source_root, source_files, dest_host, dest_root, dest_files, annotate=False):
    if dest_host != local_host and dest_root == HOME:
        dest_root = CWD
    if source_host != local_host and source_root == HOME:
        source_root = CWD

    is_remote_target = dest_host != local_host

    if not is_remote_target and source_host == local_host:
        return copy_files_local(source_root, source_files, dest_root, dest_files, annotate)

    if source_host == local_host:
        source_prefix = source_root
    else:
        source_prefix = source_host['hostname'] + ':' + source_root

    if not is_remote_target:
        dest_prefix = dest_root
    else:
        dest_prefix = dest_host['hostname'] + ':' + dest_root

    ops = []

    dest_subfolders = set([os.path.dirname(d) for d in dest_files if os.path.dirname(d)])
    mkdir_ops = [['mkdir', '-p', f'{dest_root}/{sub}'] for sub in dest_subfolders]
    if is_remote_target:
        ops.extend([['ssh', dest_host['hostname'], ' '.join(op)] for op in mkdir_ops])
    else:
        ops.extend(mkdir_ops)

    ops.extend([['scp', f'{source_prefix}/{repo_file}', f'{dest_prefix}/{dot_file}']
                 for (repo_file, dot_file) in zip(source_files, dest_files)])

    return ops

def copy_files_local(source_root, source_files, dest_root, dest_files, annotate: bool = False):
    ops = []
    ops.append(['mkdir', '-p', dest_root])

    dest_subfolders = set([os.path.dirname(d) for d in dest_files if os.path.dirname(d)])
    ops.extend([['mkdir', '-p', f'{dest_root}/{sub}'] for sub in dest_subfolders])
    for (repo_file, dot_file) in zip(source_files, dest_files):
        copy_op = ['cp', f'{source_root}/{repo_file}', f'{dest_root}/{dot_file}']
        if annotate:
            ops.append(LOCAL_DEBUG_PREFIX + ' '.join(copy_op))
        ops.append(copy_op)

    return ops


def push_remote(host, shallow):
    if isinstance(host, str):
        host = [h for h in hosts if h['hostname'] == host][0]

    hostname = host['hostname']
    file_maps = host['file_maps']

    staging_dir = f'{CWD}/out/{host["hostname"]}-dot'
    ops = [f'Synching dotFiles for {hostname}']
    ops.extend(copy_files_local(CWD, file_maps.keys(), staging_dir, file_maps.keys()))

    # fixup the zshenv to include dynamic content
    ops.append(lambda: expand_zshenv(host, f'{staging_dir}/{ZSHENV_SRC}'))

    ops.append(f'Copying {len(file_maps)} files to {hostname} home directory')
    ops.extend(copy_files(local_host, staging_dir, file_maps.keys(), host, HOME, file_maps.values(), annotate=True))
    ops.append(['rm', '-rf', staging_dir])

    if not shallow:
        ops.extend(install_vim_plugin_ops(host))
        ops.extend(install_zsh_plugin_ops(host))

    return ops


def pull_remote(host):
    hostname = host['hostname']
    file_maps = host['file_maps']

    ops = [f'Snapshotting dotFiles from {hostname}']
    ops.extend(copy_files(host, HOME, file_maps.values(), local_host, CWD, file_maps.keys()))

    # fixup the zshenv to exclude the dynamic content
    ops.append(fixup_source_zshenv)

    return ops


def bootstrap_windows():
    ''' Apply environment settings for a new Windows machine. '''
    return [
        make_sys_op(f'SETX DOTFILES_SRC_DIR {os.getcwd()}')]


def bootstrap_iterm2():
    ''' Associate the plist for iTerm2 with the dotFiles. '''
    return [
        # Specify the preferences directory
        make_sys_op('defaults write com.googlecode.iterm2 PrefsCustomFolder - string "$PWD/iterm2"'),
        # Tell iTerm2 to use the custom preferences in the directory
        make_sys_op('defaults write com.googlecode.iterm2 LoadPrefsFromCustomFolder - bool true')]


def push_sublimetext_windows_plugins():
    ''' Setup any Sublime Text plugins for Windows. '''
    return [
        ['cp', 'sublime_text\\*', '"%APPDATA%\\Sublime Text 2\\Packages\\User"']
    ]


def extend_config(cfg):
    ''' Augment the current configuration with external extensions. '''
    extended_file_maps = cfg.get('file_maps')
    if extended_file_maps is not None:
        global_file_maps.extend(extended_file_maps)

    extended_hosts = cfg.get('hosts')
    if extended_hosts is not None:
        hosts.extend(extended_hosts)

    extended_vim_start_plugins = cfg.get('vim_plugin_start_repos')
    if extended_vim_start_plugins is not None:
        vim_pack_plugin_start_repos.extend(extended_vim_start_plugins)

    extended_vim_opt_plugins = cfg.get('vim_plugin_opt_repos')
    if extended_vim_opt_plugins is not None:
        vim_pack_plugin_opt_repos.extend(extended_vim_opt_plugins)


def finalize_config(host):
    ''' Fixup the file_maps based on host overrides '''

    # Convert from a list to a dictionary. It's easier to not compute key names in jsonnet.
    new_file_maps = dict(host.get('file_maps', [])) | dict(global_file_maps)
    new_file_maps = {k: v for (k, v) in new_file_maps.items()
                     if not any(k.startswith(p) for p in host.get('file_maps_exclude', []))}

    host['file_maps'] = new_file_maps


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

    ops = []
    match args[0]:
        case '--push':
            if len(args) < 2:
                ops.extend(push_remote(local_host, shallow))
            elif args[1] == '--all':
                for host in hosts:
                    ops.extend(push_remote(host, shallow))
            else:
                ops.extend(push_remote(args[1], shallow))
        case '--push-local':
            ops.extend(push_remote(local_host, shallow))
        case '--pull':
            if len(args) < 2:
                ops.extend(pull_remote(local_host))
            else:
                ops.extend(pull_remote(args[1]))
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
    try:
        os.remove('out/apply_configs.json')
    except FileNotFoundError:
        pass

    if Path.is_file(Path.joinpath(Path.cwd(), 'apply_configs.jsonnet')):
        with open('out/apply_configs.json', encoding='utf-8', mode='w') as processed_config:
            subprocess.run(['jsonnet', 'apply_configs.jsonnet'], check=True, stdout=processed_config)


if __name__ == "__main__":
    try:
        os.mkdir('out')
    except FileExistsError:
        pass

    process_jsonnet_configs()

    try:
        with open('out/apply_configs.json', encoding='utf-8') as config:
            print('>> Including additional configurations')
            extend_config(json.load(config))
    except FileNotFoundError:
        pass

    for h in hosts:
        finalize_config(h)

    if len(sys.argv) < 2:
        print('<missing args>')
        sys.exit(1)
    else:
        sys.exit(main(sys.argv[1:]))

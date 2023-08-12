#!/usr/bin/env python3

import json
import os
from pathlib import Path
import re
import subprocess
import sys

ZPROF_PREAMBLE = '# === BEGIN_DYNAMIC_SECTION ==='
ZPROF_CONCLUSION = '# === END_DYNAMIC_SECTION ==='
ZPROF_SUB = '#<DOTFILES_HOME_SUBST>'

HOME = str(Path.home())
CWD = '.'

# zprofile is handled special after relocation to support dynamic content.
ZPROFILE_SRC = 'zsh/zprofile.zsh'
ZPROFILE_DEST = '.zprofile'

file_maps = [
    ('bash/bashrc.sh', '.bashrc'),
    ('bash/profile.sh', '.profile'),
    ('bash/bash_profile.sh', '.bash_profile'),
    ('zsh/zshrc.zsh', '.zshrc'),
    (ZPROFILE_SRC, ZPROFILE_DEST),
    ('zsh/android_funcs.zsh', '.android_funcs.zsh'),
    ('zsh/osx_funcs.zsh', '.osx_funcs.zsh'),
    ('zsh/util_funcs.zsh', '.util_funcs.zsh'),
    ('vim/vimrc.vim', '.vimrc'),
    ('vim/colors/molokai.vim', '.vim/colors/molokai.vim'),
    ('tmux/tmux.conf', '.tmux.conf')
]

vim_pack_plugin_repos = [
    # Syntax highlighting for AOSP specific files
    'https://github.com/rubberduck203/aosp-vim.git',
    # Lean & mean status/tabline for vim that's light as air
    'https://github.com/vim-airline/vim-airline.git',
    # Kotlin plugin for Vim. Featuring: syntax highlighting, basic indentation, Syntastic support
    'https://github.com/udalov/kotlin-vim.git',
    # A tree explorer plugin for vim.
    'https://github.com/preservim/nerdtree.git',
    # A Vim plugin which shows git diff markers in the sign column and stages/previews/undoes hunks and partial hunks.
    'https://github.com/airblade/vim-gitgutter.git',
    # 💻 Terminal manager for (neo)vim
    'https://github.com/voldikss/vim-floaterm.git',
    # Check syntax in Vim asynchronously and fix files, with Language Server Protocol (LSP) support
    'https://github.com/dense-analysis/ale.git'
]


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
                print(f'>> {entry}')
        elif isinstance(entry, list):
            subprocess.run(entry, check=False)
        elif callable(entry):
            entry()
        else:
            raise TypeError('Bad operation type')

def fixup_source_zprofile():
    with open(ZPROFILE_SRC, 'r', encoding='utf-8') as file:
        content = file.read()

    result = re.search(f'{re.escape(ZPROF_PREAMBLE)}.*{re.escape(ZPROF_CONCLUSION)}', content, re.DOTALL)

    # This will be None if pulled from a remote host without content substituted in.
    if result is None:
        return

    content = content.replace(result.group(0), ZPROF_SUB)

    with open(ZPROFILE_SRC, 'w', encoding='utf-8') as file:
        file.write(content)


def expand_local_zprofile():
    zprof_dynamic_content = f'''{ZPROF_PREAMBLE}
DOTFILES_SRC_HOME={os.getcwd()}
alias dotGo='pushd $DOTFILES_SRC_HOME'
{ZPROF_CONCLUSION}'''

    with open(f'{HOME}/{ZPROFILE_DEST}', 'r', encoding='utf-8') as file:
        content = file.read()

    with open(f'{HOME}/{ZPROFILE_DEST}', 'w', encoding='utf-8') as file:
        file.write(content.replace(ZPROF_SUB, zprof_dynamic_content))


def install_vim_plugin_ops(host):
    ops = [f'Cloning {len(vim_pack_plugin_repos)} Vim plugins for {host if host else "localhost"}']
    pack_root = f'{HOME}/.vim/pack' if not host else './.vim/pack'
    ops.append(['rm', '-rf', pack_root])
    pattern = re.compile("([^/]+)\\.git$")
    ops.extend([['git', 'clone', '--quiet', plugin_repo, f'{pack_root}/plugins/start/{pattern.search(plugin_repo).group(1)}']
                for plugin_repo in vim_pack_plugin_repos])

    return ops if not host else [['ssh', host, ' '.join(op)] if isinstance(op, list) else op for op in ops]


def push_local():
    ops = ['Synching dotFiles for localhost']
    ops.extend([['mkdir', '-p', f'{HOME}/{os.path.dirname(d[1])}'] for d in file_maps if os.path.dirname(d[1])])
    ops.append(f'Copying {len(file_maps)} files to local home directory')
    ops.extend([['cp', f'{CWD}/{repo_file}', f'{HOME}/{dot_file}'] for (repo_file, dot_file) in file_maps])

    # fixup the zprofile to include dynamic content
    ops.append(expand_local_zprofile)

    ops.extend(install_vim_plugin_ops(None))

    return ops


def push_remote(host):
    ops = [f'Synching dotFiles for {host}']
    ops.extend([['ssh', host, f'mkdir -p ./{os.path.dirname(d[1])}'] for d in file_maps if os.path.dirname(d[1])])
    ops.append(f'Copying {len(file_maps)} files to local home directory')
    ops.extend([['scp', f'{CWD}/{repo_file}', f'{host}:{dot_file}'] for (repo_file, dot_file) in file_maps])
    # Skip any modifications to a remote zprofile.

    ops.extend(install_vim_plugin_ops(host))

    return ops


def pull_local():
    ops = ['Snapshotting dotFiles from localhost']
    for (repo_file, dot_file) in file_maps:
        ops.append(['cp', f'{HOME}/{dot_file}', f'{CWD}/{repo_file}'])
    # fixup the zprofile to include dynamic content
    ops.append(fixup_source_zprofile)

    return ops


def pull_remote(host):
    ops = [f'Snapshotting dotFiles from {host}']
    ops.extend([['scp', f'{host}:{dot_file}', f'{CWD}/{repo_file}'] for (repo_file, dot_file) in file_maps])

    # fixup the zprofile to include dynamic content
    ops.append(fixup_source_zprofile)

    return ops


def bootstrap_windows():
    return [
        make_sys_op(f'SETX DOTFILES_SRC_DIR {os.getcwd()}')]


def bootstrap_iterm2():
    return [
        # Specify the preferences directory
        make_sys_op('defaults write com.googlecode.iterm2 PrefsCustomFolder - string "$PWD/iterm2"'),
        # Tell iTerm2 to use the custom preferences in the directory
        make_sys_op('defaults write com.googlecode.iterm2 LoadPrefsFromCustomFolder - bool true')]


def generate_iterm2_profiles():
    with open('iterm2/profile_template.json', encoding='utf-8') as t_file:
        template_data = json.load(t_file)

    with open('iterm2/profile_substitutions.json', encoding='utf-8') as s_file:
        sub_data = json.load(s_file)

    try:
        with open('iterm2/profile_substitutions_ex.json', encoding='utf-8') as s_ex_file:
            sub_data.extend(json.load(s_ex_file))
    except FileNotFoundError:
        pass

    if not os.path.exists('out'):
        os.mkdir('out')

    for sub in sub_data:
        profile_name = sub['Name']
        bg_location = Path(sub['Background Image Location']).absolute()
        profile = template_data | sub
        profile['Background Image Location'] = str(bg_location)

        with open(f'out/{profile_name}.json', 'w', encoding='utf-8') as outfile:
            json.dump(profile, outfile, indent=2, sort_keys=True)

    t_file.close()
    s_file.close()


def push_sublimetext_windows_plugins():
    return [
        ['cp', 'sublime_text\\*', '"%APPDATA%\\Sublime Text 2\\Packages\\User"']
    ]


def main(args):
    ops = []
    if args[0] == '--push':
        if len(args) < 2:
            ops.extend(push_local())
        elif args[1] == '--all':
            ops.extend(push_local())
            with open('hosts.json', encoding='utf-8') as hosts_file:
               for host in json.load(hosts_file):
                   ops.extend(push_remote(host))
        else:
            ops.extend(push_remote(args[1]))
    elif args[0] == '--push-local':
        ops.extend(push_local())
    elif args[0] == '--pull':
        if len(args) < 2:
            ops.extend(pull_local())
        else:
            ops.extend(pull_remote(args[1]))
    elif args[0] == '--bootstrap-iterm2':
        ops.extend(bootstrap_iterm2())
    elif args[0] == '--bootstrap-windows':
        ops.extend(bootstrap_windows())
    elif args[0] == '--generate-iterm2-profiles':
        generate_iterm2_profiles()
    elif args[0] == '--install-sublime-plugins':
        push_sublimetext_windows_plugins()
    else:
        print('<unknown arg>')
        return 1

    # print_ops(ops)
    run_ops(ops)
    return 0


if __name__ == "__main__":
    try:
        with open('file_maps_ex.json', encoding='utf-8') as file_maps_ex_file:
            print('>> Including additional file maps')
            file_maps.extend([(src, dest) for (src, dest) in json.load(file_maps_ex_file).items()])
    except FileNotFoundError:
        pass

    if len(sys.argv) < 2:
        print('<missing args>')
        sys.exit(1)
    else:
        sys.exit(main(sys.argv[1:]))

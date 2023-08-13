#!/usr/bin/env python3

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

hosts = {
    'localhost': {
        'zshenv_sub': [
            f"DOTFILES_SRC_HOME={os.getcwd()}",
            "alias dotGo='pushd $DOTFILES_SRC_HOME'"
        ],
        'exclude_paths': [
            'bash/'
        ]
    }
}

file_maps = [
    ('bash/bashrc.sh', '.bashrc'),
    ('bash/profile.sh', '.profile'),
    ('bash/bash_profile.sh', '.bash_profile'),
    ('zsh/zshrc.zsh', '.zshrc'),
    ('zsh/zprofile.zsh', '.zprofile'),
    (ZSHENV_SRC, ZSHENV_DEST),
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
    'https://github.com/dense-analysis/ale.git',
    # A dark Vim/Neovim color scheme inspired by Atom's One Dark syntax theme.
    'https://github.com/joshdick/onedark.vim.git'
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
                print(f'>> {entry}')
        elif isinstance(entry, list):
            subprocess.run(entry, check=False)
        elif callable(entry):
            entry()
        else:
            raise TypeError('Bad operation type')

def fixup_source_zshenv():
    with open(ZSHENV_SRC, 'r', encoding='utf-8') as file:
        content = file.read()

    result = re.search(f'{re.escape(ZSHENV_PREAMBLE)}.*{re.escape(ZSHENV_CONCLUSION)}', content, re.DOTALL)

    # This will be None if pulled from a remote host without content substituted in.
    if result is None:
        return

    content = content.replace(result.group(0), ZSHENV_SUB)

    with open(ZSHENV_SRC, 'w', encoding='utf-8') as file:
        file.write(content)


def expand_zshenv(host, target_file):
    host_config = hosts.get(host)
    if not host_config or not host_config.get('zshenv_sub'):
        return

    zshenv_dynamic_content = ZSHENV_PREAMBLE
    for line in host_config['zshenv_sub']:
        zshenv_dynamic_content += '\n' + line
    zshenv_dynamic_content += '\n' + ZSHENV_CONCLUSION

    with open(target_file, 'r', encoding='utf-8') as file:
        content = file.read()

    with open(target_file, 'w', encoding='utf-8') as file:
        file.write(content.replace(ZSHENV_SUB, zshenv_dynamic_content))


def install_vim_plugin_ops(host):
    ops = [f'Cloning {len(vim_pack_plugin_repos)} Vim plugins for {host}']
    pack_root = f'{HOME}/.vim/pack' if host == 'localhost' else './.vim/pack'
    ops.append(['rm', '-rf', pack_root])
    pattern = re.compile("([^/]+)\\.git$")
    ops.extend([['git', 'clone', '--quiet', plugin_repo, f'{pack_root}/plugins/start/{pattern.search(plugin_repo).group(1)}']
                for plugin_repo in vim_pack_plugin_repos])

    if host == 'localhost':
        return ops

    return [['ssh', host, ' '.join(op)] if isinstance(op, list) else op for op in ops]


def copy_files_local(source_root, source_files, dest_root, dest_files):
    ops = []
    ops.append(['mkdir', '-p', dest_root])

    dest_subfolders = set([os.path.dirname(d) for d in dest_files if os.path.dirname(d)])
    ops.extend([['mkdir', '-p', f'{dest_root}/{sub}'] for sub in dest_subfolders])
    ops.extend([['cp', f'{source_root}/{repo_file}', f'{dest_root}/{dot_file}'] for (repo_file, dot_file) in zip(source_files, dest_files)])

    return ops

def push_local():
    staging_dir = 'out/localhost-dot'
    ops = ['Synching dotFiles for localhost']

    ops.extend(copy_files_local(CWD, [k for (k, _) in file_maps], staging_dir, [k for (k, _) in file_maps]))

    # fixup the zshenv to include dynamic content
    ops.append(lambda: expand_zshenv('localhost', f'{staging_dir}/{ZSHENV_SRC}'))

    ops.append(f'Copying {len(file_maps)} files to local home directory')
    ops.extend(copy_files_local(staging_dir, [k for (k, _) in file_maps], HOME, [v for (_, v) in file_maps]))
    ops.append(['rm', '-rf', staging_dir])

    ops.extend(install_vim_plugin_ops('localhost'))

    return ops


def push_remote(host):
    staging_dir = f'out/{host}-dot'
    ops = [f'Synching dotFiles for {host}']
    ops.extend(copy_files_local(CWD, [k for (k, _) in file_maps], staging_dir, [k for (k, _) in file_maps]))

    # fixup the zshenv to include dynamic content
    ops.append(lambda: expand_zshenv(host, f'{staging_dir}/{ZSHENV_SRC}'))

    dest_subfolders = set([os.path.dirname(d) for d in [k for (k, _) in file_maps] if os.path.dirname(d)])
    ops.extend([['ssh', host, f'mkdir -p ./{sub}'] for sub in dest_subfolders])

    ops.append(f'Copying {len(file_maps)} files to local home directory')
    ops.extend([['scp', f'{staging_dir}/{repo_file}', f'{host}:{dot_file}'] for (repo_file, dot_file) in file_maps])
    ops.append(['rm', '-rf', staging_dir])
    ops.extend(install_vim_plugin_ops(host))

    return ops


def pull_local():
    ops = ['Snapshotting dotFiles from localhost']
    for (repo_file, dot_file) in file_maps:
        ops.append(['cp', f'{HOME}/{dot_file}', f'{CWD}/{repo_file}'])
    # fixup the zshenv to exclude the dynamic content
    ops.append(fixup_source_zshenv)

    return ops


def pull_remote(host):
    ops = [f'Snapshotting dotFiles from {host}']
    ops.extend([['scp', f'{host}:{dot_file}', f'{CWD}/{repo_file}'] for (repo_file, dot_file) in file_maps])

    # fixup the zshenv to exclude the dynamic content
    ops.append(fixup_source_zshenv)

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
        iterm_substitutions.extend(json.load(s_file))

    if not os.path.exists('out'):
        os.mkdir('out')

    for sub in iterm_substitutions:
        profile_name = sub['Name']
        bg_location = Path(sub['Background Image Location']).absolute()
        profile = template_data | sub
        profile['Background Image Location'] = str(bg_location)

        with open(f'out/{profile_name}.json', 'w', encoding='utf-8') as outfile:
            json.dump(profile, outfile, indent=2, sort_keys=True)


def push_sublimetext_windows_plugins():
    return [
        ['cp', 'sublime_text\\*', '"%APPDATA%\\Sublime Text 2\\Packages\\User"']
    ]


def extend_config(cfg):
    extended_file_maps = cfg.get('file_maps')
    if extended_file_maps is not None:
        file_maps.extend([(src, dest) for (src, dest) in extended_file_maps.items()])

    extended_hosts = cfg.get('hosts')
    if extended_hosts is not None:
        hosts.update(extended_hosts)

    extended_vim_plugins = cfg.get('vim_plugin_repos')
    if extended_vim_plugins is not None:
        vim_pack_plugin_repos.extend(extended_vim_plugins)

    extended_iterm_substitutions = cfg.get('iterm_substitutions')
    if extended_iterm_substitutions is not None:
        iterm_substitutions.extend(extended_iterm_substitutions)


def main(args):
    print_only = False
    if '--dry-run' in args:
        print_only = True
        args.remove('--dry-run')

    ops = []
    if args[0] == '--push':
        if len(args) < 2:
            ops.extend(push_local())
        elif args[1] == '--all':
            ops.extend(push_local())
            for host in [h for h in hosts if h != 'localhost']:
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

    if print_only:
        print_ops(ops)
    else:
        run_ops(ops)
    return 0


if __name__ == "__main__":
    try:
        with open('extended_config.json', encoding='utf-8') as config:
            print('>> Including additional configurations')
            extend_config(json.load(config))
    except FileNotFoundError:
        pass

    if len(sys.argv) < 2:
        print('<missing args>')
        sys.exit(1)
    else:
        sys.exit(main(sys.argv[1:]))

#!/usr/bin/python

import json
import os
from pathlib import Path
import re
import subprocess
import sys

zprof_preamble = '# === BEGIN_DYNAMIC_SECTION ==='
zprof_conclusion = '# === END_DYNAMIC_SECTION ==='
zprof_sub = '#<DOTFILES_HOME_SUBST>'

sys_command_prefix = 'sys_command: '

home = str(Path.home())
cwd = '.'

known_hosts = [
    # 'localhost'
    'joec1.c.googlers.com',
    'joec2.c.googlers.com',
    'joec3.c.googlers.com'
]

# zprofile is handled special after relocation to support dynamic content.
zprofile_src = 'zsh/zprofile'
zprofile_dest = '.zprofile'
# There are extra Vim files that would get picked up by pulling directories recursively. E.g.,
# ./.vim/pack/*
# ./.vim/.netrwhist
file_maps = [
    ('zsh/zshrc', '.zshrc'),
    (zprofile_src, zprofile_dest),
    ('zsh/android_funcs.zsh', '.android_funcs.zsh'),
    ('zsh/goog_funcs.zsh', '.goog_funcs.zsh'),
    ('zsh/util_funcs.zsh', '.util_funcs.zsh'),
    ('vim/vimrc', '.vimrc'),
    ('tmux/tmux.conf', '.tmux.conf')
]

directory_maps = [
    # ('vim/vim', '.vim'),
    ('vim/vim/colors', '.vim/colors')
]

vim_pack_repos = [
    # Syntax highlighting for AOSP specific files
    ('https://github.com/rubberduck203/aosp-vim', 'plugins/start/aosp'),
    # Lean & mean status/tabline for vim that's light as air
    ('https://github.com/vim-airline/vim-airline', 'dist/start/vim-airline'),
    # Kotlin plugin for Vim. Featuring: syntax highlighting, basic indentation, Syntastic support
    ('https://github.com/udalov/kotlin-vim.git', 'plugins/start/kotlin-vim')
]


def fixup_source_zprofile():
    with open('zsh/zprofile', 'r') as file:
        content = file.read()

    result = re.search(f'{re.escape(zprof_preamble)}.*{re.escape(zprof_conclusion)}', content, re.DOTALL)

    # This will be None if pulled from a remote host without content substituted in.
    if result is None:
        return

    content = content.replace(result.group(0), zprof_sub)

    with open('zsh/zprofile', 'w') as file:
        file.write(content)


def expand_local_zprofile():
    zprof_dynamic_content = f'''{zprof_preamble}
DOTFILES_SRC_HOME={os.getcwd()}
alias dotGo='pushd $DOTFILES_SRC_HOME'
{zprof_conclusion}'''

    with open(f'{home}/.zprofile', 'r') as file:
        content = file.read()

    with open(f'{home}/.zprofile', 'w') as file:
        file.write(content.replace(zprof_sub, zprof_dynamic_content))


def push_local():
    ops = ['Synching dotFiles for localhost']
    for (repo_dir, dot_dir) in directory_maps:
        ops.append(['mkdir', '-p', f'{home}/{dot_dir}'])
        ops.append(['cp', '-r', f'{cwd}/{repo_dir}/.', f'{home}/{dot_dir}'])
    for (repo_file, dot_file) in file_maps:
        ops.append(['cp', f'{cwd}/{repo_file}', f'{home}/{dot_file}'])
    # fixup the zprofile to include dynamic content
    ops.append(expand_local_zprofile)

    for (vim_repo, vim_pack_dir) in vim_pack_repos:
        ops.append(['rm', '-rf', f'{home}/.vim/pack/{vim_pack_dir}'])
        ops.append(['git', 'clone', vim_repo, f'{home}/.vim/pack/{vim_pack_dir}'])

    return ops


def push_remote(host):
    ops = [f'Synching dotFiles for {host}']
    for (repo_dir, dot_dir) in directory_maps:
        ops.append(['ssh', host, f'mkdir -p ~/{dot_dir}'])
        ops.append(['scp', '-r', f'{cwd}/{repo_dir}/.', f'{host}:{dot_dir}'])
    for (repo_file, dot_file) in file_maps:
        ops.append(['scp', f'{cwd}/{repo_file}', f'{host}:{dot_file}'])
    # Skip any modifications to a remote zprofile.

    for (vim_repo, vim_pack_dir) in vim_pack_repos:
        ops.append([
            'ssh', host,
            f'rm -rf ./.vim/pack/{vim_pack_dir} && git clone {vim_repo} ./.vim/pack/{vim_pack_dir}'
        ])

    # TODO: Check whether the zshrc is actually different?
    # TODO: Source the file through the outer shell?
    # print('    run `source ~/.zshrc` to pick up any new changes')
    return ops


def pull_local():
    ops = ['Snapshotting dotFiles from localhost']
    for (repo_dir, dot_dir) in directory_maps:
        ops.append(['cp', '-r', f'{home}/{dot_dir}/.', f'{cwd}/{repo_dir}/.'])
    for (repo_file, dot_file) in file_maps:
        ops.append(['cp', f'{home}/{dot_file}', f'{cwd}/{repo_file}'])
    # fixup the zprofile to include dynamic content
    ops.append(fixup_source_zprofile)

    return ops


def pull_remote(host):
    ops = [f'Snapshotting dotFiles from {host}']
    for (repo_dir, dot_dir) in directory_maps:
        ops.append(['scp', '-r', f'{host}:{dot_dir}/.', f'{cwd}/{repo_dir}/.'])
    for (repo_file, dot_file) in file_maps:
        ops.append(['scp', f'{host}:{dot_file}', f'{cwd}/{repo_file}'])
    # fixup the zprofile to include dynamic content
    ops.append(fixup_source_zprofile)

    return ops

def bootstrap_windows():
    return[sys_command_prefix + f'''SETX DOTFILES_SRC_DIR {os.getcwd()}''']

def bootstrap_iterm2():
    # Specify the preferences directory
    return [
        sys_command_prefix + 'defaults write com.googlecode.iterm2 PrefsCustomFolder - string "$PWD/iterm2"',
        # Tell iTerm2 to use the custom preferences in the directory
        sys_command_prefix + 'defaults write com.googlecode.iterm2 LoadPrefsFromCustomFolder - bool true']


def generate_iterm2_profiles():
    with open('iterm2/profile_template.json') as t_file:
        template_data = json.load(t_file)

    with open('iterm2/profile_substitutions.json') as s_file:
        sub_data = json.load(s_file)

    for sub in sub_data:
        profile_name = sub['Name']
        bg_location = Path(sub['Background Image Location']).absolute()
        profile = template_data | sub
        profile['Background Image Location'] = str(bg_location)

        with open("iterm2/" + profile_name + ".json", 'w') as outfile:
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
            for host in known_hosts:
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

    for entry in ops:
        if isinstance(entry, str):
            if entry.startswith(sys_command_prefix):
                print("DEBUG SYSCALL:" + entry)
                os.system(entry.removeprefix(sys_command_prefix))
            else:
                print(f'>> {entry}')
        elif isinstance(entry, list):
            # print("DEBUG: " + " ".join(entry))
            subprocess.run(entry)
        elif callable(entry):
            # print("DEBUG: invoking function")
            entry()
        else:
            raise 'bad'
    return 0


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print('<missing args>')
        sys.exit(1)
    else:
        sys.exit(main(sys.argv[1:]))

#!/usr/bin/python

import os
from pathlib import Path
import subprocess
import sys

home = str(Path.home())
cwd = '.'

# There are extra Vim files that would get picked up by pulling directories recursively. E.g.,
# ./.vim/pack/*
# ./.vim/.netrwhist

file_maps = [
    ('zsh/zshrc', '.zshrc'),
    ('vim/vimrc', '.vimrc'),
    ('tmux/tmux.conf', '.tmux.conf')
]

directory_maps = [
    # ('vim/vim', '.vim'),
    ('vim/vim/colors', '.vim/colors')
]

def push_local():
    ops = ['Synching dotFiles for localhost']
    for (repo_dir, dot_dir) in directory_maps:
        ops.append(['mkdir', '-p', f'{home}/{dot_dir}'])
        ops.append(['cp', '-r', f'{cwd}/{repo_dir}/.', f'{home}/{dot_dir}'])
    for (repo_file, dot_file) in file_maps:
        ops.append(['cp', f'{cwd}/{repo_file}', f'{home}/{dot_file}'])

    ops.append(['rm', '-rf', f'{home}/.vim/pack/dist/start/vim-airline'])
    ops.append(
        [
            'git', 'clone',
            'https://github.com/vim-airline/vim-airline',
            f'{home}/.vim/pack/dist/start/vim-airline'
        ])

    return ops

def push_remote(host):
    ops = [f'Synching dotFiles for {host}']
    for (repo_dir, dot_dir) in directory_maps:
        ops.append(['ssh', host, f'mkdir -p ~/{dot_dir}'])
        ops.append(['scp', '-r', f'{cwd}/{repo_dir}/.', f'{host}:{dot_dir}'])
    for (repo_file, dot_file) in file_maps:
        ops.append(['scp', f'{cwd}/{repo_file}', f'{host}:{dot_file}'])

    ops.append([
        'ssh', host,
        'rm -rf ./.vim/pack/dist/start/vim-airline && ' +
        'git clone https://github.com/vim-airline/vim-airline ./.vim/pack/dist/start/vim-airline'
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

    return ops


def pull_remote(host):
    ops = [f'Snapshotting dotFiles from {host}']
    for (repo_dir, dot_dir) in directory_maps:
        ops.append(['scp', '-r', f'{host}:{dot_dir}/.', f'{cwd}/{repo_dir}/.'])
    for (repo_file, dot_file) in file_maps:
        ops.append(['scp', f'{host}:{dot_file}', f'{cwd}/{repo_file}'])

    return ops

def bootstrap_iterm2():
    # Specify the preferences directory
    os.system('defaults write com.googlecode.iterm2 PrefsCustomFolder - string "$PWD/iterm2"')

    # Tell iTerm2 to use the custom preferences in the directory
    os.system('defaults write com.googlecode.iterm2 LoadPrefsFromCustomFolder - bool true')

    return []

known_hosts = [
    # 'localhost'
    'joec1.c.googlers.com',
    'joec2.c.googlers.com',
    'joec3.c.googlers.com'
]

def main(args):
    ops = []
    if args[0] == '--push':
        ops.extend(push_local())
        for host in known_hosts:
            ops.extend(push_remote(host))
    if args[0] == '--push-local':
        ops.extend(push_local())
    elif args[0] == '--pull':
        if len(args) < 2:
            ops.extend(pull_local())
        else:
            ops.extend(pull_remote(args[1]))
    elif args[0] == '--push-local':
        ops.extend(push_local())
    elif args[0] == '--bootstrap-iterm2':
        ops.extend(bootstrap_iterm2())
    else:
        print('<unknown arg>')

    for entry in ops:
        if isinstance(entry, str):
            print(entry)
        else:
            # print("DEBUG": " + " ".join(entry))
            subprocess.run(entry)

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print('<missing args>')
    else:
        main(sys.argv[1:])

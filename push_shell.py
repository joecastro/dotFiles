#!/usr/bin/python3

import subprocess
from pathlib import Path

def push_local():
    print('Synching dotFiles for localhost')
    subprocess.run(['mkdir', '-p', str(Path.home()) + '/.vim/colors'])
    subprocess.run(['cp', './zsh/zshrc', str(Path.home()) + '/.zshrc'])
    subprocess.run(['cp', './vim/vimrc', str(Path.home()) + '/.vimrc'])
    subprocess.run(['cp', '-r', './vim/vim/.', str(Path.home()) + '/.vim'])
    subprocess.run(['cp', './tmux/tmux.conf', str(Path.home()) + '/.tmux.conf'])

def push_remote(host):
    print('Synching dotFiles for ' + host)
    subprocess.run(['ssh', host, 'mkdir -p ~/.vim/colors'])
    subprocess.run(['scp', './zsh/zshrc', host + ':./.zshrc'])
    subprocess.run(['scp', './vim/vimrc', host + ':./.vimrc'])
    subprocess.run(['scp', '-r', './vim/vim/.', host + ':./.vim'])
    subprocess.run(['scp', './tmux/tmux.conf', host + ':./.tmux.conf'])

    # TODO: Check whether the zshrc is actually different?
    # TODO: Source the file through the outer shell?
    # print('    run `source ~/.zshrc` to pick up any new changes')


known_hosts = [
    # 'localhost'
    'joec1.c.googlers.com',
    'joec2.c.googlers.com',
    'joec3.c.googlers.com'
]

if __name__ == "__main__":
    push_local()
    for host in known_hosts:
        push_remote(host)

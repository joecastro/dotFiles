#!/bin/zsh

SYNC_HOST=some.host.name
ROOT=~/github/dotFiles

ssh $SYNC_HOST "mkdir -p ~/.vim/colors"

scp $ROOT/zsh/zshrc $SYNC_HOST:./.zshrc
scp $ROOT/vim/vimrc $SYNC_HOST:./.vimrc
scp -r $ROOT/vim/vim/. $SYNC_HOST:./.vim
scp $ROOT/tmux/tmux.conf $SYNC_HOST:./.tmux.conf

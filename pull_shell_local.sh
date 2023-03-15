#!/bin/zsh

ROOT_DIR=${0:a:h}

cp ~/.zshrc $ROOT_DIR/zsh/zshrc
cp ~.vimrc $ROOT_DIR/vim/vimrc
cp -r ~/.vim/. $ROOT_DIR/vim/vim

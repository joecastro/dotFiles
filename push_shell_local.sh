#!/bin/zsh

ROOT_DIR=${0:a:h}

mkdir -p ~/.vim
mkdir -p ~/.vim/colors

cp $ROOT_DIR/zsh/zshrc ~/.zshrc
cp $ROOT_DIR/vim/vimrc ~/.vimrc
cp -r $ROOT_DIR/vim/vim/. ~/.vim

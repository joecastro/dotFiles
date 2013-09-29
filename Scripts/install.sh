#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )"

ln -sf $DIR/vimrc ~/.vimrc
ln -sf $DIR/vim ~/.vim
ln -sf $DIR/profile ~/.profile
ln -sf $DIR/bash_profile ~/.bash_profile
ln -sf $DIR/bashrc ~/.bashrc

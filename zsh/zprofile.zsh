#!/bin/zsh

#pragma once
PRAGMA_FILE_NAME="PRAGMA_${"${(%):-%1N}"//\./_}"
[ -n "${(P)PRAGMA_FILE_NAME}" ] && unset PRAGMA_FILE_NAME && return;
declare $PRAGMA_FILE_NAME=0
unset PRAGMA_FILE_NAME

if [ -d "$HOME/.rbenv/bin" ]; then
    export PATH="$HOME/.rbenv/bin:$PATH"
    eval "$(rbenv init -)"
fi

if [ -d "/opt/homebrew/bin" ]; then
    # Set PATH, MANPATH, etc., for Homebrew.
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

#<DOTFILES_HOME_SUBST>

#! /bin/bash

#pragma once-bash

source ~/.env_vars.sh

if [ -d "/opt/homebrew/bin" ]; then
    # Set PATH, MANPATH, etc., for Homebrew.
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

export BASH_SILENCE_DEPRECATION_WARNING=1

# source ${DOTFILES_CONFIG_ROOT}/android_funcs.sh # Android shell utility functions
# source ${DOTFILES_CONFIG_ROOT}/util_funcs.sh

if [ -n "$BASH_VERSION" ]; then
    if [ -f ~/.bashrc ]; then
        source ~/.bashrc
    fi
fi

#! /bin/bash

#pragma once

# shellcheck source=/dev/null
source ~/.env_vars.sh

export BASH_SILENCE_DEPRECATION_WARNING=1
export EXPECT_NERD_FONTS="${EXPECT_NERD_FONTS:-0}"
export EDITOR=vim

if [ -d "/opt/homebrew/bin" ]; then
    # Set PATH, MANPATH, etc., for Homebrew.
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

source "${DOTFILES_CONFIG_ROOT}/android_funcs.sh" # Android shell utility functions
source "${DOTFILES_CONFIG_ROOT}/util_funcs.sh"
source "${DOTFILES_CONFIG_ROOT}/env_funcs.sh"

if [ -n "${BASH_VERSION}" ]; then
    test -e ~/.bashrc && source ~/.bashrc
fi

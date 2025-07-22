#! /bin/bash

#pragma once

#pragma validate-dotfiles

# shellcheck source=/dev/null
source ~/.env_vars.sh

export BASH_SILENCE_DEPRECATION_WARNING=1

# Set PATH, MANPATH, etc., for Homebrew.
test -d "/opt/homebrew/bin" && eval "$(/opt/homebrew/bin/brew shellenv)"
test -e ~/.cargo/env && source ~/.cargo/env

source "${DOTFILES_CONFIG_ROOT}/env_funcs.sh"
test -e "${DOTFILES_CONFIG_ROOT}/google_funcs.sh" && source "${DOTFILES_CONFIG_ROOT}/google_funcs.sh"
source "${DOTFILES_CONFIG_ROOT}/osx_funcs.sh"
source "${DOTFILES_CONFIG_ROOT}/android_funcs.sh" # Android shell utility functions
source "${DOTFILES_CONFIG_ROOT}/util_funcs.sh"

if __is_shell_bash; then
    test -e ~/.bashrc && source ~/.bashrc
fi

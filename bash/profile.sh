#! /bin/bash

#pragma once

#pragma validate-dotfiles

export BASH_SILENCE_DEPRECATION_WARNING=1

# Set PATH, MANPATH, etc., for Homebrew.
test -d "/opt/homebrew/bin" && eval "$(/opt/homebrew/bin/brew shellenv)"
test -e ~/.cargo/env && source ~/.cargo/env

#pragma requires env_funcs.sh
#pragma requires macos_funcs.sh
#pragma requires android_funcs.sh
#pragma requires util_funcs.sh

if __is_shell_bash; then
    test -e ~/.bashrc && source ~/.bashrc
fi

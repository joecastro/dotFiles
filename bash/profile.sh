#! /bin/bash

#pragma once

#pragma validate-dotfiles

export BASH_SILENCE_DEPRECATION_WARNING=1

# Ensure homebrew is available to login/non-interactive shells through PATH
if command -v brew >/dev/null 2>&1; then
    eval "$(brew shellenv)"
elif [[ -x "/opt/homebrew/bin/brew" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x "/usr/local/bin/brew" ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
fi

# Note: This also gets loaded by Ghostty and iTerm2. There isn't a way
# to ensure that the version aligns with what's loaded by the terminal.
# Right now everything is in sync at version 0.6.
#pragma requires bash/bash-preexec.sh

#pragma requires platform.sh
#pragma requires env_funcs.sh
#pragma requires macos_funcs.sh
#pragma requires android_funcs.sh
#pragma requires util_funcs.sh

if __is_shell_bash; then
    #shellcheck source=./bashrc.sh
    [ -s ~/.bashrc ] && source ~/.bashrc
fi

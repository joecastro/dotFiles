#!/bin/zsh

#pragma once

#pragma validate-dotfiles

#pragma requires debug.sh

if [[ -z "$DOTFILES_INIT_EPOCHREALTIME_START" ]]; then
    _dotTrace "EPOCHREALTIME not set. Falling back to $(command -v date) for start time."
    DOTFILES_INIT_EPOCHREALTIME_START="$(__time_now)"
    _dotTrace "Inferred start time: $DOTFILES_INIT_EPOCHREALTIME_START"
fi

# Ensure homebrew is available to login/non-interactive shells through PATH
if command -v brew >/dev/null 2>&1; then
    eval "$(brew shellenv)"
elif [[ -x "/opt/homebrew/bin/brew" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x "/usr/local/bin/brew" ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
fi

#pragma requires platform.sh
#pragma requires env_funcs.sh
#pragma requires macos_funcs.sh
#pragma requires android_funcs.sh
#pragma requires util_funcs.sh

_dotTrace "Finished loading .zshenv"

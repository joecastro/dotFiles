#!/bin/zsh

#pragma once

#pragma validate-dotfiles

#pragma requires debug.sh

if [[ -z "$DOTFILES_INIT_EPOCHREALTIME_START" ]]; then
    _dotTrace "EPOCHREALTIME not set. Falling back to $(command -v date) for start time."
    DOTFILES_INIT_EPOCHREALTIME_START="$(__time_now)"
    _dotTrace "Inferred start time: $DOTFILES_INIT_EPOCHREALTIME_START"
fi

#pragma requires env_funcs.sh
#pragma requires macos_funcs.sh
#pragma requires android_funcs.sh
#pragma requires util_funcs.sh

[[ -f ~/.cargo/env ]] && source ~/.cargo/env
[ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && source "$NVM_DIR/bash_completion"

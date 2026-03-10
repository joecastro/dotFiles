#!/bin/zsh

#pragma once

#pragma validate-dotfiles

#pragma requires debug.sh

if [[ -z "$DOTFILES_INIT_EPOCHREALTIME_START" ]]; then
    _dotTrace "EPOCHREALTIME not set. Falling back to $(command -v date) for start time."
    DOTFILES_INIT_EPOCHREALTIME_START="$(__time_now)"
    _dotTrace "Inferred start time: $DOTFILES_INIT_EPOCHREALTIME_START"
fi

#pragma requires platform.sh
typeset __dotfiles_inherited_node_bin="$(__capture_inherited_nvm_node_bin_from_path "${PATH}" || true)"
__configure_homebrew_shellenv

#pragma requires env_funcs.sh
#pragma requires macos_funcs.sh
#pragma requires android_funcs.sh
#pragma requires util_funcs.sh

if [[ -n "${__dotfiles_inherited_node_bin}" ]]; then
    __restore_inherited_nvm_node_bin "${__dotfiles_inherited_node_bin}"
fi

__activate_preferred_node_version >/dev/null 2>&1
unset __dotfiles_inherited_node_bin

_dotTrace "Finished loading .zshenv"

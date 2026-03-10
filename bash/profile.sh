#! /bin/bash

#pragma once

#pragma validate-dotfiles

export BASH_SILENCE_DEPRECATION_WARNING=1

# Note: This also gets loaded by Ghostty and iTerm2. There isn't a way
# to ensure that the version aligns with what's loaded by the terminal.
# Right now everything is in sync at version 0.6.
#pragma requires bash/bash-preexec.sh

#pragma requires platform.sh
__dotfiles_inherited_node_bin="$(__capture_inherited_nvm_node_bin_from_path "${PATH}" || true)"
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

if __is_shell_bash; then
    #shellcheck source=./bashrc.sh
    [ -s ~/.bashrc ] && source ~/.bashrc
fi

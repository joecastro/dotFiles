#!/bin/zsh

#pragma once

#pragma validate-dotfiles

source ~/.env_vars.sh

[[ -f ~/.cargo/env ]] && source ~/.cargo/env

source "${DOTFILES_CONFIG_ROOT}/env_funcs.sh"

source "${DOTFILES_CONFIG_ROOT}/macos_funcs.sh"
source "${DOTFILES_CONFIG_ROOT}/android_funcs.sh" # Android shell utility functions
source "${DOTFILES_CONFIG_ROOT}/util_funcs.sh"

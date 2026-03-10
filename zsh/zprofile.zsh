#!/bin/zsh

#pragma once

#pragma validate-dotfiles

#pragma requires debug.sh
#pragma requires platform.sh
#pragma requires env_funcs.sh

__configure_homebrew_shellenv
__activate_preferred_node_version >/dev/null 2>&1

_dotTrace "Completed loading .zprofile"

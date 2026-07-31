#!/bin/zsh

#pragma once

#pragma validate-dotfiles

#pragma requires debug.sh
#pragma requires platform.sh
#pragma requires env_funcs.sh
#pragma requires macos_funcs.sh
#pragma requires android_funcs.sh
#pragma requires util_funcs.sh

__configure_login_toolchains

_dotTrace "Completed loading .zprofile"

#!/bin/zsh

#pragma once

#pragma validate-dotfiles

#pragma requires env_funcs.sh
#pragma requires macos_funcs.sh
#pragma requires android_funcs.sh
#pragma requires util_funcs.sh

[[ -f ~/.cargo/env ]] && source ~/.cargo/env
[ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && source "$NVM_DIR/bash_completion"

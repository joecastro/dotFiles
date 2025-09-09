#! /bin/bash

#pragma once

#pragma validate-dotfiles

export BASH_SILENCE_DEPRECATION_WARNING=1

# Set PATH, MANPATH, etc., for Homebrew.
test -d "/opt/homebrew/bin" && eval "$(/opt/homebrew/bin/brew shellenv)"

#shellcheck source=/dev/null
test -e ~/.cargo/env && source ~/.cargo/env

# shellcheck source=/dev/null
[ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"

#shellcheck source=/dev/null
[ -s "$NVM_DIR/bash_completion" ] && source "$NVM_DIR/bash_completion"

# Note: This also gets loaded by Ghostty and iTerm2. There isn't a way
# to ensure that the version aligns with what's loaded by the terminal.
# Right now everything is in sync at version 0.6.
#pragma requires bash/bash-preexec.sh

#pragma requires env_funcs.sh
#pragma requires macos_funcs.sh
#pragma requires android_funcs.sh
#pragma requires util_funcs.sh

if __is_shell_bash; then
    #shellcheck source=./bashrc.sh
    test -e ~/.bashrc && source ~/.bashrc
fi

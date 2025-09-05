#!/bin/zsh

#pragma once

#pragma validate-dotfiles

if [[ -z "$DOTFILES_INIT_EPOCHREALTIME_START" ]]; then
    if (( $+TRACE_DOTFILES )); then
        printf "[%s] [zshenv] Falling back to date implementation...\n" "$(date +%Y-%m-%dT%H:%M:%S%z)" >&2
    fi
    date_args="+%s.%N"
    if ! date "$date_args" 2>/dev/null | grep -q '\.'; then
        date_args="%s"
    fi
    DOTFILES_INIT_EPOCHREALTIME_START="$(date +"$date_args")"
    if (( $+TRACE_DOTFILES )); then
        printf "[%s] [zshenv] Inferred start time: %s using '%s %s'\n" \
            "$(date +%Y-%m-%dT%H:%M:%S%z)" \
            "${DOTFILES_INIT_EPOCHREALTIME_START}" \
            "$(command -v date)" \
            "$date_args" >&2
    fi
    unset date_args
fi

#pragma requires env_funcs.sh
#pragma requires macos_funcs.sh
#pragma requires android_funcs.sh
#pragma requires util_funcs.sh

[[ -f ~/.cargo/env ]] && source ~/.cargo/env
[ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && source "$NVM_DIR/bash_completion"

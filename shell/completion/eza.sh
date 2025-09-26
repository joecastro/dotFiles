#! /usr/bin/env bash

#pragma once

#pragma requires debug.sh
#pragma requires env_funcs.sh

_dotTrace "Configuring eza aliases and completions"

if ! command -v eza >/dev/null 2>&1; then
    __cute_shell_header_add_warning "eza not found"
    alias ls='ls -FHG'
    return 0
fi

export EZA_STRICT=0
export EZA_ICONS_AUTO=0

alias ls='eza -l --group-directories-first'
alias kd='eza --group-directories-first'

# shellcheck disable=SC2329
function kd_tree() {
    local arg="${1:-}"
    local -i level=3

    if [[ -n "$arg" && "$arg" =~ ^[0-9]+$ ]]; then
        if [[ -d "$arg" ]]; then
            echo "Warning: ambiguous argument '$arg' (both number and directory); using as level." >&2
        fi
        level="$arg"
        shift
    fi

    eza --tree --level="$level" --group-directories-first "$@"
}

alias kt='kd_tree'
alias realls='\ls -FHG'

unset completions_dir

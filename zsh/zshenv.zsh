#!/bin/zsh

#pragma once

#pragma validate-dotfiles

source ~/.env_vars.sh

[[ -f ~/.cargo/env ]] && source ~/.cargo/env

source "${DOTFILES_CONFIG_ROOT}/env_funcs.sh"

# "key" -> (test_function ICON)
typeset -a VSCODE_TERMINAL_ID=("__is_vscode_terminal" "ICON_MAP[MD_MICROSOFT_VISUAL_STUDIO_CODE]")
typeset -A EMBEDDED_TERMINAL_ID_FUNCS=( \
    [VSCODE]=VSCODE_TERMINAL_ID )

function __z_is_embedded_terminal() {
    __embedded_terminal_info --noshow
}

function __embedded_terminal_info() {
    for key value in ${(kv)EMBEDDED_TERMINAL_ID_FUNCS}; do
        local id_func=${(P)value:0:1}
        local icon=${(P)value:1:1}
        if eval ${id_func}; then
            if [[ "$1" != "--noshow" ]]; then
                echo -n "${(P)icon}"
            fi
            return 0
        fi
    done
    return 1
}

typeset -A DISTRIBUTION_ID_FUNCS=( \
    [WSL]="__is_on_wsl" \
    [OSX]="__is_on_osx" \
    [WINDOWS]="__is_on_windows" )

function __z_effective_distribution() {
    for distro func in ${(kv)DISTRIBUTION_ID_FUNCS}; do
        if $func; then
            echo $distro
            return 0
        fi
    done
    if __is_on_unexpected_linux; then
       echo "Linux"
    elif __is_on_unexpected_windows; then
        echo "Unexpected Win32 environment"
    else
        echo "Unhandled"
    fi
    return 1
}

# "key" -> (test_function ICON ICON_COLOR)
# typeset -a GIT_VIRTUALENV_ID=("__is_in_git_repo" "ICON_MAP[GIT]" "yellow")
typeset -a TMUX_VIRTUALENV_ID=("__is_in_tmux" "ICON_MAP[TMUX]" "white"])
typeset -a VIM_VIRTUALENV_ID=("(( \${+VIMRUNTIME} ))" "ICON_MAP[VIM]" "green")
typeset -a PYTHON_VIRTUALENV_ID=("(( \${+VIRTUAL_ENV} ))" "ICON_MAP[PYTHON]" "blue")
typeset -a WSL_WINDOWS_VIRTUALENV_ID=("__is_on_wsl && __is_in_windows_drive" "ICON_MAP[WINDOWS]" "blue")
typeset -a WSL_LINUX_VIRTUALENV_ID=("__is_on_wsl && ! __is_in_windows_drive" "ICON_MAP[LINUX_PENGUIN]" "blue")

typeset -a VIRTUALENV_ID_FUNCS=( \
    TMUX_VIRTUALENV_ID \
    VIM_VIRTUALENV_ID \
    PYTHON_VIRTUALENV_ID \
    WSL_WINDOWS_VIRTUALENV_ID \
    WSL_LINUX_VIRTUALENV_ID)

function __virtualenv_info() {
    local suffix="${1:-}"
    local has_virtualenv=1
    for value in "${VIRTUALENV_ID_FUNCS[@]}"; do
        local ID_FUNC=${(P)value:0:1}
        local ICON=${(P)value:1:1}
        local ICON_COLOR=${(P)value:2:1}
        if eval ${ID_FUNC}; then
            echo -n "%{$fg[${ICON_COLOR}]%}${(P)ICON}"
            has_virtualenv=0
        fi
    done
    if [[ "${has_virtualenv}" == "0" ]]; then
        echo -n "${suffix}"
    fi
    return ${has_virtualenv}
}

[[ -f "${DOTFILES_CONFIG_ROOT}/google_funcs.sh" ]] && source "${DOTFILES_CONFIG_ROOT}/google_funcs.sh"
source "${DOTFILES_CONFIG_ROOT}/osx_funcs.sh"
source "${DOTFILES_CONFIG_ROOT}/android_funcs.sh" # Android shell utility functions
source "${DOTFILES_CONFIG_ROOT}/util_funcs.sh"

CUTE_HEADER_PARTS+=("distro:$(__z_effective_distribution)")
if __z_is_embedded_terminal; then
    CUTE_HEADER_PARTS+=("embedded:$(__embedded_terminal_info)")
fi
#!/bin/zsh

#pragma once

test -e ~/.env_vars.sh && source ~/.env_vars.sh

EXPECT_NERD_FONTS="${EXPECT_NERD_FONTS:-0}"
BE_LOUD_ABOUT_SLOW_COMMANDS=0

EDITOR=vim

source "${DOTFILES_CONFIG_ROOT}/env_funcs.sh"

# "key" -> (test_function ICON)
typeset -a VSCODE_TERMINAL_ID=("__is_vscode_terminal" "ICON_MAP[MD_MICROSOFT_VISUAL_STUDIO_CODE]")
typeset -A EMBEDDED_TERMINAL_ID_FUNCS=( \
    [VSCODE]=VSCODE_TERMINAL_ID )

function __is_embedded_terminal() {
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
    [Windows]="__is_on_windows" )

function __effective_distribution() {
    for distro func in ${(kv)DISTRIBUTION_ID_FUNCS}; do
        if $func; then
            echo $distro
            return 0
        fi
    done
    if __is_on_unexpected_linux; then
       echo "Unexpected Linux environment"
    elif __is_on_unexpected_windows; then
        echo "Unexpected Win32 environment"
    else
        echo "Unhandled"
    fi
    return 1
}

# "key" -> (test_function ICON ICON_COLOR)
typeset -a TMUX_VIRTUALENV_ID=("__is_in_tmux" "ICON_MAP[TMUX]" "white"])
typeset -a VIM_VIRTUALENV_ID=("(( \${+VIMRUNTIME} ))" "ICON_MAP[VIM]" "green")
typeset -a PYTHON_VIRTUALENV_ID=("(( \${+VIRTUAL_ENV} ))" "ICON_MAP[PYTHON]" "blue")
typeset -A VIRTUALENV_ID_FUNCS=( \
    [TMUX]=TMUX_VIRTUALENV_ID \
    [VIM]=VIM_VIRTUALENV_ID \
    [PYTHON]=PYTHON_VIRTUALENV_ID )

function __virtualenv_info() {
    local has_virtualenv=1
    for key value in ${(kv)VIRTUALENV_ID_FUNCS}; do
        local ID_FUNC=${(P)value:0:1}
        local ICON=${(P)value:1:1}
        local ICON_COLOR=${(P)value:2:1}
        if eval ${ID_FUNC}; then
            echo -n "%{$fg[${ICON_COLOR}]%}${(P)ICON}"
            has_virtualenv=0
        fi
    done
    return ${has_virtualenv}
}

test -e ${DOTFILES_CONFIG_ROOT}/google_funcs.zsh && source ${DOTFILES_CONFIG_ROOT}/google_funcs.zsh
source ${DOTFILES_CONFIG_ROOT}/android_funcs.sh # Android shell utility functions
source ${DOTFILES_CONFIG_ROOT}/util_funcs.sh

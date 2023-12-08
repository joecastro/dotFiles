#!/bin/zsh

#pragma once

EDITOR=vim
GIT_EDITOR=vim

# emojipedia.org
ANCHOR_ICON=⚓
PIN_ICON=📌
HUT_ICON=🛖
HOUSE_ICON=🏠
TREE_ICON=🌲
DISK_ICON=💾
OFFICE_ICON=🏢
SNAKE_ICON=🐍
ROBOT_ICON=🤖

#Nerdfonts - https://www.nerdfonts.com/cheat-sheet
WINDOWS_ICON=
LINUX_PENGUIN_ICON=
GITHUB_ICON=
GOOGLE_ICON=
VIM_ICON=
ANDROID_HEAD_ICON=󰀲
ANDROID_BODY_ICON=
PYTHON_ICON=
GIT_BRANCH_ICON=
GIT_COMMIT_ICON=
HOME_FOLDER_ICON=󱂵
COD_FILE_SUBMODULE_ICON=
TMUX_ICON=
VS_CODE_ICON=󰨞
COD_HOME_ICON=
COD_PINNED_ICON=
COD_TOOLS_ICON=
COD_TAG_ICON=
COD_PACKAGE_ICON=
COD_SAVE_ICON=
FAE_TREE_ICON=
MD_SUBMARINE_ICON=󱕬
MD_GREATER_THAN_ICON=󰥭
MD_CHEVRON_DOUBLE_RIGHT_ICON=󰄾
MD_MICROSOFT_VISUAL_STUDIO_CODE_ICON=󰨞
MD_SNAPCHAT=󰒶
OCT_FILE_SUBMODULE_ICON=
COD_TERMINAL_BASH=
FA_DOLLAR_ICON=

function __is_ssh_session() {
    if [ -n "$SSH_CLIENT" ] || [ -n "$SSH_TTY" ] || [ -n "$SSH_CONNECTION" ]; then
        return 0
    fi
    return 1
}

function __is_in_git_repo() {
    git branch > /dev/null 2>&1;
    if [[ "$?" == "0" ]]; then
        return 0
    fi
    return 1
}

function __is_in_git_dir() {
    git rev-parse --is-inside-git-dir | grep "true" > /dev/null 2>&1;
    if [[ "$?" == "0" ]]; then
        return 0
    fi
    return 1
}

function __is_in_repo() {
    local verbose=0
    if [[ -z "$1" ]]; then
        unset verbose
    fi

    repo --show-toplevel > /dev/null 2>&1;
    if [[ "$?" == "0" ]]; then
        return 0
    fi

    if (( ${+verbose} )); then
        echo "error: Not in Android repo tree"
    fi

    return 1
}

function __is_interactive() {
    if [[ $- == *i* ]]; then
        return 0
    fi
    return 1
}

function __is_in_tmux() {
    if [ "$TERM" = "screen" ]; then
        return 1
    elif [ -n "$TMUX" ]; then
        return 0
    fi
    return 1
}

function __is_on_wsl() {
    grep -qE "(Microsoft|WSL)" /proc/version &> /dev/null
}

function __is_in_windows_drive() {
    if (( ${+WIN_SYSTEM_ROOT} )); then
        if test "${PWD##$WIN_SYSTEM_ROOT}" != "${PWD}"; then
            return 0
        fi
    fi
    return 1
}

function __is_on_osx() {
    if [[ "$(uname)" == "Darwin" ]]; then
        return 0
    fi
    return 1
}

function __is_on_windows() {
    if [[ "$(uname -s)" = "MINGW64_NT"* ]] || [[ "$(uname -s)" = "MSYS_NT"* ]]; then
        return 0
    fi
    return 1
}

function __is_on_unexpected_windows() {
    if [[ "$(uname -s)" = "MINGW32_NT"* ]]; then
        return 0
    fi
    return 1
}

function __is_on_unexpected_linux() {
    if [[ "$(uname -s)" = "Linux"* ]]; then
        return 0
    fi
    return 1
}

function __is_embedded_terminal() {
    # This isn't quite the same thing as running in an embedded terminal.
    # Code will launch an interactive shell to resolve environment variables.
    # This value can be used to detect that.
    if [[ "$VSCODE_RESOLVING_ENVIRONMENT" == "1" ]]; then
        return 0
    fi
    if [[ "$TERM_PROGRAM" == "vscode" ]]; then
        return 0
    fi
    return 1
}

typeset -A DISTRIBUTION_ID_FUNCS=( \
    ["WSL"]="__is_on_wsl" \
    ["OSX"]="__is_on_osx" \
    ["Windows"]="__is_on_windows" )

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
typeset -a TMUX_VIRTUALENV_ID=("__is_in_tmux" $TMUX_ICON "white"])
typeset -a VIM_VIRTUALENV_ID=("(( \${+VIMRUNTIME} ))" $VIM_ICON "green")
typeset -a PYTHON_VIRTUALENV_ID=("(( \${+VIRTUAL_ENV} ))" $PYTHON_ICON "blue")
typeset -A VIRTUALENV_ID_FUNCS=( \
    [TMUX]=TMUX_VIRTUALENV_ID \
    [VIM]=VIM_VIRTUALENV_ID \
    [PYTHON]=PYTHON_VIRTUALENV_ID )

function __virtualenv_info() {
    local HAS_VIRTUALENV=1
    for key value in ${(kv)VIRTUALENV_ID_FUNCS}; do
        if eval ${${(P)value}:0:1}; then
            echo -n "%{$fg[${${(P)value}:2:1}]%}${${(P)value}:1:1}"
            HAS_VIRTUALENV=0
        fi
    done
    return $HAS_VIRTUALENV
}

source ~/.env_vars.sh

test -e ${DOTFILES_CONFIG_ROOT}/google_funcs.zsh && source ${DOTFILES_CONFIG_ROOT}/google_funcs.zsh
source ${DOTFILES_CONFIG_ROOT}/android_funcs.sh # Android shell utility functions
source ${DOTFILES_CONFIG_ROOT}/util_funcs.sh

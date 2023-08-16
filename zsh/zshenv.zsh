#!/bin/zsh

#pragma once
PRAGMA_FILE_NAME="PRAGMA_${"${(%):-%1N}"//\./_}"
[ -n "${(P)PRAGMA_FILE_NAME}" ] && unset PRAGMA_FILE_NAME && return;
declare $PRAGMA_FILE_NAME=0
unset PRAGMA_FILE_NAME

EDITOR=vim
GIT_EDITOR=vim

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
    verbose=0
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

test -e ~/.google_funcs.zsh && source ~/.google_funcs.zsh
source ~/.android_funcs.zsh # Android shell utility functions
source ~/.util_funcs.zsh

#<DOTFILES_HOME_SUBST>

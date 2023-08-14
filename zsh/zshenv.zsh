#!/bin/zsh

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

function __is_in_wsl() {
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

function __is_embedded_terminal() {
    if [[ "$TERM_PROGRAM" == "vscode" ]]; then
        return 0
    fi
    return 1
}

function __effective_distribution() {
    if __is_in_wsl; then
        echo "WSL"
    elif [[ "$(uname)" == "Darwin" ]]; then
        echo "OSX"
    elif [[ "$(expr substr $(uname -s) 1 5)" == "Linux" ]]; then
        echo "Unexpected Linux environment"
    elif [[ "$(expr substr $(uname -s) 1 10)" == "MINGW32_NT" ]]; then
        echo "Unexpected Win32 environment"
    elif [[ "$(expr substr $(uname -s) 1 10)" == "MINGW64_NT" ]] || [[ "$(expr substr $(uname -s) 1 7)" == "MSYS_NT" ]]; then
        echo "Windows"
    else
        echo "Unhandled"
    fi
}

if __is_in_wsl; then
    WIN_SYSTEM_DRIVE=$(powershell.exe '$env:SystemDrive')
    WIN_SYSTEM_ROOT="/mnt/${WIN_ROOT:0:1:l}"
    WIN_USERNAME=$(powershell.exe '$env:UserName')
    WIN_USERPROFILE=$(echo $(wslpath $(powershell.exe '$env:UserProfile')) | sed $'s/\r//')
fi

test -e ~/.google_funcs.zsh && source ~/.google_funcs.zsh
source ~/.android_funcs.zsh # Android shell utility functions
source ~/.util_funcs.zsh

#<DOTFILES_HOME_SUBST>

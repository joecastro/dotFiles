#! /bin/bash

#pragma once

function __is_ssh_session() {
    [ -n "${SSH_CLIENT}" ] || [ -n "${SSH_TTY}" ] || [ -n "${SSH_CONNECTION}" ]
}

function __is_in_git_repo() {
    git branch > /dev/null 2>&1;
}

function __is_in_git_dir() {
    git rev-parse --is-inside-git-dir | grep "true" > /dev/null 2>&1;
}

function __is_in_repo() {
    local verbose=0
    if [[ -z "$1" ]]; then
        unset verbose
    fi

    if repo --show-toplevel > /dev/null 2>&1; then
        return 0
    fi

    if [[ ${verbose} -eq 0 ]]; then
        echo "error: Not in Android repo tree"
    fi

    return 1
}

function __is_interactive() {
    [[ $- == *i* ]]
}

function __is_in_tmux() {
    if [ "${TERM}" = "screen" ]; then
        return 1
    fi

    [ -n "${TMUX}" ]
}

function __is_on_wsl() {
    grep -qE "(Microsoft|WSL)" /proc/version &> /dev/null
}

function __is_in_windows_drive() {
    if [ -z "${WIN_SYSTEM_ROOT-}" ]; then
        return 1
    fi

    if test "${PWD##"${WIN_SYSTEM_ROOT}"}" != "${PWD}"; then
        return 0
    fi

    return 1
}

function __is_on_osx() {
    [[ "$(uname)" == "Darwin" ]]
}

function __is_on_windows() {
    [[ "$(uname -s)" = "MINGW64_NT"* ]] || [[ "$(uname -s)" = "MSYS_NT"* ]];
}

function __is_on_unexpected_windows() {
    [[ "$(uname -s)" = "MINGW32_NT"* ]]
}

function __is_on_unexpected_linux() {
    [[ "$(uname -s)" = "Linux"* ]];
}

function __is_vscode_terminal() {
    # This isn't quite the same thing as running in an embedded terminal.
    # Code will launch an interactive shell to resolve environment variables.
    # This value can be used to detect that.
    if [[ "${VSCODE_RESOLVING_ENVIRONMENT}" == "1" ]]; then
        return 0
    fi
    if [[ "${TERM_PROGRAM}" == "vscode" ]]; then
        return 0
    fi
    return 1
}

#! /bin/bash

#pragma once

function __is_shell_interactive() { [[ $- == *i* ]]; }
function __is_in_screen() { [ "${TERM}" = "screen" ]; }

function __is_in_tmux() {
    if __is_in_screen; then return 1; fi
    [ -n "${TMUX}" ]
}

function __is_in_vimruntime() { [ -n "${VIMRUNTIME}" ]; }
function __is_in_python_venv() { [ -n "${VIRTUAL_ENV}" ]; }

function __is_on_wsl() { grep -qE "(Microsoft|WSL)" /proc/version &> /dev/null; }

function __is_in_windows_drive() {
    if [ -z "${WIN_SYSTEM_ROOT-}" ]; then return 1; fi
    [[ "${PWD##"${WIN_SYSTEM_ROOT}"}" != "${PWD}" ]]
}

function __is_in_wsl_windows_drive() { __is_on_wsl && __is_in_windows_drive; }
function __is_in_wsl_linux_drive() { __is_on_wsl && ! __is_in_windows_drive; }

function __is_on_macos() { [[ "$(uname -s)" == "Darwin" ]]; }
function __is_on_windows() { [[ "$(uname -s)" = "MINGW64_NT"* ]] || [[ "$(uname -s)" = "MSYS_NT"* ]]; }
function __is_on_unexpected_windows() { [[ "$(uname -s)" = "MINGW32_NT"* ]]; }
function __is_on_linux() { [[ "$(uname -s)" = "Linux"* ]]; }

function __print_linux_distro() {
    if [[ -f /etc/lsb-release ]]; then
        . /etc/lsb-release
        echo -n "${DISTRIB_ID}"
    else
        echo -n "Unknown Linux distribution"
    fi
}

function __is_vscode_terminal() {
    if [[ "${VSCODE_RESOLVING_ENVIRONMENT}" == "1" ]]; then return 0; fi
    if [[ "${TERM_PROGRAM}" == "vscode" ]]; then return 0; fi
    return 1
}

function __is_iterm2_terminal() { [[ "iTerm2" == "${LC_TERMINAL}" ]]; }
function __is_konsole_terminal() { [[ -n "${KONSOLE_VERSION}" ]]; }
function __is_ghostty_terminal() { [[ "${TERM}" == "xterm-ghostty" ]]; }
function __is_tool_window() { [[ -n "${TOOL_WINDOW}" ]]; }

function __is_shell_bash() { [[ -n "${BASH_VERSION}" ]]; }
function __is_shell_old_bash() { __is_shell_bash && [[ "${BASH_VERSINFO[0]}" -lt 4 ]]; }
function __is_shell_zsh() { [[ -n "${ZSH_VERSION}" ]]; }

function __is_homebrew_bin() {
    local bin_path="$1"
    [[ $bin_path == ${HOMEBREW_PREFIX:-/opt/homebrew}/bin/* ]]
}

function __has_citc() { command -v citctools > /dev/null; }


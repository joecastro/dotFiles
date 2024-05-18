#! /bin/bash

#pragma once

# emojipedia.org
#Nerdfonts - https://www.nerdfonts.com/cheat-sheet
if [[ ${EXPECT_NERD_FONTS} = 0 ]]; then
    declare -A ICON_MAP=(
        [WINDOWS]=
        [LINUX_PENGUIN]=
        [GITHUB]=
        [GOOGLE]=
        [VIM]=
        [ANDROID_HEAD]=󰀲
        [ANDROID_BODY]=
        [PYTHON]=
        [GIT_BRANCH]=
        [GIT_COMMIT]=
        [HOME_FOLDER]=󱂵
        [COD_FILE_SUBMODULE]=
        [TMUX]=
        [VS_CODE]=󰨞
        [COD_HOME]=
        [COD_PINNED]=
        [COD_TOOLS]=
        [COD_TAG]=
        [COD_PACKAGE]=
        [COD_SAVE]=
        [FAE_TREE]=
        [MD_SUBMARINE]=󱕬
        [MD_GREATER_THAN]=󰥭
        [MD_CHEVRON_DOUBLE_RIGHT]=󰄾
        [MD_MICROSOFT_VISUAL_STUDIO_CODE]=󰨞
        [MD_SNAPCHAT]=󰒶
        [OCT_FILE_SUBMODULE]=
        [COD_TERMINAL_BASH]=
        [FA_DOLLAR]=
        [FA_BEER]=
        [CIDER]=
    )
else
    declare -A ICON_MAP=(
        [WINDOWS]=🪟
        [LINUX_PENGUIN]=🐧
        [GITHUB]="🐈‍🐙" # octo-cat
        [GOOGLE]="{G}"
        [VIM]="{vim}"
        [ANDROID_HEAD]=🤖
        [ANDROID_BODY]=🤖
        [PYTHON]=🐍
        [GIT_BRANCH]=️"(b)"
        [GIT_COMMIT]="(c)"
        [HOME_FOLDER]="📁‍🏠"
        [COD_FILE_SUBMODULE]=📂
        [TMUX]=🤵
        [VS_CODE]=♾️
        [COD_HOME]=🏠
        [COD_PINNED]=📌
        [COD_TOOLS]=🛠️
        [COD_TAG]=🏷️
        [COD_PACKAGE]=📦
        [COD_SAVE]=💾
        [FAE_TREE]=🌲
        [MD_SUBMARINE]="{sub}"
        [MD_GREATER_THAN]=">"
        [MD_CHEVRON_DOUBLE_RIGHT]=">>"
        [MD_MICROSOFT_VISUAL_STUDIO_CODE]=♾️
        [MD_SNAPCHAT]=👻
        [OCT_FILE_SUBMODULE]=🗄️
        [COD_TERMINAL_BASH]="{bash}"
        [FA_DOLLAR]=$
        [FA_BEER]=🍺
        [CIDER]=🍺
    )
fi
export ICON_MAP

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
    repo --show-toplevel > /dev/null 2>&1
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

function __is_tool_window() {
    [[ -n "${TOOL_WINDOW}" ]];
}
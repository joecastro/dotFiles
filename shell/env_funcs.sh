#! /bin/bash

#pragma once

declare -A ICON_MAP=([NOTHING]="")

function __refresh_icon_map() {
    USE_NERD_FONTS="$1"
    # emojipedia.org
    #Nerdfonts - https://www.nerdfonts.com/cheat-sheet
    if [[ ${USE_NERD_FONTS} = 0 ]]; then
        ICON_MAP=(
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
        [YAWN]=
        [ACCOUNT]=
        [CLOUD]=󰅟
        )
    else
        ICON_MAP=(
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
        [YAWN]=🥱
        [ACCOUNT]=🙋
        [CLOUD]=🌥️
        )
    fi
}

__refresh_icon_map "${EXPECT_NERD_FONTS:-0}"
export ICON_MAP

function __source_if_exists() {
    local file="$1"
    if [[ -f "$file" ]]; then
        # shellcheck disable=SC1090
        source "$file"
        return 0
    fi
    return 1
}

function __invoke_if_exists() {
    if declare -f "$1" > /dev/null; then
        "$1"
    fi
}

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

function __is_shell_interactive() {
    [[ $- == *i* ]]
}

function __is_in_screen() {
    [ "${TERM}" = "screen" ]
}

function __is_in_tmux() {
    if __is_in_screen; then
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

    [[ "${PWD##"${WIN_SYSTEM_ROOT}"}" != "${PWD}" ]]
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

function __is_iterm2_terminal() {
    # When in SSH, TERM_PROGRAM isn't getting propagated.
    [[ "iTerm2" == "${LC_TERMINAL}" ]]
}

function __is_tool_window() {
    [[ -n "${TOOL_WINDOW}" ]];
}

function __cute_pwd_helper() {
    local ACTIVE_DIR=$1
    local SUFFIX=$2

    # These should only match if they're exact.
    case "${ACTIVE_DIR}" in
    "${HOME}")
        echo -n "${ICON_MAP[COD_HOME]}${SUFFIX}"
        return 0
        ;;
    "${WIN_USERPROFILE}")
        echo -n "${ICON_MAP[WINDOWS]}${SUFFIX}"
        return 0
        ;;
    "/")
        echo -n "${ICON_MAP[FAE_TREE]}${SUFFIX}"
        return 0
        ;;
    esac

    if [[ -v ANDROID_REPO_BRANCH ]]; then
        if [[ "${ACTIVE_DIR##*/}" == "${ANDROID_REPO_BRANCH}" ]]; then
            echo -n "${ICON_MAP[ANDROID_HEAD]}${SUFFIX}"
            return 0
        fi
    fi

    case "${ACTIVE_DIR##*/}" in
    "github")
        echo -n "${ICON_MAP[GITHUB]}${SUFFIX}"
        return 0
        ;;
    "src" | "source")
        echo -n "${ICON_MAP[COD_SAVE]}${SUFFIX}"
        return 0
        ;;
    "cloud")
        echo -n "${ICON_MAP[CLOUD]}${SUFFIX}"
        return 0
        ;;
    "${USER}")
        echo -n "${ICON_MAP[ACCOUNT]}${SUFFIX}"
        return 0
        ;;
    *)
        ;;
    esac

    # If there is a suffix here then don't print the directory.
    if [[ "${SUFFIX}" == "" ]]; then
        echo -n "${ACTIVE_DIR##*/}"
    fi

    return 0
}

function __cute_pwd() {
    if __is_in_git_repo; then
        if ! __is_in_git_dir; then
            # If we're in a git repo then show the current directory relative to the root of that repo.
            # These commands wind up spitting out an extra slash, so backspace to remove it on the console.
            # Because this messes with the shell's perception of where the cursor is, make the anchor icon
            # appear like an escape sequence instead of a printed character.
            echo -e "%{${ICON_MAP[COD_PINNED]} %}$(git rev-parse --show-toplevel | xargs basename)/$(git rev-parse --show-prefix)\b"
        else
            echo -n "${PWD}"
        fi
        return 0
    fi

    if [[ "${PWD}" != "/" ]]; then
        __cute_pwd_helper "$(dirname "${PWD}")" "/"
    fi
    __cute_pwd_helper "${PWD}" ""
    return 0
}

function __cute_pwd_short() {
    __cute_pwd_helper "${PWD}" ""
}

#! /bin/bash

#pragma once

# shellcheck source=/dev/null
source ~/.env_vars.sh

if [ -d "/opt/homebrew/bin" ]; then
    # Set PATH, MANPATH, etc., for Homebrew.
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

export BASH_SILENCE_DEPRECATION_WARNING=1
export EXPECT_NERD_FONTS="${EXPECT_NERD_FONTS:-0}"
export EDITOR=vim

function __refresh_icon_vars() {
    # emojipedia.org
    #Nerdfonts - https://www.nerdfonts.com/cheat-sheet
    if [[ ${EXPECT_NERD_FONTS} = 0 ]]; then
        export WINDOWS_ICON=
    else
        export WINDOWS_ICON=🪟
    fi
    if [[ ${EXPECT_NERD_FONTS} = 0 ]]; then
        export LINUX_PENGUIN_ICON=
    else
        export LINUX_PENGUIN_ICON=🐧
    fi
    if [[ ${EXPECT_NERD_FONTS} = 0 ]]; then
        export GITHUB_ICON=
    else
        export GITHUB_ICON="🐈‍🐙" # octo-cat
    fi
    if [[ ${EXPECT_NERD_FONTS} = 0 ]]; then
        export GOOGLE_ICON=
    else
        export GOOGLE_ICON="{G}"
    fi
    if [[ ${EXPECT_NERD_FONTS} = 0 ]]; then
        export VIM_ICON=
    else
        export VIM_ICON="{vim}"
    fi
    if [[ ${EXPECT_NERD_FONTS} = 0 ]]; then
        export ANDROID_HEAD_ICON=󰀲
    else
        export ANDROID_HEAD_ICON=🤖
    fi
    if [[ ${EXPECT_NERD_FONTS} = 0 ]]; then
        export ANDROID_BODY_ICON=
    else
        export ANDROID_BODY_ICON=🤖
    fi
    if [[ ${EXPECT_NERD_FONTS} = 0 ]]; then
        export PYTHON_ICON=
    else
        export PYTHON_ICON=🐍
    fi
    if [[ ${EXPECT_NERD_FONTS} = 0 ]]; then
        export GIT_BRANCH_ICON=
    else
        export GIT_BRANCH_ICON=️"(b)"
    fi
    if [[ ${EXPECT_NERD_FONTS} = 0 ]]; then
        export GIT_COMMIT_ICON=
    else
        export GIT_COMMIT_ICON="(c)"
    fi
    if [[ ${EXPECT_NERD_FONTS} = 0 ]]; then
        export HOME_FOLDER_ICON=󱂵
    else
        export HOME_FOLDER_ICON="📁‍🏠"
    fi
    if [[ ${EXPECT_NERD_FONTS} = 0 ]]; then
        export COD_FILE_SUBMODULE_ICON=
    else
        export COD_FILE_SUBMODULE_ICON=📂
    fi
    if [[ ${EXPECT_NERD_FONTS} = 0 ]]; then
        export TMUX_ICON=
    else
        export TMUX_ICON=🤵
    fi
    if [[ ${EXPECT_NERD_FONTS} = 0 ]]; then
        export VS_CODE_ICON=󰨞
    else
        export VS_CODE_ICON=♾️
    fi
    if [[ ${EXPECT_NERD_FONTS} = 0 ]]; then
        export COD_HOME_ICON=
    else
        export COD_HOME_ICON=🏠
    fi
    if [[ ${EXPECT_NERD_FONTS} = 0 ]]; then
        export COD_PINNED_ICON=
    else
        export COD_PINNED_ICON=📌
    fi
    if [[ ${EXPECT_NERD_FONTS} = 0 ]]; then
        export COD_TOOLS_ICON=
    else
        export COD_TOOLS_ICON=🛠️
    fi
    if [[ ${EXPECT_NERD_FONTS} = 0 ]]; then
        export COD_TAG_ICON=
    else
        export COD_TAG_ICON=🏷️
    fi
    if [[ ${EXPECT_NERD_FONTS} = 0 ]]; then
        export COD_PACKAGE_ICON=
    else
        export COD_PACKAGE_ICON=📦
    fi
    if [[ ${EXPECT_NERD_FONTS} = 0 ]]; then
        export COD_SAVE_ICON=
    else
        export COD_SAVE_ICON=💾
    fi
    if [[ ${EXPECT_NERD_FONTS} = 0 ]]; then
        export FAE_TREE_ICON=
    else
        export FAE_TREE_ICON=🌲
    fi
    if [[ ${EXPECT_NERD_FONTS} = 0 ]]; then
        export MD_SUBMARINE_ICON=󱕬
    else
        export MD_SUBMARINE_ICON="{sub}"
    fi
    if [[ ${EXPECT_NERD_FONTS} = 0 ]]; then
        export MD_GREATER_THAN_ICON=󰥭
    else
        export MD_GREATER_THAN_ICON=">"
    fi
    if [[ ${EXPECT_NERD_FONTS} = 0 ]]; then
        export MD_CHEVRON_DOUBLE_RIGHT_ICON=󰄾
    else
        export MD_CHEVRON_DOUBLE_RIGHT_ICON=">>"
    fi
    if [[ ${EXPECT_NERD_FONTS} = 0 ]]; then
        export MD_MICROSOFT_VISUAL_STUDIO_CODE_ICON=󰨞
    else
        export MD_MICROSOFT_VISUAL_STUDIO_CODE_ICON=♾️
    fi
    if [[ ${EXPECT_NERD_FONTS} = 0 ]]; then
        export MD_SNAPCHAT=󰒶
    else
        export MD_SNAPCHAT=👻
    fi
    if [[ ${EXPECT_NERD_FONTS} = 0 ]]; then
        export OCT_FILE_SUBMODULE_ICON=
    else
        export OCT_FILE_SUBMODULE_ICON=🗄️
    fi
    if [[ ${EXPECT_NERD_FONTS} = 0 ]]; then
        export COD_TERMINAL_BASH=
    else
        export COD_TERMINAL_BASH="{bash}"
    fi
    if [[ ${EXPECT_NERD_FONTS} = 0 ]]; then
        export FA_DOLLAR_ICON=
    else
        export FA_DOLLAR_ICON="$"
    fi
    if [[ ${EXPECT_NERD_FONTS} = 0 ]]; then
        export FA_BEER_ICON=
    else
        export FA_BEER_ICON=🍺
    fi
    export CIDER_ICON=$FA_BEER_ICON
}

__refresh_icon_vars

source "${DOTFILES_CONFIG_ROOT}/android_funcs.sh" # Android shell utility functions
source "${DOTFILES_CONFIG_ROOT}/util_funcs.sh"
source "${DOTFILES_CONFIG_ROOT}/env_funcs.sh"

if [ -n "${BASH_VERSION}" ]; then
    test -e ~/.bashrc && source ~/.bashrc
fi

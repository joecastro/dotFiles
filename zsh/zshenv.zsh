#!/bin/zsh

#pragma once

test -e ~/.env_vars.sh && source ~/.env_vars.sh

EXPECT_NERD_FONTS="${EXPECT_NERD_FONTS:-0}"

EDITOR=vim

function __refresh_icon_vars() {
    # Ensure all icon variables are exported
    emulate -L zsh
    setopt all_export

    # emojipedia.org
    #Nerdfonts - https://www.nerdfonts.com/cheat-sheet
    [[ ${EXPECT_NERD_FONTS} = 0 ]] && WINDOWS_ICON= || WINDOWS_ICON=🪟
    [[ ${EXPECT_NERD_FONTS} = 0 ]] && LINUX_PENGUIN_ICON= || LINUX_PENGUIN_ICON=🐧
    [[ ${EXPECT_NERD_FONTS} = 0 ]] && GITHUB_ICON= || GITHUB_ICON="🐈‍🐙" # octo-cat
    [[ ${EXPECT_NERD_FONTS} = 0 ]] && GOOGLE_ICON= || GOOGLE_ICON="{G}"
    [[ ${EXPECT_NERD_FONTS} = 0 ]] && VIM_ICON= || VIM_ICON="{vim}"
    [[ ${EXPECT_NERD_FONTS} = 0 ]] && ANDROID_HEAD_ICON=󰀲 || ANDROID_HEAD_ICON=🤖
    [[ ${EXPECT_NERD_FONTS} = 0 ]] && ANDROID_BODY_ICON= || ANDROID_BODY_ICON=🤖
    [[ ${EXPECT_NERD_FONTS} = 0 ]] && PYTHON_ICON= || PYTHON_ICON=🐍
    [[ ${EXPECT_NERD_FONTS} = 0 ]] && GIT_BRANCH_ICON= || GIT_BRANCH_ICON=️"(b)"
    [[ ${EXPECT_NERD_FONTS} = 0 ]] && GIT_COMMIT_ICON= || GIT_COMMIT_ICON="(c)"
    [[ ${EXPECT_NERD_FONTS} = 0 ]] && HOME_FOLDER_ICON=󱂵 || HOME_FOLDER_ICON="📁‍🏠"
    [[ ${EXPECT_NERD_FONTS} = 0 ]] && COD_FILE_SUBMODULE_ICON= || COD_FILE_SUBMODULE_ICON=📂
    [[ ${EXPECT_NERD_FONTS} = 0 ]] && TMUX_ICON= || TMUX_ICON=🤵
    [[ ${EXPECT_NERD_FONTS} = 0 ]] && VS_CODE_ICON=󰨞 || VS_CODE_ICON=♾️
    [[ ${EXPECT_NERD_FONTS} = 0 ]] && COD_HOME_ICON= || COD_HOME_ICON=🏠
    [[ ${EXPECT_NERD_FONTS} = 0 ]] && COD_PINNED_ICON= || COD_PINNED_ICON=📌
    [[ ${EXPECT_NERD_FONTS} = 0 ]] && COD_TOOLS_ICON= || COD_TOOLS_ICON=🛠️
    [[ ${EXPECT_NERD_FONTS} = 0 ]] && COD_TAG_ICON= || COD_TAG_ICON=🏷️
    [[ ${EXPECT_NERD_FONTS} = 0 ]] && COD_PACKAGE_ICON= || COD_PACKAGE_ICON=📦
    [[ ${EXPECT_NERD_FONTS} = 0 ]] && COD_SAVE_ICON= || COD_SAVE_ICON=💾
    [[ ${EXPECT_NERD_FONTS} = 0 ]] && FAE_TREE_ICON= || FAE_TREE_ICON=🌲
    [[ ${EXPECT_NERD_FONTS} = 0 ]] && MD_SUBMARINE_ICON=󱕬 || MD_SUBMARINE_ICON="{sub}"
    [[ ${EXPECT_NERD_FONTS} = 0 ]] && MD_GREATER_THAN_ICON=󰥭 || MD_GREATER_THAN_ICON=">"
    [[ ${EXPECT_NERD_FONTS} = 0 ]] && MD_CHEVRON_DOUBLE_RIGHT_ICON=󰄾 || MD_CHEVRON_DOUBLE_RIGHT_ICON=">>"
    [[ ${EXPECT_NERD_FONTS} = 0 ]] && MD_MICROSOFT_VISUAL_STUDIO_CODE_ICON=󰨞 || MD_MICROSOFT_VISUAL_STUDIO_CODE_ICON=♾️
    [[ ${EXPECT_NERD_FONTS} = 0 ]] && MD_SNAPCHAT=󰒶 || MD_SNAPCHAT=👻
    [[ ${EXPECT_NERD_FONTS} = 0 ]] && OCT_FILE_SUBMODULE_ICON= || OCT_FILE_SUBMODULE_ICON=🗄️
    [[ ${EXPECT_NERD_FONTS} = 0 ]] && COD_TERMINAL_BASH= || COD_TERMINAL_BASH="{bash}"
    [[ ${EXPECT_NERD_FONTS} = 0 ]] && FA_DOLLAR_ICON= || FA_DOLLAR_ICON="$"
    [[ ${EXPECT_NERD_FONTS} = 0 ]] && FA_BEER_ICON= || FA_BEER_ICON=🍺
    CIDER_ICON=$FA_BEER_ICON
}

__refresh_icon_vars

source "${DOTFILES_CONFIG_ROOT}/env_funcs.sh"

# "key" -> (test_function ICON)
typeset -a VSCODE_TERMINAL_ID=("__is_vscode_terminal" MD_MICROSOFT_VISUAL_STUDIO_CODE_ICON)
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
typeset -a TMUX_VIRTUALENV_ID=("__is_in_tmux" TMUX_ICON "white"])
typeset -a VIM_VIRTUALENV_ID=("(( \${+VIMRUNTIME} ))" VIM_ICON "green")
typeset -a PYTHON_VIRTUALENV_ID=("(( \${+VIRTUAL_ENV} ))" PYTHON_ICON "blue")
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

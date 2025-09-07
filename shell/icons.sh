#! /bin/bash

#pragma once

#pragma requires platform.sh

# Suppress warnings on bash 3
declare -A ICON_MAP=([NOTHING]="❌") > /dev/null 2>&1

declare -A EMOJI_ICON_MAP=(
    [WINDOWS]=🪟
    [LINUX_PENGUIN]=🐧
    [GIT]=🐙
    [GITHUB]=🐈
    [GOOGLE]=🔍
    [VIM]=🦄
    [ANDROID_HEAD]=🤖
    [ANDROID_BODY]=🤖
    [PYTHON]=🐍
    [GIT_BRANCH]=🌿
    [GIT_COMMIT]=🌱
    [HOME_FOLDER]="📁‍🏠"
    [COD_FILE_SUBMODULE]=📂
    [TMUX]=🤵
    [COD_HOME]=🏠
    [COD_PINNED]=📌
    [COD_TOOLS]=🛠️
    [COD_TAG]=🏷️
    [COD_PACKAGE]=📦
    [COD_SAVE]=💾
    [FAE_TREE]=🌲
    [MD_SUBMARINE]=🚢
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
    [DEBIAN]=🌀
    [UBUNTU]=👫
    [DOWNLOAD]=📥
    [DESKTOP]=🖥️
    [PICTURES]=🖼️
    [MUSIC]=🎵
    [VIDEOS]=🎥
    [DOCUMENTS]=📄
    [KEY]=🔑
    [LEGO]=🪀
    [ARROW_UP]=⬆️
    [ARROW_DOWN]=⬇️
    [ARROW_UPDOWN]=↕️
    [ARROW_UP_THICK]=⬆️
    [ARROW_DOWN_THICK]=⬇️
    [ARROW_UPDOWN_THICK]=↕️
    [REVIEW]=📝
    [TOOLS]=🛠️
    [NODEJS]=🔩
    [CLOCK]=🕰️
    [X]=❌
    [QUESTION]=❓
    [ALARM]=🚨
    [TEST_TUBE]=🧪
    [ALERT]=⚠️
    [APPLE_FINDER]= # Only legible on MacOS and iOS
    ) > /dev/null 2>&1

declare -A NF_ICON_MAP=(
    [WINDOWS]=
    [LINUX_PENGUIN]=
    [GIT]=
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
    [DEBIAN]=
    [UBUNTU]=
    [DOWNLOAD]=
    [DESKTOP]=
    [PICTURES]=
    [MUSIC]=
    [VIDEOS]=
    [DOCUMENTS]=
    [KEY]=
    [LEGO]=
    [ARROW_UP]=
    [ARROW_DOWN]=
    [ARROW_UPDOWN]=󰹹
    [ARROW_UP_THICK]=󰁞
    [ARROW_DOWN_THICK]=󰁆
    [ARROW_UPDOWN_THICK]=󰹺
    [REVIEW]=
    [TOOLS]=
    [NODEJS]=
    [CLOCK]=
    [X]=󰅖
    [QUESTION]=
    [ALARM]=󰞎
    [TEST_TUBE]=
    [ALERT]=
    [APPLE_FINDER]=󰀶
    ) > /dev/null 2>&1

if __is_shell_zsh; then
    # shellcheck disable=SC2296
    declare -a ICON_MAP_KEYS=("${(@k)EMOJI_ICON_MAP}")
else
    declare -a ICON_MAP_KEYS=("${!EMOJI_ICON_MAP[@]}")
fi

function __refresh_icon_map() {
    local USE_NERD_FONTS="$1"
    if __is_shell_old_bash;
        then return 1;
    fi
    unset "ICON_MAP[NOTHING]"
    if [[ "${USE_NERD_FONTS}" == "0" ]]; then
        for key in "${ICON_MAP_KEYS[@]}"; do ICON_MAP[$key]=${NF_ICON_MAP[$key]}; done
    else
        for key in "${ICON_MAP_KEYS[@]}"; do ICON_MAP[$key]=${EMOJI_ICON_MAP[$key]}; done
    fi
}

function __print_icon_map() {
    echo "Icon Map:"
    for key in "${ICON_MAP_KEYS[@]}"; do
        echo "  $key => ${ICON_MAP[$key]}"
    done
}

__refresh_icon_map "${EXPECT_NERD_FONTS:-0}"
export ICON_MAP

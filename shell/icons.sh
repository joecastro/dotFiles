#! /bin/bash

#pragma once

#pragma requires platform.sh

# On very old Bash (pre-4, no associative arrays), make ICON_MAP a scalar fallback.
# In Bash, `${var[something]}` on a scalar expands to `${var}`; setting this to ❌
# ensures `${ICON_MAP[ANY_KEY]}` reliably prints an X.
if __is_shell_old_bash; then
    declare -a ICON_MAP='❌'
    export ICON_MAP
    return 0
fi

declare -A ICON_MAP=([NOTHING]="❌")

declare -A COMMON_ICON_MAP=(
    [MD_GREATER_THAN]=">"
    [MD_CHEVRON_DOUBLE_RIGHT]=">>"
    [FA_DOLLAR]=$
    [GIT_BRANCH]=⑂
    [GIT_COMMIT]=●
    [HOME_FOLDER]=⌂
    [PINNED]=⌖
    [PINNED_OUTLINE]=⌖
    [ARROW_UP]=↑
    [ARROW_DOWN]=↓
    [ARROW_UPDOWN]=↕
    [ARROW_UP_THICK]=⬆
    [ARROW_DOWN_THICK]=⬇
    [ARROW_UPDOWN_THICK]=⇅
    [DOWNLOAD]=⇩
    [CLOUD]=☁
    [KEY]=⚿
    [CLOCK]=◷
    [X]=×
    [QUESTION]="?"
    [ALERT]=⚠
    [TOOLS]=⚒
    [REACT]=⚛
    [GIT_REMOTE_ORIGIN]=ⓞ
    [GIT_REMOTE_FORK]=ⓕ
    [GIT_REMOTE_UPSTREAM]=ⓤ
    [GIT_REMOTE_UNTRACKED]=○
    )

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
    [PINNED]=📌
    [PINNED_OUTLINE]=📌
    [COD_TOOLS]=🛠️
    [COD_TAG]=🏷️
    [COD_PACKAGE]=📦
    [COD_SAVE]=💾
    [FAE_TREE]=🌲
    [MD_SUBMARINE]=🚢
    [MD_MICROSOFT_VISUAL_STUDIO_CODE]=♾️
    [MD_SNAPCHAT]=👻
    [OCT_FILE_SUBMODULE]=🗄️
    [COD_TERMINAL_BASH]="{bash}"
    [BEER]=🍺
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
    [APPLE]=🍎
    [DOLBY]=🔊
    [RUST]=🦀
    [VUEJS]=🇻
    [NEXTJS]=➡️
    [REACT]=⚛️
    [VITE]=⚡
    [TAILWIND]=🌬️
    [APPS]=🗂️
    [WEB]=🌐
    [IOS]=📱
    [GNU]=🦬
    [EC2]=☁️
    [AWS]=☁️
    [AMAZON]=🛒
    )

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
    [PINNED]=󰐃
    [PINNED_OUTLINE]=
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
    [BEER]=
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
    [APPLE]=
    [DOLBY]=󰚳
    [RUST]=
    [VUEJS]=
    [NEXTJS]=
    [REACT]=
    [VITE]=
    [TAILWIND]=󱏿
    [APPS]=󰀻
    [WEB]=󰖟
    [IOS]= #󰀷
    [GNU]=
    [EC2]=󰒋
    [AWS]=󰸏
    [AMAZON]=
    )

if __is_shell_zsh; then
    # shellcheck disable=SC2296
    declare -a ICON_MAP_KEYS=("${(@k)COMMON_ICON_MAP}" "${(@k)EMOJI_ICON_MAP}" "${(@k)NF_ICON_MAP}")
else
    declare -a ICON_MAP_KEYS=("${!COMMON_ICON_MAP[@]}" "${!EMOJI_ICON_MAP[@]}" "${!NF_ICON_MAP[@]}")
fi

# shellcheck disable=SC2207
IFS=$'\n' ICON_MAP_KEYS=($(sort -u <<<"${ICON_MAP_KEYS[*]}"))
unset IFS

function __refresh_icon_map() {
    local use_nerd_fonts="$1"
    unset "ICON_MAP[NOTHING]"
    for key in "${ICON_MAP_KEYS[@]}"; do
        if [[ -n "${COMMON_ICON_MAP[$key]:-}" ]]; then
            ICON_MAP[$key]=${COMMON_ICON_MAP[$key]}
        fi
    done
    if (( use_nerd_fonts )); then
        for key in "${ICON_MAP_KEYS[@]}"; do
            if [[ -n "${NF_ICON_MAP[$key]:-}" ]]; then ICON_MAP[$key]=${NF_ICON_MAP[$key]}; fi
        done
    else
        for key in "${ICON_MAP_KEYS[@]}"; do
            if [[ -n "${EMOJI_ICON_MAP[$key]:-}" ]]; then ICON_MAP[$key]=${EMOJI_ICON_MAP[$key]}; fi
        done
    fi
}

function __print_icon_map() {
    echo "Icon Map:"
    for key in "${ICON_MAP_KEYS[@]}"; do
        echo "  $key => ${ICON_MAP[$key]}"
    done
}

__refresh_icon_map "${EXPECT_NERD_FONTS:-1}"
export ICON_MAP

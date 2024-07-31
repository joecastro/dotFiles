#! /bin/bash

#pragma once

# Suppress warnings on bash 3
declare -A ICON_MAP=([NOTHING]="") > /dev/null 2>&1

function __refresh_icon_map() {
    if __is_shell_old_bash; then
        ICON_MAP=([UNSUPPORTED]="[?]")
        return 0
    fi

    local USE_NERD_FONTS="$1"
    # emojipedia.org
    #Nerdfonts - https://www.nerdfonts.com/cheat-sheet
    if [[ "${USE_NERD_FONTS}" == "0" ]]; then
        ICON_MAP=(
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
        [GIT]=🐙
        [GITHUB]=🐈
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

function __is_ssh_session() {
    [ -n "${SSH_CLIENT}" ] || [ -n "${SSH_TTY}" ] || [ -n "${SSH_CONNECTION}" ]
}

function __is_in_git_repo() {
    git branch > /dev/null 2>&1;
}

function __is_in_git_dir() {
    __is_in_git_repo && git rev-parse --is-inside-git-dir | grep "true" > /dev/null 2>&1;
}

function __is_in_repo() {
    repo --show-toplevel > /dev/null 2>&1
}

function __is_in_repo_root() {
    __is_in_repo && [[ "$(repo --show-toplevel)" == "${PWD}" ]]
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

function __is_shell_bash() {
    [[ -n "$BASH_VERSION" ]]
}

function __is_shell_old_bash() {
    __is_shell_bash && [[ "${BASH_VERSINFO[0]}" -lt 4 ]]
}

function __is_shell_zsh() {
    [[ -n "$ZSH_VERSION" ]]
}

# Shared cuteness

function __print_abbreviated_path() {
    local input_string="$1"
    local result=""
    local part
    while [[ "$input_string" == *"/"* ]]; do
        part="${input_string%%/*}"
        result+="${part:0:1}/"
        input_string="${input_string#*/}"
    done
    result+="${input_string:0:1}"
    echo -n "${result}"
}

if ! __is_shell_old_bash; then

    function __cute_pwd() {
        local is_short=1
        if [[ "$1" == "--short" ]]; then
            is_short=0
        fi

        if __is_in_git_repo; then
            if [[ is_short -eq 0 ]]; then
                echo -n "${PWD##*/}"
                return 0
            fi

            if ! __is_in_git_dir; then
                # If we're in a git repo then show the current directory relative to the root of that repo.
                # These commands wind up spitting out an extra slash, so backspace to remove it on the console.
                # Because this messes with the shell's perception of where the cursor is, make the anchor icon
                # appear like an escape sequence instead of a printed character.
                if __is_shell_zsh; then
                    echo -e "%{${ICON_MAP[COD_PINNED]} %}$(git rev-parse --show-toplevel | xargs basename)/$(git rev-parse --show-prefix)\b"
                else
                    echo -e "${ICON_MAP[COD_PINNED]} $(git rev-parse --show-toplevel | xargs basename)/$(git rev-parse --show-prefix)\b"
                fi
            else
                echo -n "${PWD}"
            fi
            return 0
        fi

        function __cute_pwd_lookup() {
            local ACTIVE_DIR=$1

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
                echo -n "${ICON_MAP[FAE_TREE]}"
                return 0
                ;;
            esac

            if [[ -n "${ANDROID_REPO_BRANCH}" ]]; then
                if [[ "${ACTIVE_DIR##*/}" == "${ANDROID_REPO_BRANCH}" ]]; then
                    echo -n "${ICON_MAP[ANDROID_HEAD]}"
                    return 0
                fi
            fi

            case "${ACTIVE_DIR##*/}" in
            "github")
                echo -n "${ICON_MAP[GITHUB]}"
                return 0
                ;;
            "src" | "source")
                echo -n "${ICON_MAP[COD_SAVE]}"
                return 0
                ;;
            "cloud")
                echo -n "${ICON_MAP[CLOUD]}"
                return 0
                ;;
            "$USER")
                echo -n "${ICON_MAP[ACCOUNT]}"
                return 0
                ;;
            esac

            return 1
        }

        if [[ is_short -ne 0 ]]; then
            # Print the parent directory only if it has a special expansion.
            if [[ "${PWD}" != "/" ]] && __cute_pwd_lookup "$(dirname "${PWD}")"; then
                echo -n "/"
            fi
        fi

        if ! __cute_pwd_lookup "${PWD}"; then
            echo -n "${PWD##*/}"
        fi

        return 0
    }
else
    function __cute_pwd() {
        if [[ "$1" == "--short" ]]; then
            echo -n "${PWD##*/}"
            return 0
        fi

        if [[ "${PWD}" == "/" ]]; then
            echo -n "${PWD}"
            return 0
        fi

        parent_dir="$(dirname "${PWD}")"
        echo -n "${parent_dir##*/}/${PWD##*/}"
    }
fi

function __cute_pwd_short() {
    __cute_pwd --short
}

function __cute_time_prompt() {
    case "$(date +%Z)" in
    UTC)
        echo -n "$(date +'%_H:%Mz')"
        ;;
    *)
        echo -n "$(date +'%_H:%M %Z')"
        ;;
    esac
}

typeset -a CUTE_HEADER_PARTS=()

function __cute_shell_header() {
    if ! [[ "$1" == "--force" ]]; then
        if ! __is_shell_interactive; then
            return 0
        fi
        if [[ "${SHLVL}" != "1" ]]; then
            if ! __is_shell_zsh || ! __z_is_embedded_terminal; then
                return 0
            fi
        fi
    fi

    echo "${CUTE_HEADER_PARTS[@]}" "${ICON_MAP[MD_SNAPCHAT]}"
}

if __is_shell_bash; then
    CUTE_HEADER_PARTS+=("${SHELL}" "${BASH_VERSION}")
fi
if __is_shell_zsh; then
    CUTE_HEADER_PARTS+=("$(zsh --version)")
fi

CUTE_HEADER_PARTS+=("$(uname -smn)")

if __is_shell_old_bash; then
    CUTE_HEADER_PARTS+=("!! Bash ${BASH_VERSINFO[0]} is old o_O !!")
fi

if __is_tool_window; then
    CUTE_HEADER_PARTS+=("tool")
fi

# Shared setup helpers for bash and zsh.

function __do_eza_aliases() {
    # if eza is installed prefer that to ls
    # options aren't the same, but I also need it less often...
    if ! command -v eza &> /dev/null; then
        echo "## Using native ls because missing eza"
        # by default, show slashes, follow symbolic links, colorize
        alias ls='ls -FHG'
    else
        export EZA_STRICT=0
        export EZA_ICONS_AUTO=0
        alias ls='eza -l --group-directories-first'
        # https://github.com/orgs/eza-community/discussions/239#discussioncomment-9834010
        alias kd='eza --group-directories-first'
        alias realls='\ls -FHG'
    fi
}

function __do_iterm2_shell_integration() {
    # If using iTerm2, try for shell integration.
    # iTerm profile switching requires shell_integration to be installed anyways.
    if ! __is_iterm2_terminal; then
        return 0;
    fi

    if __is_shell_zsh; then
        # shellcheck source=/dev/null
        [[ -f "${DOTFILES_CONFIG_ROOT}/iterm2_shell_integration.zsh" ]] && source "${DOTFILES_CONFIG_ROOT}/iterm2_shell_integration.zsh"
    elif __is_shell_bash; then
        # shellcheck source=/dev/null
        [[ -f "${DOTFILES_CONFIG_ROOT}/iterm2_shell_integration.bash" ]] && source "${DOTFILES_CONFIG_ROOT}/iterm2_shell_integration.bash"
    else
        echo "Unknown shell for iTerm2 integration"
        return 1
    fi

    # shellcheck source=/dev/null
    [[ -f "${DOTFILES_CONFIG_ROOT}/iterm2_funcs.sh" ]] && source "${DOTFILES_CONFIG_ROOT}/iterm2_funcs.sh"
}

function __do_vscode_shell_integration() {
    if ! __is_vscode_terminal; then
        return 0
    fi

    if __is_shell_zsh; then
        if command -v code &> /dev/null; then
            # shellcheck disable=SC1090
            source "$(code --locate-shell-integration-path zsh)"
        fi

        # Also, in some contexts .zprofile isn't sourced when started inside the Python debug console.
        # shellcheck disable=SC1090
        source ~/.zprofile
    fi
}

__refresh_icon_map "${EXPECT_NERD_FONTS:-0}"
export ICON_MAP

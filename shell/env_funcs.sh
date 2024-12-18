#! /bin/bash

#pragma once

# Defines __git_ps1

# shellcheck source=/dev/null
source "${DOTFILES_CONFIG_ROOT}/completion/git-prompt.sh"

function _dotTrace() {
    if [[ -n "${TRACE_DOTFILES}" ]]; then
        echo "TRACE $(date +%T): $*"
    fi
}

# Suppress warnings on bash 3
declare -A ICON_MAP=([NOTHING]="") > /dev/null 2>&1

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
    [ARROW_UP_THICK]=⬆️
    [REVIEW]=📝
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
    [ARROW_UP_THICK]=󰁞
    [REVIEW]=
    ) > /dev/null 2>&1

function __is_ssh_session() {
    [ -n "${SSH_CLIENT}" ] || [ -n "${SSH_TTY}" ] || [ -n "${SSH_CONNECTION}" ]
}

function __is_in_git_repo() {
    local ret_for_git_dir=0
    if [[ "$1" == "--git-dir" ]]; then
        ret_for_git_dir=1
    fi

    if error_message=$(git branch 2>&1); then
        if git rev-parse --is-inside-git-dir | grep "true" > /dev/null 2>&1; then
            return ${ret_for_git_dir}
        fi
        return 0
    fi

    if [[ "${error_message}" == *"ot a git repository"* ]]; then
        return 2
    fi

    return 1
}

function __git_is_in_git_dir() {
    __is_in_git_repo --git-dir
    [[ "$?" == "1" ]]
}

function __git_is_detached_head() {
    git status 2> /dev/null | grep "HEAD detached" > /dev/null 2>&1
}

function __git_is_head_on_branch() {
    matching_branch=$(git show-ref --head | grep "$(__git_print_commit_sha)" | grep -o 'refs/remotes/[^ ]*' | head -n 1)
    [[ -n "$matching_branch" ]]
}

function __git_is_nothing_to_commit() {
    git status 2> /dev/null | grep "nothing to commit" > /dev/null 2>&1
}

function __git_is_in_worktree() {
    # git rev-parse --is-inside-work-tree | grep "true" > /dev/null 2>&1
    local root_worktree active_worktree

    root_worktree=$(git worktree list | head -n1 | awk '{print $1;}')
    active_worktree=$(git worktree list | grep "$(git rev-parse --show-toplevel)" | head -n1 | awk '{print $1;}')

    [[ "${root_worktree}" != "${active_worktree}" ]]
}

function __git_print_commit_sha() {
    if ! __is_in_git_repo; then
        echo -n ""
        return 1
    fi

    git rev-parse --short HEAD
}

function __git_print_branch_name() {
    if ! __is_in_git_repo; then
        echo -n ""
        return 1
    fi

    local branch_name
    if ! branch_name=$(git symbolic-ref --short HEAD 2> /dev/null); then
        echo -n "HEAD"
        return 1
    fi

    echo -n "${branch_name}"
}

function __print_git_branch() {
    __is_in_git_repo --git-dir
    local git_repo_result=$?
    if [[ ${git_repo_result} == 2 ]]; then
        echo -n ""
        return 1
    elif [[ ${git_repo_result} == 1 ]]; then
        echo -n "${ICON_MAP[COD_TOOLS]} "
        return 0
    fi

    local branch_display=""
    if __git_is_detached_head; then
        branch_display+="${ICON_MAP[GIT_COMMIT]}"
        #branch_display+="$(__git_print_commit_sha)"
    else
        branch_display+="${ICON_MAP[GIT_BRANCH]}"
        #branch_display+="$(__git_print_branch_name)"
    fi
    branch_display+="$(__git_ps1 "%s")"

    if ! __git_is_nothing_to_commit; then
        branch_display+="*"
    fi

    echo -ne "${branch_display}"
}

function __print_git_branch_short() {
    __is_in_git_repo --git-dir
    local git_repo_result=$?
    if [[ $git_repo_result == 2 ]]; then
        echo -n ""
        return 1
    fi

    if [[ $git_repo_result == 1 ]]; then
        echo -n "${ICON_MAP[COD_TOOLS]}"
        return 0
    fi

    if ! __git_is_detached_head; then
        echo -n "${ICON_MAP[GIT_BRANCH]}"
        return 0
    fi

    if __git_is_head_on_branch; then
        echo -n "${ICON_MAP[GIT_BRANCH]}"
    else
        echo -n "${ICON_MAP[GIT_COMMIT]}"
    fi

    return 0
}

function __print_git_worktree() {
    if ! __is_in_git_repo; then
        echo -n ""
        return 1
    fi

    if ! __git_is_in_worktree; then
        echo -n ""
        return 1
    fi

    local root_worktree active_worktree submodule_worktree
    submodule_worktree=$(git rev-parse --show-superproject-working-tree)
    if [[ "${submodule_worktree}" != "" ]]; then
        echo -n "${ICON_MAP[LEGO]}${submodule_worktree##*/}"
        return 0
    fi

    root_worktree=$(git worktree list | head -n1 | awk '{print $1;}')
    active_worktree=$(git worktree list | grep "$(git rev-parse --show-toplevel)" | head -n1 | awk '{print $1;}')

    echo -n "${ICON_MAP[LEGO]}${root_worktree##*/}:${active_worktree##*/}"
}

function __print_git_pwd() {
    local use_pin_icon=1
    if [[ "$1" == "--no-branch" ]]; then
        use_pin_icon=0
    fi

    __is_in_git_repo --git-dir
    local git_repo_result=$?
    if [[ $git_repo_result == 2 ]]; then
        echo -ne ""
        return 1
    fi

    local anchor_icon="${ICON_MAP[COD_PINNED]}"
    if [[ $use_pin_icon != 0 ]] || [[ $git_repo_result == 1 ]]; then
        anchor_icon="$(__print_git_branch_short)"
    fi

    local color_hint
    color_hint=$(__git_branch_color_hint)
    anchor_icon=$(__echo_colored "${color_hint}" "${anchor_icon}")

    local anchored_path
    if [[ $git_repo_result == 1 ]]; then
        anchored_path=".git${PWD##*.git}"
    else
        # If we're in a git repo then show the current directory relative to the root of that repo.
        # These commands wind up spitting out an extra slash, so backspace to remove it on the console.
        anchored_path="$(echo -ne "$(git rev-parse --show-toplevel | xargs basename)/$(git rev-parse --show-prefix)")"
        anchored_path="${anchored_path%/}"
    fi

    echo -ne "${anchor_icon} ${anchored_path}"
}

function __is_in_repo_root() {
    local candidate_dir="${1:-$PWD}"
    # Hackily relying on an implementation detail...
    # Check _FindRepo() in the repo Python script.
    [[ -f "${candidate_dir}/.repo/repo/main.py" ]]
}

function __is_in_repo() {
    local current_dir
    current_dir=$(readlink -f "$PWD")
    if [[ -n "${CWD_REPO_ROOT}" && "$current_dir" == "$CWD_REPO_ROOT"* ]]; then
        _dotTrace "__is_in_repo Already in repo root"
        return 0
    fi
    _dotTrace "__is_in_repo Checking for repo root"
    while [[ "$current_dir" != "/" ]]; do
        if __is_in_repo_root "$current_dir"; then
            _dotTrace "__is_in_repo Found repo root"
            if [[ "$(repo --show-toplevel)" != "${current_dir}" ]]; then
                echo "BADBAD: ${current_dir}"
            fi

            if [[ "$current_dir" != "$CWD_REPO_ROOT" ]]; then
                local cached_parts
                if cached_parts=$(__cache_get "REPO_INFO_${current_dir}"); then
                    IFS='%' read -r CWD_REPO_ROOT CWD_REPO_MANIFEST_BRANCH CWD_REPO_DEFAULT_REMOTE <<< "$cached_parts"
                    export CWD_REPO_ROOT
                    export CWD_REPO_MANIFEST_BRANCH
                    export CWD_REPO_DEFAULT_REMOTE
                    _dotTrace "__is_in_repo Using cached repo environment variables"
                    return 0
                fi

                CWD_REPO_ROOT="${current_dir}"
                export CWD_REPO_ROOT
                CWD_REPO_MANIFEST_BRANCH=$(repo info -o --outer-manifest -l | grep -i "Manifest branch" | sed 's/^Manifest branch: //')
                export CWD_REPO_MANIFEST_BRANCH
                if command -v xmllint &> /dev/null; then
                    CWD_REPO_DEFAULT_REMOTE=$(xmllint --xpath '//manifest/default/@remote' "${current_dir}/.repo/manifests/default.xml" | sed -n 's/.*remote="\([^"]*\)".*/\1/p')
                else
                    CWD_REPO_DEFAULT_REMOTE="unknown"
                fi
                export CWD_REPO_DEFAULT_REMOTE

                __cache_put "REPO_INFO_${current_dir}" "${CWD_REPO_ROOT}%${CWD_REPO_MANIFEST_BRANCH}%${CWD_REPO_DEFAULT_REMOTE}" 3000
            fi
            _dotTrace "__is_in_repo Updated repo environment variables"
            return 0
        fi
        current_dir="$(dirname "$current_dir")"
    done
    _dotTrace "__is_in_repo Not in repo root"
    unset CWD_REPO_ROOT
    unset CWD_REPO_MANIFEST_BRANCH
    unset CWD_REPO_DEFAULT_REMOTE
    return 1
}

function __print_repo_worktree() {
    if ! __is_in_repo; then
        echo -n ""
        return 0
    fi

    local manifest_branch=${CWD_REPO_MANIFEST_BRANCH}
    local default_remote=${CWD_REPO_DEFAULT_REMOTE}

    local line="${ICON_MAP[ANDROID_BODY]}"

    if [[ "${default_remote}" != "goog" ]]; then
        line+="${default_remote}/"
    fi
    line+="${manifest_branch}"

    __echo_colored "green" "${line}"

    local current_project
    if current_project=$(repo_current_project); then
        local current_branch
        if current_branch=$(repo_current_project_branch); then
            echo -n ":$(repo_current_project_branch_status)${current_branch}"
        else
            __echo_colored "green" ":$(__print_abbreviated_path "${current_project}")"
        fi
    fi
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

function __is_konsole_terminal() {
    # This doesn't work in SSH sessions...
    [[ -n "${KONSOLE_VERSION}" ]]
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

function __has_homebrew() {
    command -v brew > /dev/null
}

function __has_citc() {
    command -v citctools > /dev/null
}

function __cache_available() {
    return 1
}

if __is_shell_zsh; then
    function __cache_available() {
        return 0
    }

    declare -A Z_CACHE=()

    function __cache_put() {
        local key="$1"
        local value="$2"
        local expiration_time="${3:-0}"

        Z_CACHE[${key}]="${value}"
        if [[ ${expiration_time} -gt 0 ]]; then
            Z_CACHE[${key}_expiration]="$(( $(date +%s) + expiration_time ))"
        else
            Z_CACHE[${key}_expiration]=0
        fi
    }

    function __cache_get_expiration() {
        local key="$1"
        local expiration_value
        expiration_value="${Z_CACHE[${key}_expiration]}"
        if [[ -n "${expiration_value}" ]]; then
            echo -n "${expiration_value}"
            return 0
        fi
        return 1
    }

    function __cache_get() {
        local key="$1"

        local cache_expiration
        if ! cache_expiration=$(__cache_get_expiration "${key}"); then
            return 1
        fi

        if [[ "${cache_expiration}" -gt 0 ]]; then
            if [[ "${cache_expiration}" -lt "$(date +%s)" ]]; then
                return 1
            fi
        fi

        if [[ -n "${Z_CACHE["${key}"]}" ]]; then
            echo -n "${Z_CACHE["${key}"]}"
            return 0
        fi

        return 1
    }

    function __cache_clear() {
        if [[ -n "$1" ]]; then
            Z_CACHE[${1}_expiration]=1
        else
            Z_CACHE=()
        fi
    }

# Prevent bash from attempting to interpret invalid zsh syntax.
# shellcheck disable=SC1091
source /dev/stdin <<'EOF'

    function __cache_print() {
        local expires_soon_threshold=1800
        local current_time
        current_time="$(date +%s)"
        local expiration_value
        local suffix
        for key in "${(@k)Z_CACHE}"; do
            if expiration_value=$(__cache_get_expiration "${key}"); then
                if [[ "${expiration_value}" -eq 0 ]]; then
                    suffix=""
                elif [[ "${expiration_value}" -lt "${current_time}" ]]; then
                    suffix=" (expired)"
                else
                    local remaining_time=$((expiration_value - current_time))
                    local remaining_minutes=$((remaining_time / 60))
                    suffix=" (expires in ${remaining_minutes} minutes)"
                fi
                echo "${key}=\"${Z_CACHE[$key]}\"${suffix}"
            fi
        done
    }

    function __cache_save() {
        local cache_file="$1"
        local key
        local value
        for key value in "${(@kv)Z_CACHE}"; do
            echo "${key}=${value}"
        done > "${cache_file}"
    }

    function __cache_load() {
        local cache_file="$1"
        local key
        local value
        while read -r key value; do
            Z_CACHE["${key}"]="${value}"
        done < "${cache_file}"
    }

    function __refresh_icon_map() {
        local USE_NERD_FONTS="$1"
        # emojipedia.org
        #Nerdfonts - https://www.nerdfonts.com/cheat-sheet
        if [[ "${USE_NERD_FONTS}" == "0" ]]; then
            for key val in "${(@kv)NF_ICON_MAP}"; do
                ICON_MAP[$key]=$val
            done
        else
            for key val in "${(@kv)EMOJI_ICON_MAP}"; do
                ICON_MAP[$key]=$val
            done
        fi
    }
EOF
else
    function __cache_put() {
        return 0
    }

    function __cache_get() {
        return 1
    }

    function __cache_clear() {
        return 0
    }

    function __cache_print() {
        return 0
    }

    if __is_shell_old_bash; then
        function __refresh_icon_map() {
            ICON_MAP=([UNSUPPORTED]="[?]")
            return 0
        }
    else
        function __refresh_icon_map() {
            local USE_NERD_FONTS="$1"
            # emojipedia.org
            #Nerdfonts - https://www.nerdfonts.com/cheat-sheet
            if [[ "${USE_NERD_FONTS}" == "0" ]]; then
                for key in "${!NF_ICON_MAP[@]}"; do
                    ICON_MAP[$key]=${NF_ICON_MAP[$key]}
                done
            else
                for key in "${!EMOJI_ICON_MAP[@]}"; do
                    ICON_MAP[$key]=${EMOJI_ICON_MAP[$key]}
                done
            fi
        }
    fi
fi

if __is_shell_zsh; then

    function __is_text_colored() {
        local text="$1"
        [[ "$text" == *"%{"* && "$text" == *"%}"* ]]
    }

    function __echo_colored() {
        local color_name="$1"
        shift
        local text="$*"
        local style=""

        # Check for optional style parameters
        if [[ "$color_name" == "bold" || "$color_name" == "bright" ]]; then
            style="$color_name"
            color_name="$1"
            shift
            text="$*"
        fi

        local color_code
        # Apply style if specified
        if [[ "$style" == "bold" ]]; then
            # shellcheck disable=SC2154
            color_code="%{${fg_bold[${color_name}]}%}"
        elif [[ "$style" == "bright" ]]; then
            # shellcheck disable=SC2154
            color_code="%{${fg_bright[${color_name}]}%}"
        else
            # shellcheck disable=SC2154
            color_code="%{${fg[${color_name}]}%}"
        fi

        if __is_text_colored "$text"; then
            echo -ne "${text}"
            echo "E: Trying to colorize colored text: ${text}" >&2
            return 0
        fi

        # shellcheck disable=SC2154
        echo -ne "%{${color_code}%}${text}%{${reset_color}%}"
    }

else

    function __is_text_colored() {
        local text="$1"

        [[ "$text" == *"\e["* && "$text" == *"m"* ]]
    }

    function __echo_colored() {
        local color_name="$1"
        shift
        local style=""

        # Check for optional style parameters
        if [[ "$color_name" == "bold" || "$color_name" == "bright" ]]; then
            style="$color_name"
            color_name="$1"
            shift
        fi

        local text="$*"

        declare -A color_map=(
            ["black"]="0"
            ["red"]="1"
            ["green"]="2"
            ["yellow"]="3"
            ["blue"]="4"
            ["magenta"]="5"
            ["cyan"]="6"
            ["white"]="7"
        )

        # Default to white if color not found
        local color_code="3${color_map[$color_name]:-7}"

        # Apply style if specified
        if [[ "$style" == "bold" ]]; then
            color_code="1;${color_code}"
        elif [[ "$style" == "bright" ]]; then
            color_code="9${color_map[$color_name]:-7}"
        fi

        if __is_text_colored "$text"; then
            echo -ne "${text}"
            echo "E: Trying to colorize colored text: ${text}" >&2
            return 0
        fi

        echo -ne "\e[${color_code}m${text}\e[0m"
    }

fi

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
    result+="${input_string}"
    echo -n "${result}"
}

function __git_branch_color_hint() {
    if __git_is_nothing_to_commit; then
        echo -ne "green"
    elif __git_is_detached_head; then
        echo -ne "red"
    else
        echo -ne "yellow"
    fi
}

if ! __is_shell_old_bash; then

    function __cute_pwd_lookup() {
        local ACTIVE_DIR=$1

        declare -A KNOWN_DIRS=(
            ["${HOME}"]=${ICON_MAP[COD_HOME]}
            ["${HOME}/Desktop"]=${ICON_MAP[DESKTOP]}
            ["${HOME}/Documents"]=${ICON_MAP[DOCUMENTS]}
            ["${HOME}/Videos"]=${ICON_MAP[VIDEOS]}
            ["${HOME}/Downloads"]=${ICON_MAP[DOWNLOAD]}
            ["${HOME}/Pictures"]=${ICON_MAP[PICTURES]}
            ["${HOME}/Music"]=${ICON_MAP[MUSIC]}
            ["${HOME}/.ssh"]=${ICON_MAP[KEY]}
            ["/"]=${ICON_MAP[FAE_TREE]}
        )

        if __is_on_wsl; then
            KNOWN_DIRS["${WIN_USERPROFILE}"]=${ICON_MAP[WINDOWS]}
        fi

        # These should only match if they're exact.
        if [[ -v KNOWN_DIRS[$ACTIVE_DIR] ]]; then
            echo -n "${KNOWN_DIRS[$ACTIVE_DIR]}"
            return 0
        fi

        if __is_in_repo_root "${ACTIVE_DIR}"; then
            echo -n "${ICON_MAP[ANDROID_HEAD]}"
            return 0
        fi

        declare -A KNOWN_FOLDER_NAMES=(
            ["src"]=${ICON_MAP[COD_SAVE]}
            ["source"]=${ICON_MAP[COD_SAVE]}
            ["github"]=${ICON_MAP[GITHUB]}
            ["cloud"]=${ICON_MAP[CLOUD]}
            ["$USER"]=${ICON_MAP[ACCOUNT]}
        )

        if [[ -v KNOWN_FOLDER_NAMES[${ACTIVE_DIR##*/}] ]]; then
            echo -n "${KNOWN_FOLDER_NAMES[${ACTIVE_DIR##*/}]}"
            return 0
        fi

        return 1
    }

    function __cute_pwd() {
        local is_short=1
        if [[ "$1" == "--short" ]]; then
            is_short=0
        fi

        if [[ $is_short != 0 ]] && __is_in_git_repo; then
            __print_git_pwd ""
            return 0
        fi

        if [[ $is_short != 0 ]]; then
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
        echo -n "$(date -u +'%H:%Mz')"
        ;;
    *)
        echo -n "$(date +'%_H:%M %Z')"
        ;;
    esac
}

typeset -a CUTE_HEADER_PARTS=()

function __cute_shell_header() {
    if ! [[ "$1" != "--force" ]]; then
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
    if [[ "$(which "$0")" == "/bin/bash" ]] || [[ "$(which "$0")" == "/usr/bin/bash" ]]; then
        CUTE_HEADER_PARTS+=("bash")
    else
        CUTE_HEADER_PARTS+=("$0")
    fi

    CUTE_HEADER_PARTS+=("${BASH_VERSINFO[0]}.${BASH_VERSINFO[1]}.${BASH_VERSINFO[2]}")
fi

if __is_shell_zsh; then
    if [[ "${SHELL}" == "/bin/zsh" ]] || [[ "${SHELL}" == "/usr/bin/zsh" ]]; then
        CUTE_HEADER_PARTS+=("zsh")
    else
        CUTE_HEADER_PARTS+=("${SHELL}")
    fi

    CUTE_HEADER_PARTS+=("${ZSH_VERSION}")
fi

CUTE_HEADER_PARTS+=("$(uname -smn)")

if __is_shell_old_bash; then
    CUTE_HEADER_PARTS+=("!! Bash ${BASH_VERSINFO[0]} is old o_O !!")
fi

if __is_tool_window; then
    CUTE_HEADER_PARTS+=("tool")
fi

# Shared setup helpers for bash and zsh.

function ssh() {
    __cache_clear "KONSOLE_PROFILE"
    command ssh "$@"
}

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

    # shellcheck source=SCRIPTDIR/iterm2_funcs.sh
    [[ -f "${DOTFILES_CONFIG_ROOT}/iterm2_funcs.sh" ]] && source "${DOTFILES_CONFIG_ROOT}/iterm2_funcs.sh"
}

function __do_vscode_shell_integration() {
    if __is_on_osx && ! __is_ssh_session && ! command -v code &> /dev/null; then
        echo "## CLI for VSCode is unavailable. Check https://code.visualstudio.com/docs/setup/mac"
    fi

    if ! __is_vscode_terminal; then
        return 0
    fi

    if __is_shell_zsh; then
        if command -v code &> /dev/null; then
            # shellcheck disable=SC1090
            source "$(code --locate-shell-integration-path zsh)"
        fi
    fi
}

_prompt_executing=""
function __konsole_integration_precmd() {
    _dotTrace "__konsole_integration_precmd"

    local ret="$?"
    if [[ "$_prompt_executing" != "0" ]]; then
        _PROMPT_SAVE_PS1="$PS1"
        _PROMPT_SAVE_PS2="$PS2"
        # shellcheck disable=SC2025
        PS1=$'%{\e]133;P;k=i\a%}'$PS1$'%{\e]133;B\a\e]122;> \a%}'
        PS2=$'%{\e]133;P;k=s\a%}'$PS2$'%{\e]133;B\a%}'
    fi
    if [[ "$_prompt_executing" != "" ]]; then
        echo -ne "\e]133;D;$ret;aid=$$\a"
    fi
    echo -ne "\e]133;A;cl=m;aid=$$\a"
    _prompt_executing=0
}

function __konsole_integration_preexec() {
    _dotTrace "__konsole_integration_preexec"

    PS1="$_PROMPT_SAVE_PS1"
    PS2="$_PROMPT_SAVE_PS2"
    echo -ne "\e]133;C;\a"
    _prompt_executing=1
}

function toggle_konsole_semantic_integration() {
    _dotTrace "toggle_konsole_semantic_integration"

    function is_konsole_semantic_integration_active() {
        echo "${preexec_functions}" | grep -q __konsole_integration_preexec
    }

    function add_konsole_semantic_integration() {
        if ! is_konsole_semantic_integration_active; then
            preexec_functions+=("__konsole_integration_preexec")
            precmd_functions+=("__konsole_integration_precmd")
        fi
    }

    function remove_konsole_semantic_integration() {
        if is_konsole_semantic_integration_active; then
            preexec_functions=("${preexec_functions:#__konsole_integration_preexec}")
            precmd_functions=("${precmd_functions:#__konsole_integration_precmd}")
        fi
    }

    if [[ "$1" == "0" ]]; then
        remove_konsole_semantic_integration
        return 0
    elif [[ "$1" == "1" ]]; then
        add_konsole_semantic_integration
        return 0
    fi

    if is_konsole_semantic_integration_active; then
        remove_konsole_semantic_integration
    else
        add_konsole_semantic_integration
    fi
}

function __update_konsole_profile() {
    _dotTrace "__update_konsole_profile"

    local active_dynamic_prompt_style
    active_dynamic_prompt_style=$(__cache_get "ACTIVE_DYNAMIC_PROMPT_STYLE")

    local arg=""
    if [[ "$active_dynamic_prompt_style" == "Repo" ]]; then
        arg="Colors=Android Colors"
    else
        arg="Colors=$(hostname) Colors"
    fi
    if [[ $(__cache_get "KONSOLE_PROFILE") == "${arg}" ]]; then
        _dotTrace "__update_konsole_profile - already set"
        return
    fi

    _dotTrace "__update_konsole_profile - setting default profile"
    echo -ne "\e]50;${arg}\a"
    __cache_put "KONSOLE_PROFILE" "${arg}" 30000
    _dotTrace "__update_konsole_profile - done"
}

function __do_konsole_shell_integration() {
    source "${DOTFILES_CONFIG_ROOT}/konsole_color_funcs.sh"

    if __is_shell_zsh; then
        toggle_konsole_semantic_integration 1

        precmd_functions+=(__update_konsole_profile)
    fi
}

__refresh_icon_map "${EXPECT_NERD_FONTS:-0}"
export ICON_MAP
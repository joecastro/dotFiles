#! /bin/bash

#pragma once

# Defines __git_ps1

# shellcheck source=/dev/null
source "${DOTFILES_CONFIG_ROOT}/completion/git-prompt.sh"

if [[ ":$PATH:" != *":${DOTFILES_CONFIG_ROOT}/bin:"* ]]; then
    PATH="${DOTFILES_CONFIG_ROOT}/bin:${PATH}"
fi

if [[ ":$PATH:" != *":${HOME}/.local/bin:"* ]]; then
    PATH="${HOME}/.local/bin:${PATH}"
fi

# Declare a new stack (unconditionally)
function _stack_declare() {
    local name=$1
    eval "$name=''"
}

# Declare stack only if not already defined
function _stack_safe_declare() {
    local name=$1
    if ! eval "[[ \${$name+set} ]]" 2>/dev/null; then
        eval "$name=''"
    fi
}

# Push a value onto the stack
function _stack_push() {
    local name=$1 value=$2
    local stack
    eval 'stack="$'"$name"'"'
    stack="${stack}"$'\n'"$value"
    eval "$name=\"\$stack\""
}

# Pop the top value from the stack and print it
function _stack_pop() {
    local name=$1 stack top rest
    eval 'stack="$'"$name"'"'
    [ -z "$stack" ] && return 1

    top="${stack##*$'\n'}"
    rest="${stack%$'\n'*}"
    [ "$top" = "$stack" ] && rest=''

    eval "$name=\"\$rest\""
}

# Peek at the top value
function _stack_top() {
    local name=$1 stack
    eval 'stack="$'"$name"'"'
    [ -z "$stack" ] && return 1
    printf '%s\n' "${stack##*$'\n'}"
}

# Get number of elements in the stack
function _stack_size() {
    local name=$1 stack
    eval 'stack="$'"$name"'"'
    [ -z "$stack" ] && echo 0 && return
    printf '%s\n' "$stack" | awk 'END { print NR }'
}


# Check if the stack is empty (returns 0 if empty)
function _stack_is_empty() {
    local name=$1 stack
    eval 'stack="$'"$name"'"'
    [ -z "$stack" ]
}

# Clear the stack
function _stack_clear() {
    local name=$1
    eval "$name=''"
}

# Print stack elements joined by a given separator
function _stack_print() {
    local name=$1 sep=$2 stack first=1
    eval 'stack="$'"$name"'"'
    [ -z "$stack" ] && return

    while IFS= read -r line; do
        if [ $first -eq 1 ]; then
            printf '%s' "$line"
            first=0
        else
            printf '%s%s' "$sep" "$line"
        fi
    done <<< "$stack"
    echo
}

function _dotTrace() {
    if [[ -n "${TRACE_DOTFILES}" ]]; then
        local indent_depth=""
        for ((i=1; i < $(_stack_size TRACE_DOTFILES_STACK); i++)); do
            indent_depth+="  "
        done
        echo "${indent_depth}TRACE $(date +%T.%3N): $*" >&2
    fi
}

function _dotTrace_enter() {
    if [[ -n "${TRACE_DOTFILES}" ]]; then
        _stack_safe_declare TRACE_DOTFILES_STACK

        local indent_depth=""
        for ((i=1; i < $(_stack_size TRACE_DOTFILES_STACK); i++)); do
            indent_depth+="  "
        done

        local func_name=""
        local func_args=""
        if [[ -n "${ZSH_VERSION}" ]]; then
            # shellcheck disable=SC2154
            func_name="${funcstack[1]}"
            # Zsh: $argv contains the arguments to the current function, so use $argv for $func_args
            # shellcheck disable=SC2124,SC2154
            func_args="${argv[@]}"
        else
            func_name="${FUNCNAME[1]}"
            # Bash: BASH_ARGV contains the arguments to the current function, but in reverse order
            # $BASH_ARGC[1] is the number of arguments to the calling function
            local argc=${BASH_ARGC[1]:-0}
            if (( argc > 0 )); then
                for ((i=argc-1; i>=0; i--)); do
                    func_args="${BASH_ARGV[i]} ${func_args}"
                done
                func_args="${func_args%% }"
            fi
        fi
        _stack_push TRACE_DOTFILES_STACK "$func_name"

        echo "${indent_depth}TRACE_ENTER $(date +%T.%3N): $(_stack_top TRACE_DOTFILES_STACK)($func_args)" >&2
    fi
}

function _dotTrace_exit() {
    if [[ -n "${TRACE_DOTFILES}" ]]; then
        # echo "TRACE_EXIT $(date +%T.%3N): $(_stack_top TRACE_DOTFILES_STACK)" >&2
        _stack_pop TRACE_DOTFILES_STACK
    fi
}

function toggle_trace_dotfiles() {
    if [[ -n "${TRACE_DOTFILES}" ]]; then
        unset TRACE_DOTFILES
    else
        export TRACE_DOTFILES=1
    fi
}

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
    [APPLE_FINDER]=󰀶
    ) > /dev/null 2>&1

if [[ -n "${ZSH_VERSION}" ]]; then
    # shellcheck disable=SC2296
    declare -a ICON_MAP_KEYS=("${(@k)EMOJI_ICON_MAP}")
else
    declare -a ICON_MAP_KEYS=("${!EMOJI_ICON_MAP[@]}")
fi

function __refresh_icon_map() {
    local USE_NERD_FONTS="$1"

    if __is_shell_old_bash; then
        return 1
    fi

    unset "ICON_MAP[NOTHING]"

    # emojipedia.org
    #Nerdfonts - https://www.nerdfonts.com/cheat-sheet
    if [[ "${USE_NERD_FONTS}" == "0" ]]; then
        for key in "${ICON_MAP_KEYS[@]}"; do
            ICON_MAP[$key]=${NF_ICON_MAP[$key]}
        done
    else
        for key in "${ICON_MAP_KEYS[@]}"; do
            ICON_MAP[$key]=${EMOJI_ICON_MAP[$key]}
        done
    fi
}

function __print_icon_map() {
    echo "Icon Map:"
    for key in "${ICON_MAP_KEYS[@]}"; do
        echo "  $key => ${ICON_MAP[$key]}"
    done
}

function __is_ssh_session() {
    [ -n "${SSH_CLIENT}" ] || [ -n "${SSH_TTY}" ] || [ -n "${SSH_CONNECTION}" ]
}

function __is_in_git_repo() {
    local ret_for_git_dir=0
    if [[ "$1" == "--git-dir-ok" ]]; then
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
    __is_in_git_repo --git-dir-ok
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

function __git_compare_upstream_changes() {
    # Fetch remote changes (use --quiet to suppress output)
    # git fetch --quiet

    local upstream
    upstream=$(git rev-parse --abbrev-ref --symbolic-full-name "@{u}" 2>/dev/null)
    if [[ -z "$upstream" ]]; then
        return 1
    fi

    local ahead behind
    read -r ahead behind < <(git rev-list --left-right --count "$upstream"...HEAD 2>/dev/null | awk '{print $2, $1}')

    local result=0
    if [[ "$ahead" -gt 0 ]]; then
        result=$((result + 2))
    fi
    if [[ "$behind" -gt 0 ]]; then
        result=$((result + 4))
    fi
    return $result
}

function __git_has_unpushed_changes() {
    __git_compare_upstream_changes
    local result=$?
    return $(( (result & 2) == 0 ))
}

function __git_has_remote_changes() {
    __git_compare_upstream_changes
    local result=$?
    return $(( (result & 4) == 0 ))
}

function __git_is_on_default_branch() {
    local default_branch
    default_branch=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|^refs/remotes/origin/||')
    if [[ -z "${default_branch}" ]]; then
        return 1
    fi

    local current_branch
    current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
    [[ "${current_branch}" == "${default_branch}" ]]
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
    local colorize=0
    if [[ "$1" == "--no-color" ]]; then
        colorize=1
    fi

    __is_in_git_repo --git-dir-ok
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

    if [[ ${colorize} -eq 0 ]]; then
        local color_hint
        color_hint=$(__git_branch_color_hint)
        branch_display=$(__echo_colored "${color_hint}" "${branch_display}")
    fi

    echo -ne "${branch_display}"
}

function __print_git_branch_icon() {
    __is_in_git_repo --git-dir-ok
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
    _dotTrace_enter
    local working_pwd=""

    __is_in_git_repo --git-dir-ok
    local git_repo_result=$?
    if [[ $git_repo_result == 2 ]]; then
        _dotTrace "Not at all in a git repo"
        echo -ne ""
        _dotTrace_exit
        return 1
    fi

    __git_is_on_default_branch
    local is_branch_shorthand_eligible=$?

    local color_hint has_remote_changes has_unpushed_changes
    color_hint=$(__git_branch_color_hint)
    has_remote_changes=$(__git_has_remote_changes; echo $?)
    has_unpushed_changes=$(__git_has_unpushed_changes; echo $?)

    if [[ $has_remote_changes -eq 0 && $has_unpushed_changes -eq 0 ]]; then
        _dotTrace "both remote and unpushed changes detected"
        is_branch_shorthand_eligible=1
        working_pwd+="${ICON_MAP[ARROW_UPDOWN_THICK]}"
    elif [[ $has_remote_changes -eq 0 ]]; then
        _dotTrace "remote changes detected"
        is_branch_shorthand_eligible=1
        working_pwd+="${ICON_MAP[ARROW_DOWN_THICK]}"
    elif [[ $has_unpushed_changes -eq 0 ]]; then
        _dotTrace "unpushed changes detected"
        is_branch_shorthand_eligible=1
        working_pwd+="${ICON_MAP[ARROW_UP_THICK]}"
    fi

    working_pwd+="$(__print_git_branch_icon)"

    if [[ ${is_branch_shorthand_eligible} == 0 ]]; then
        _dotTrace "on default branch - omitting branch name"
    else
        _dotTrace "not on default branch - using __git_ps1 for branch display"
        working_pwd+="$(__git_ps1 "%s")"
    fi

    if ! __git_is_nothing_to_commit; then
        _dotTrace "uncommitted changes detected"
        working_pwd+="*"
    fi

    working_pwd=$(__echo_colored "${color_hint}" "${working_pwd}")

    working_pwd+=" ${ICON_MAP[COD_PINNED]}"

    _dotTrace "branch prefix before anchored path: ${working_pwd}"

    local anchored_path
    if [[ $git_repo_result == 1 ]]; then
        anchored_path=".git${PWD##*.git}"
    else
        # If we're in a git repo then show the current directory relative to the root of that repo.
        # These commands wind up spitting out an extra slash, so backspace to remove it on the console.
        anchored_path="$(echo -ne "$(git rev-parse --show-toplevel | xargs basename)/$(git rev-parse --show-prefix)")"
        anchored_path="${anchored_path%/}"
        anchored_path="$(__print_abbreviated_path "${anchored_path}" 0)"
    fi

    echo -ne "${working_pwd}${anchored_path}"
    _dotTrace_exit
}

function __repo_is_in_repo_root() {
    local candidate_dir="${1:-$PWD}"
    # Hackily relying on an implementation detail...
    # Check _FindRepo() in the repo Python script.
    [[ -f "${candidate_dir}/.repo/repo/main.py" ]]
}

function __repo_find_root() {
    local current_dir="$1"
    while [[ "$current_dir" != "/" ]]; do
        if __repo_is_in_repo_root "$current_dir"; then
            echo -n "$current_dir"
            return 0
        fi
        current_dir="$(dirname "$current_dir")"
    done
    return 1
}

function __is_in_repo() {
    _dotTrace_enter
    local current_dir
    current_dir=$(readlink -f "$PWD")
    if [[ -n "${CWD_REPO_ROOT}" && "$current_dir" == "$CWD_REPO_ROOT"* ]]; then
        _dotTrace_exit
        return 0
    fi

    if ! CWD_REPO_ROOT=$(__repo_find_root "$current_dir"); then
        unset CWD_REPO_ROOT
        unset CWD_REPO_MANIFEST_BRANCH
        unset CWD_REPO_DEFAULT_REMOTE
        _dotTrace_exit
        return 1
    fi

    local cached_parts
    if cached_parts=$(__cache_get "REPO_INFO_${CWD_REPO_ROOT}"); then
        IFS='%' read -r CWD_REPO_MANIFEST_BRANCH CWD_REPO_DEFAULT_REMOTE <<< "$cached_parts"
        export CWD_REPO_ROOT
        export CWD_REPO_MANIFEST_BRANCH
        export CWD_REPO_DEFAULT_REMOTE
        _dotTrace "Using cached repo environment variables"
        _dotTrace_exit
        return 0
    fi

    _dotTrace "updating repo environment variables"

    if command -v xmllint &> /dev/null; then
        local xpath_response
        xpath_response=$(xmllint --xpath '//manifest/default' "${current_dir}/.repo/manifests/default.xml")
        CWD_REPO_MANIFEST_BRANCH=$(echo "${xpath_response}" | sed -n 's/.*revision="\([^"]*\)".*/\1/p')
        CWD_REPO_DEFAULT_REMOTE=$(echo "${xpath_response}" | sed -n 's/.*remote="\([^"]*\)".*/\1/p')
    else
        CWD_REPO_MANIFEST_BRANCH=$(repo info -o --outer-manifest -l | grep -i "Manifest branch" | sed 's/^Manifest branch: //')
        CWD_REPO_DEFAULT_REMOTE="unknown"
    fi

    __cache_put "REPO_INFO_${CWD_REPO_ROOT}" "${CWD_REPO_MANIFEST_BRANCH}%${CWD_REPO_DEFAULT_REMOTE}" 3000
    _dotTrace "updated repo environment variables"

    export CWD_REPO_ROOT
    export CWD_REPO_MANIFEST_BRANCH
    export CWD_REPO_DEFAULT_REMOTE

    _dotTrace_exit
    return 0
}

function __print_repo_worktree() {
    _dotTrace_enter
    _dotTrace ""
    if ! __is_in_repo; then
        _dotTrace_exit
        echo -n ""
        return 0
    fi

    local line="${ICON_MAP[ANDROID_BODY]}"

    if [[ "${CWD_REPO_DEFAULT_REMOTE}" != "goog" ]]; then
        line+="${CWD_REPO_DEFAULT_REMOTE}/"
    fi
    line+="${CWD_REPO_MANIFEST_BRANCH}"

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
    _dotTrace "done"
    _dotTrace_exit
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

function __is_in_vimruntime() {
    [ -n "${VIMRUNTIME}" ]
}

function __is_in_python_venv() {
    [ -n "${VIRTUAL_ENV}" ]
}

function __auto_activate_venv() {
    # If I am no longer in the same directory hierarchy as the venv that was last activated, deactivate.
    if __is_in_python_venv; then
        local P_DIR="$(dirname "$VIRTUAL_ENV")"
        if [[ "$PWD"/ != "${P_DIR}"/* ]] && command -v deactivate &> /dev/null; then
            echo "${ICON_MAP[PYTHON]} Deactivating venv for ${P_DIR}"
            deactivate
        fi
    fi

    # If I enter a directory with a .venv and I am already activated with another one, let me know but don't activate.
    if [[ -d ./.venv ]]; then
        if ! __is_in_python_venv; then
            source ./.venv/bin/activate
            echo "${ICON_MAP[PYTHON]} Activating venv with $(python --version) for $PWD/.venv"
        # else: CONSIDER: test "$PWD" -ef "$VIRTUAL_ENV" && "🐍 Avoiding implicit activation of .venv environment because $VIRTUAL_ENV is already active"
        fi
    fi
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

function __is_in_wsl_windows_drive() {
    __is_on_wsl && __is_in_windows_drive
}

function __is_in_wsl_linux_drive() {
    __is_on_wsl && ! __is_in_windows_drive
}

function __is_on_macos() {
    [[ "$(uname -s)" == "Darwin" ]]
}

function __is_on_windows() {
    [[ "$(uname -s)" = "MINGW64_NT"* ]] || [[ "$(uname -s)" = "MSYS_NT"* ]];
}

function __is_on_unexpected_windows() {
    [[ "$(uname -s)" = "MINGW32_NT"* ]]
}

function __is_on_linux() {
    [[ "$(uname -s)" = "Linux"* ]];
}

function __print_linux_distro() {
    if [[ -f /etc/lsb-release ]]; then
        . /etc/lsb-release
        echo -n "${DISTRIB_ID}"
    else
        echo -n "Unknown Linux distribution"
    fi
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

function __is_ghostty_terminal() {
    [[ "${TERM}" == "xterm-ghostty" ]]
}

function __is_tool_window() {
    [[ -n "${TOOL_WINDOW}" ]];
}

function __is_shell_bash() {
    [[ -n "${BASH_VERSION}" ]]
}

function __is_shell_old_bash() {
    __is_shell_bash && [[ "${BASH_VERSINFO[0]}" -lt 4 ]]
}

function __is_shell_zsh() {
    [[ -n "${ZSH_VERSION}" ]]
}

function __is_homebrew_bin() {
    local bin_path="$1"
    [[ $bin_path == ${HOMEBREW_PREFIX:-/opt/homebrew}/bin/* ]]
}

function __has_citc() {
    command -v citctools > /dev/null
}

if __is_shell_old_bash; then
    function __cache_available() {
        return 1
    }

    function __cache_put() {
        return 1
    }

    function __cache_get_expiration() {
        return 1
    }

    function __cache_get() {
        return 1
    }

    function __cache_clear() {
        return 1
    }

else
    declare -A Z_CACHE=()

    function __cache_available() {
        return 0
    }

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

        if [[ -n "${Z_CACHE[${key}]}" ]]; then
            echo -n "${Z_CACHE[${key}]}"
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
fi

if __is_shell_zsh; then
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
EOF
else
    function __cache_print() {
        return 0
    }
fi

function __is_icon_map_initialized() {
    [[ -z "${ICON_MAP[NOTHING]}" ]]
}

# Don't use ICON_MAP before this point.
__refresh_icon_map "${EXPECT_NERD_FONTS:-0}"
export ICON_MAP

function __is_style_name() {
    local style="$1"
    [[ "$style" == "bold" || "$style" == "bright" ]]
}

if __is_shell_zsh; then

    function __is_text_colored() {
        local text="$1"
        [[ "$text" == *"%{"* && "$text" == *"%}"* ]]
    }

    function __echo_colored() {
        local color_name="$1"
        shift
        local style=""

        # Check for optional style parameters
        if __is_style_name "$color_name"; then
            style="$color_name"
            color_name="$1"
            shift
        fi

        local text="$*"

        local color_code
        # Apply style if specified
        if [[ "$style" == "bold" ]]; then
            # shellcheck disable=SC2154
            color_code="${fg_bold[${color_name}]}"
        elif [[ "$style" == "bright" ]]; then
            # shellcheck disable=SC2154
            color_code="${fg_bright[${color_name}]}"
        else
            # shellcheck disable=SC2154
            color_code="${fg[${color_name}]}"
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
        if __is_style_name "$color_name"; then
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
    local expand_prefix="${2:-1}"
    local result=""
    local part
    while [[ "$input_string" == *"/"* ]]; do
        part="${input_string%%/*}"
        if [[ $expand_prefix -eq 0 ]]; then
            result+="$part/"
        else
            result+="${part:0:1}/"
        fi
        expand_prefix=1
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

        case "${ACTIVE_DIR}" in
        "${HOME}")
            echo -n "${ICON_MAP[COD_HOME]}"
            return 0
            ;;
        "${HOME}/Desktop")
            echo -n "${ICON_MAP[DESKTOP]}"
            return 0
            ;;
        "${HOME}/Documents")
            echo -n "${ICON_MAP[DOCUMENTS]}"
            return 0
            ;;
        "${HOME}/Videos")
            echo -n "${ICON_MAP[VIDEOS]}"
            return 0
            ;;
        "${HOME}/Downloads")
            echo -n "${ICON_MAP[DOWNLOAD]}"
            return 0
            ;;
        "${HOME}/Pictures")
            echo -n "${ICON_MAP[PICTURES]}"
            return 0
            ;;
        "${HOME}/Music")
            echo -n "${ICON_MAP[MUSIC]}"
            return 0
            ;;
        "${HOME}/.ssh")
            echo -n "${ICON_MAP[KEY]}"
            return 0
            ;;
        "/")
            echo -n "${ICON_MAP[FAE_TREE]}"
            return 0
            ;;
        esac

        if __is_on_wsl && test "${ACTIVE_DIR}" = "${WIN_USERPROFILE}"; then
            echo -n "${ICON_MAP[HOME_FOLDER]}"
            return 0
        fi

        if __repo_is_in_repo_root "${ACTIVE_DIR}"; then
            echo -n "${ICON_MAP[ANDROID_HEAD]}"
            return 0
        fi

        case "${ACTIVE_DIR##*/}" in
        "src")
            echo -n "${ICON_MAP[COD_SAVE]}"
            return 0
            ;;
        "source")
            echo -n "${ICON_MAP[COD_SAVE]}"
            return 0
            ;;
        "github")
            echo -n "${ICON_MAP[GITHUB]}"
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

    function __cute_pwd() {
        _dotTrace_enter
        _dotTrace "args: \"$1\""
        local is_short=1
        if [[ "$1" == "--short" ]]; then
            is_short=0
        fi

        if [[ $is_short != 0 ]] && __is_in_git_repo; then
            __print_git_pwd
            _dotTrace_exit
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

        _dotTrace "done"
        _dotTrace_exit
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

function __cute_host() {
    uname -n
}

function __cute_kernel() {
    echo -n "$(uname -s)"

    if __is_on_wsl; then
        echo -n "${ICON_MAP[WINDOWS]}"
    fi
}

function __cute_shell_path() {
    # alternatively: readlink /proc/$$/exe 2>/dev/null || lsof -p $$ | awk '/txt/{print $9}'
    local cute_shell_path="${0#-}"
    # Zsh rewrites $0 when sourcing and in function calls. Bash does not.
    if [[ -n "${ZSH_ARGZERO}" ]]; then
        cute_shell_path="${ZSH_ARGZERO#-}"
    fi

    cute_shell_path="$(which "${cute_shell_path}")"
    if [[ "${cute_shell_path}" == "$(which "$(basename "${cute_shell_path}")")" ]]; then
        cute_shell_path="$(basename "${cute_shell_path}")"
    fi

    echo -n "${cute_shell_path}"
}

function __cute_shell_version() {
    local cute_shell_version=""
    if __is_shell_bash; then
        cute_shell_version="${BASH_VERSINFO[0]}.${BASH_VERSINFO[1]}.${BASH_VERSINFO[2]}"
    elif __is_shell_zsh; then
        cute_shell_version="${ZSH_VERSION}"
    else
        cute_shell_version="<unknown>"
    fi

    echo -n "${cute_shell_version}"
}

# "key" -> (test_function ICON)
typeset -a VSCODE_TERMINAL_ID=("__is_vscode_terminal" "MD_MICROSOFT_VISUAL_STUDIO_CODE")
typeset -a EMBEDDED_TERMINAL_ID_FUNCS=( \
    VSCODE_TERMINAL_ID )

function __is_embedded_terminal() {
    __embedded_terminal_info --noshow
}

function __embedded_terminal_info() {
    local ID_FUNC ICON arr
    for value in "${EMBEDDED_TERMINAL_ID_FUNCS[@]}"; do
        eval "arr=(\"\${${value}[@]}\")"
        ID_FUNC="${arr[@]:0:1}"
        ICON="${ICON_MAP[${arr[@]:1:1}]}"
        if eval "${ID_FUNC}"; then
            if [[ "$1" != "--noshow" ]]; then
                echo -n "${ICON}"
            fi
            return 0
        fi
    done
    return 1
}

function __effective_distribution() {
    if __is_on_wsl; then
        echo "WSL"
        return 0
    elif __is_on_macos; then
        echo "MACOS"
        return 0
    elif __is_on_windows; then
        echo "WINDOWS"
        return 0
    elif __is_on_linux; then
        echo "$(__print_linux_distro)"
    elif __is_on_unexpected_windows; then
        echo "Unexpected Win32 environment"
    else
        echo "Unhandled"
    fi
    return 1
}

# "key" -> (test_function ICON ICON_COLOR)
# typeset -a GIT_VIRTUALENV_ID=("__is_in_git_repo" "ICON_MAP[GIT]" "yellow")
typeset -a TMUX_VIRTUALENV_ID=("__is_in_tmux" "TMUX" "white")
typeset -a VIM_VIRTUALENV_ID=("__is_in_vimruntime" "VIM" "green")
typeset -a PYTHON_VIRTUALENV_ID=("__is_in_python_venv" "PYTHON" "blue")
typeset -a WSL_WINDOWS_VIRTUALENV_ID=("__is_in_wsl_windows_drive" "WINDOWS" "blue")
typeset -a WSL_LINUX_VIRTUALENV_ID=("__is_in_wsl_linux_drive" "LINUX_PENGUIN" "blue")

typeset -a VIRTUALENV_ID_FUNCS=( \
    TMUX_VIRTUALENV_ID \
    VIM_VIRTUALENV_ID \
    PYTHON_VIRTUALENV_ID \
    WSL_WINDOWS_VIRTUALENV_ID \
    WSL_LINUX_VIRTUALENV_ID)

function __virtualenv_info() {
    local suffix="${1:-}"
    local has_virtualenv=1
    for value in "${VIRTUALENV_ID_FUNCS[@]}"; do
        eval "arr=(\"\${${value}[@]}\")"
        ID_FUNC="${arr[@]:0:1}"
        ICON="${ICON_MAP[${arr[@]:1:1}]}"
        ICON_COLOR="${arr[@]:2:1}"
        if eval "${ID_FUNC}"; then
            __echo_colored "${ICON_COLOR}" "${ICON}"
            has_virtualenv=0
        fi
    done
    if [[ "${has_virtualenv}" == "0" ]]; then
        echo -n "${suffix}"
    fi
    return ${has_virtualenv}
}

declare -a CUTE_HEADER_PARTS=() > /dev/null 2>&1

function __cute_shell_header() {
    _dotTrace_enter
    if [[ "$1" != "--force" ]]; then
        if ! __is_shell_interactive; then
            _dotTrace_exit
            return 0
        fi
        if [[ "${SHLVL}" -gt 1 ]]; then
            if __is_embedded_terminal; then
                _dotTrace_exit
                return 0
            fi
        fi
    fi

    if [[ "${SHLVL}" -gt 1 ]]; then
        for ((i = 2; i <= SHLVL; i++)); do
            echo -n "|"
        done
        echo -n " "
    fi

    echo "$(__cute_shell_path)" "$(__cute_shell_version)" "${CUTE_HEADER_PARTS[@]}" "${ICON_MAP[MD_SNAPCHAT]}"
    _dotTrace_exit
}

if __is_shell_interactive; then
    CUTE_HEADER_PARTS+=("$(__cute_kernel)")
    CUTE_HEADER_PARTS+=("$(__cute_host)")
    CUTE_HEADER_PARTS+=("$(uname -m)")

    if ! __is_shell_old_bash; then
        if __is_tool_window; then
            CUTE_HEADER_PARTS+=("${ICON_MAP[TOOLS]}")
        fi
    else
        CUTE_HEADER_PARTS+=("!! Bash ${BASH_VERSINFO[0]} is old o_O !!")
    fi

    CUTE_HEADER_PARTS+=("distro:$(__effective_distribution)")
    if __is_embedded_terminal; then
        CUTE_HEADER_PARTS+=("embedded:$(__embedded_terminal_info)")
    fi
fi

# Shared setup helpers for bash and zsh.

function ssh() {
    __cache_clear "KONSOLE_PROFILE"
    command ssh "$@"
}

function screen() {
    echo "Don't use screen"
    return 1
}

function __do_eza_aliases() {
    # if eza is installed prefer that to ls
    # options aren't the same, but I also need it less often...
    if ! command -v eza &> /dev/null; then
        local eza_warning="!! eza not found !!"
        # shellcheck disable=SC2076
        if [[ ! " ${CUTE_HEADER_PARTS[*]} " =~ " ${eza_warning} " ]]; then
            CUTE_HEADER_PARTS+=("${eza_warning}")
        fi
        # echo "## Using native ls because missing eza"
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
    _dotTrace_enter
    # If using iTerm2, try for shell integration.
    # iTerm profile switching requires shell_integration to be installed anyways.
    if ! __is_iterm2_terminal; then
        _dotTrace_exit
        return 0;
    fi

    if __is_shell_zsh; then
        # shellcheck source=/dev/null
        [[ -f "${DOTFILES_CONFIG_ROOT}/iterm2_shell_integration.zsh" ]] && source "${DOTFILES_CONFIG_ROOT}/iterm2_shell_integration.zsh"
    elif __is_shell_bash; then
        # Disable extdebug because it causes issues with iTerm shell integration
        shopt -u extdebug

        # shellcheck source=/dev/null
        [[ -f "${DOTFILES_CONFIG_ROOT}/iterm2_shell_integration.bash" ]] && source "${DOTFILES_CONFIG_ROOT}/iterm2_shell_integration.bash"
    else
        echo "Unknown shell for iTerm2 integration"
        _dotTrace_exit
        return 1
    fi

    # shellcheck source=SCRIPTDIR/iterm2_funcs.sh
    [[ -f "${DOTFILES_CONFIG_ROOT}/iterm2_funcs.sh" ]] && source "${DOTFILES_CONFIG_ROOT}/iterm2_funcs.sh"
    _dotTrace_exit
}

function __do_vscode_shell_integration() {
    _dotTrace_enter
    if __is_on_macos && ! __is_ssh_session && ! command -v code &> /dev/null; then
        local vscode_warning="!! VSCode CLI unavailable. Check https://code.visualstudio.com/docs/setup/mac !!"
        # shellcheck disable=SC2076
        if [[ ! " ${CUTE_HEADER_PARTS[*]} " =~ " ${vscode_warning} " ]]; then
            CUTE_HEADER_PARTS+=("${vscode_warning}")
        fi
    fi

    if ! __is_vscode_terminal; then
        _dotTrace_exit
        return 0
    fi

    if __is_shell_zsh; then
        if command -v code &> /dev/null; then
            # shellcheck disable=SC1090
            source "$(code --locate-shell-integration-path zsh)"
        fi
    fi
    _dotTrace_exit
}

_prompt_executing=""
function __konsole_integration_precmd() {
    _dotTrace_enter
    _dotTrace ""
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
    _dotTrace_exit
}

function __konsole_integration_preexec() {
    _dotTrace_enter
    _dotTrace ""
    PS1="$_PROMPT_SAVE_PS1"
    PS2="$_PROMPT_SAVE_PS2"
    echo -ne "\e]133;C;\a"
    _prompt_executing=1
    _dotTrace_exit
}

function toggle_konsole_semantic_integration() {
    _dotTrace_enter

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

    local do_enable_integration
    if [[ "$1" == "0" ]]; then
        _dotTrace "Removing Konsole semantic integration because of explicit argument"
        do_enable_integration=1
    elif [[ "$1" == "1" ]]; then
        _dotTrace "Adding Konsole semantic integration because of explicit argument"
        do_enable_integration=0
    else
        _dotTrace "Toggling Konsole semantic integration - current state: $(is_konsole_semantic_integration_active)"
        if is_konsole_semantic_integration_active; then
            do_enable_integration=1
        else
            do_enable_integration=0
        fi
    fi

    if [[ ${do_enable_integration} -eq 1 ]]; then
        _dotTrace "Removing Konsole semantic integration"
        remove_konsole_semantic_integration
    else
        _dotTrace "Adding Konsole semantic integration"
        add_konsole_semantic_integration
    fi
    _dotTrace_exit
}

function __update_konsole_profile() {
    _dotTrace_enter
    local active_dynamic_prompt_style
    active_dynamic_prompt_style=$(__cache_get "ACTIVE_DYNAMIC_PROMPT_STYLE")

    local arg=""
    if [[ "$active_dynamic_prompt_style" == "Repo" ]]; then
        arg="Colors=Android Colors"
    else
        arg="Colors=$(hostname) Colors"
    fi
    if [[ $(__cache_get "KONSOLE_PROFILE") == "${arg}" ]]; then
        _dotTrace "already set"
        _dotTrace_exit
        return
    fi

    _dotTrace "setting konsole profile"
    echo -ne "\e]50;${arg}\a"
    __cache_put "KONSOLE_PROFILE" "${arg}" 30000
    _dotTrace_exit
}

function __do_konsole_shell_integration() {
    _dotTrace_enter
    source "${DOTFILES_CONFIG_ROOT}/konsole_color_funcs.sh"

    if __is_shell_zsh; then
        toggle_konsole_semantic_integration 1

        # precmd_functions+=(__update_konsole_profile)
    fi
    _dotTrace_exit
}


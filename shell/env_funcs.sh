#! /bin/bash

#pragma once

#pragma requires platform.sh
#pragma requires cache.sh
#pragma requires icons.sh
#pragma requires git_funcs.sh
#pragma wants completion/git-prompt.sh
#pragma wants konsole_funcs.sh

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

function __is_ssh_session() {
    [ -n "${SSH_CLIENT}" ] || [ -n "${SSH_TTY}" ] || [ -n "${SSH_CONNECTION}" ]
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
        if [[ $expand_prefix -eq 0 || ${#part} -le 3 ]]; then
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



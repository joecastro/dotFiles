#! /usr/bin/env bash

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


## Stack implementation (portable bash/zsh): newline-delimited string
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
        if [[ -z "$stack" ]]; then
            stack="$value"
        else
            stack="${stack}"$'\n'"$value"
        fi
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
        if [ -z "$stack" ]; then
            echo 0
            return
        fi
        local -i n=0
        while IFS= read -r _; do
            ((n++))
        done <<< "$stack"
        printf '%d\n' "$n"
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
            # In zsh, $funcstack[1] is the current function; the caller is [2]
            # shellcheck disable=SC2154
            func_name="${funcstack[2]:-<toplevel>}"
            # Prefer explicitly forwarded args (from caller using: _dotTrace_enter "$@")
            if (( $# > 0 )); then
                func_args="$*"
            else
                func_args=""
            fi
        else
            func_name="${FUNCNAME[1]}"
            # Prefer explicitly forwarded args
            if (( $# > 0 )); then
                func_args="$*"
            else
                # Bash: BASH_ARGV contains the arguments to the current function, but in reverse order
                # $BASH_ARGC[1] is the number of arguments to the calling function
                local -i argc=${BASH_ARGC[1]:-0}
                if (( argc > 0 )); then
                    for ((i=argc-1; i>=0; i--)); do
                        func_args="${BASH_ARGV[i]} ${func_args}"
                    done
                    func_args="${func_args%% }"
                fi
            fi
        fi
        _stack_push TRACE_DOTFILES_STACK "$func_name"

        echo "${indent_depth}TRACE_ENTER $(date +%T.%3N): $(_stack_top TRACE_DOTFILES_STACK)($func_args)" >&2
    fi
}

function _dotTrace_exit() {
    # Capture caller's last exit code immediately
    local -i exit_status=${1:-$?}
    if [[ -n "${TRACE_DOTFILES}" ]]; then
        local indent_depth=""
        for ((i=1; i < $(_stack_size TRACE_DOTFILES_STACK); i++)); do
            indent_depth+="  "
        done
        local current="$(_stack_top TRACE_DOTFILES_STACK)"
        echo "${indent_depth}TRACE_EXIT  $(date +%T.%3N): ${current} -> status=${exit_status}" >&2
        _stack_pop TRACE_DOTFILES_STACK
    fi
    return ${exit_status}
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
            printf '%s' "$current_dir"
            return 0
        fi
        current_dir="$(dirname "$current_dir")"
    done
    return 1
}

function __is_in_repo() {
    _dotTrace_enter "$@"
    local current_dir
    # Use physical path resolution that works in both bash and zsh (portable on macOS/Linux)
    current_dir=$(pwd -P)
    if [[ -n "${CWD_REPO_ROOT}" && "$current_dir" == "$CWD_REPO_ROOT"* ]]; then
        _dotTrace_exit 0
        return
    fi

    if ! CWD_REPO_ROOT=$(__repo_find_root "$current_dir"); then
        unset CWD_REPO_ROOT
        unset CWD_REPO_MANIFEST_BRANCH
        unset CWD_REPO_DEFAULT_REMOTE
        _dotTrace_exit 1
        return
    fi

    local cached_parts
    if cached_parts=$(__cache_get "REPO_INFO_${CWD_REPO_ROOT}"); then
        IFS='%' read -r CWD_REPO_MANIFEST_BRANCH CWD_REPO_DEFAULT_REMOTE <<< "$cached_parts"
        export CWD_REPO_ROOT
        export CWD_REPO_MANIFEST_BRANCH
        export CWD_REPO_DEFAULT_REMOTE
        _dotTrace "Using cached repo environment variables"
        _dotTrace_exit 0
        return
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

    _dotTrace_exit 0
}

function __print_repo_worktree() {
    _dotTrace_enter "$@"
    if ! __is_in_repo; then
        _dotTrace_exit 0
        return
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
            printf '%s' ":$(repo_current_project_branch_status)${current_branch}"
        else
            __echo_colored "green" ":$(__print_abbreviated_path "${current_project}")"
        fi
    fi
    _dotTrace_exit 0
}

function __node_is_in_project_root() {
    local candidate_dir="${1:-$PWD}"
    [[ -f "${candidate_dir}/package.json" ]]
}

function __node_find_root() {
    local current_dir="$1"
    while [[ "$current_dir" != "/" ]]; do
        if __node_is_in_project_root "$current_dir"; then
            printf '%s' "$current_dir"
            return 0
        fi
        current_dir="$(dirname "$current_dir")"
    done
    return 1
}

function __is_in_node_project() {
    _dotTrace_enter "$@"
    local current_dir
    # Use physical path resolution that works in both bash and zsh (portable on macOS/Linux)
    current_dir=$(pwd -P)
    if [[ -n "${CWD_NODE_ROOT}" && "$current_dir" == "$CWD_NODE_ROOT"* ]]; then
        _dotTrace_exit 0
        return
    fi

    if ! CWD_NODE_ROOT=$(__node_find_root "$current_dir"); then
        unset CWD_NODE_ROOT
        _dotTrace_exit 1
        return
    fi

    _dotTrace "updating node environment variables"
    export CWD_NODE_ROOT

    _dotTrace_exit 0
}

function __is_in_initialized_node_project() {
    __is_in_node_project && [ -d "${CWD_NODE_ROOT}/node_modules" ]
}

function __is_in_uninitialized_node_project() {
    __is_in_node_project && [ ! -d "${CWD_NODE_ROOT}/node_modules" ]
}

function __is_in_stale_node_project() {
    if ! __is_in_initialized_node_project; then
        return 1
    fi

    if npm ls --depth=0 >/dev/null 2>&1; then
        return 1
    else
        return 0
    fi
}

function __is_in_synchronized_node_project() {
    __is_in_node_project && ! __is_in_uninitialized_node_project && ! __is_in_stale_node_project
}

# Check node_modules existence & freshness at the project root
# - Reports if node_modules is missing
# - Warns if the dependency tree has problems (unmet/invalid)
# - Lists outdated top-level deps (or says they’re current)
function __print_node_modules_status() {
    if ! __is_in_node_project; then
        echo "Not inside a Node.js project."
        return 1
    fi

    echo "Project root: $CWD_NODE_ROOT"
    if __is_in_initialized_node_project; then
        echo "node_modules: present"
    else
        echo "node_modules: MISSING (run: npm install or npm ci)"
        return 1
    fi

    if __is_in_stale_node_project; then
        echo "Dependency tree: PROBLEMS DETECTED (unmet/peer issues)."
    else
        echo "Dependency tree: OK"
        return 0
    fi

    # Check for outdated top-level deps; parse JSON so we don’t rely on exit codes
    local out
    out="$(npm outdated --depth=0 --json 2>/dev/null || true)"
    if [ -z "$out" ] || [ "$out" = "{}" ]; then
        echo "Outdated check: all top-level dependencies are CURRENT."
    else
        echo "Outdated check: some dependencies are OUTDATED:"
        # Pretty-print a small table (name current wanted latest)
        echo "$out" | node -e '
        const data = JSON.parse(require("fs").readFileSync(0,"utf8"));
        const rows = Object.entries(data).map(([name, v]) =>
            [name, v.current||"", v.wanted||"", v.latest||""]);
        const w=[0,0,0,0];
        rows.forEach(r=>r.forEach((c,i)=>w[i]=Math.max(w[i],String(c).length)));
        const pr=(r)=>r.map((c,i)=>String(c).padEnd(w[i])).join("  ");
        console.log(pr(["package","current","wanted","latest"]));
        console.log(pr(w.map(x=>"-".repeat(x))));
        rows.forEach(r=>console.log(pr(r)));
        '
    fi
}

function __auto_activate_venv() {
    # If I am no longer in the same directory hierarchy as the venv that was last activated, deactivate.
    if __is_in_python_venv; then
        local P_DIR
        P_DIR="$(dirname "$VIRTUAL_ENV")"
        if [[ "$PWD"/ != "${P_DIR}"/* ]] && command -v deactivate &> /dev/null; then
            echo "${ICON_MAP[PYTHON]} Deactivating venv for ${P_DIR}"
            deactivate
        fi
    fi

    # If I enter a directory with a .venv and I am already activated with another one, let me know but don't activate.
    if [[ -d ./.venv ]]; then
        if ! __is_in_python_venv; then
            # shellcheck disable=SC1091
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
            printf '%s' "${text}"
            printf 'E: Trying to colorize colored text: %s\n' "${text}" >&2
            return 0
        fi

        # shellcheck disable=SC2154
        printf '%s' "%{${color_code}%}${text}%{${reset_color}%}"
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

        # Map color name to base code (avoid associative arrays for bash 3.x compatibility)
        local base="37" # default white
        case "$color_name" in
            black)   base="30" ;;
            red)     base="31" ;;
            green)   base="32" ;;
            yellow)  base="33" ;;
            blue)    base="34" ;;
            magenta) base="35" ;;
            cyan)    base="36" ;;
            white)   base="37" ;;
        esac

        local color_code="$base"
        # Apply style if specified
        if [[ "$style" == "bold" ]]; then
            color_code="1;${base}"
        elif [[ "$style" == "bright" ]]; then
            # Bright variant of the base color
            case "$base" in
                30) color_code=90 ;;
                31) color_code=91 ;;
                32) color_code=92 ;;
                33) color_code=93 ;;
                34) color_code=94 ;;
                35) color_code=95 ;;
                36) color_code=96 ;;
                37) color_code=97 ;;
            esac
        fi

        if __is_text_colored "$text"; then
            printf '%s' "${text}"
            printf 'E: Trying to colorize colored text: %s\n' "${text}" >&2
            return 0
        fi

        printf '\e[%sm%s\e[0m' "$color_code" "$text"
    }

fi

# Shared cuteness

# Always-ANSI color helper for non-prompt output (works in bash and zsh)
function __echo_colored_stdout() {
    local color_name="$1"
    shift
    local style=""
    if __is_style_name "$color_name"; then
        style="$color_name"
        color_name="$1"
        shift
    fi
    local text="$*"
    local base="37"  # default white
    case "$color_name" in
        black) base="30" ;;
        red) base="31" ;;
        green) base="32" ;;
        yellow) base="33" ;;
        blue) base="34" ;;
        magenta) base="35" ;;
        cyan) base="36" ;;
        white) base="37" ;;
    esac
    local code="$base"
    if [[ "$style" == "bold" ]]; then
        code="1;${base}"
    elif [[ "$style" == "bright" ]]; then
        case "$base" in
            30) code=90 ;;
            31) code=91 ;;
            32) code=92 ;;
            33) code=93 ;;
            34) code=94 ;;
            35) code=95 ;;
            36) code=96 ;;
            37) code=97 ;;
        esac
    fi
    printf '\e[%sm%s\e[0m' "$code" "$text"
}

function __print_abbreviated_path() {
    local input_string="$1"
    local -i expand_prefix=${2:-1}
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
    printf '%s' "${result}"
}



if ! __is_shell_old_bash; then

    function __cute_pwd_lookup() {
        local ACTIVE_DIR=$1

        case "${ACTIVE_DIR}" in
        "${HOME}")
            printf '%s' "${ICON_MAP[COD_HOME]}"
            return 0
            ;;
        "${HOME}/Desktop")
            printf '%s' "${ICON_MAP[DESKTOP]}"
            return 0
            ;;
        "${HOME}/Documents")
            printf '%s' "${ICON_MAP[DOCUMENTS]}"
            return 0
            ;;
        "${HOME}/Videos")
            printf '%s' "${ICON_MAP[VIDEOS]}"
            return 0
            ;;
        "${HOME}/Downloads")
            printf '%s' "${ICON_MAP[DOWNLOAD]}"
            return 0
            ;;
        "${HOME}/Pictures")
            printf '%s' "${ICON_MAP[PICTURES]}"
            return 0
            ;;
        "${HOME}/Music")
            printf '%s' "${ICON_MAP[MUSIC]}"
            return 0
            ;;
        "${HOME}/.ssh")
            printf '%s' "${ICON_MAP[KEY]}"
            return 0
            ;;
        "/")
            printf '%s' "${ICON_MAP[FAE_TREE]}"
            return 0
            ;;
        esac

        if __is_on_wsl && test "${ACTIVE_DIR}" = "${WIN_USERPROFILE}"; then
            printf '%s' "${ICON_MAP[HOME_FOLDER]}"
            return 0
        fi

        if __repo_is_in_repo_root "${ACTIVE_DIR}"; then
            printf '%s' "${ICON_MAP[ANDROID_HEAD]}"
            return 0
        fi

        case "${ACTIVE_DIR##*/}" in
        "src")
            printf '%s' "${ICON_MAP[COD_SAVE]}"
            return 0
            ;;
        "source")
            printf '%s' "${ICON_MAP[COD_SAVE]}"
            return 0
            ;;
        "github")
            printf '%s' "${ICON_MAP[GITHUB]}"
            return 0
            ;;
        "cloud")
            printf '%s' "${ICON_MAP[CLOUD]}"
            return 0
            ;;
        "$USER")
            printf '%s' "${ICON_MAP[ACCOUNT]}"
            return 0
            ;;
        esac

        return 1
    }

    function __cute_pwd() {
        _dotTrace_enter "$@"
        # rely on _dotTrace_enter to report args if forwarded
        local is_short=1
        if [[ "$1" == "--short" ]]; then
            is_short=0
        fi

        if [[ $is_short != 0 ]] && __git_is_in_repo; then
            __print_git_pwd
            _dotTrace_exit 0
            return
        fi

        if [[ $is_short != 0 ]]; then
            # Print the parent directory only if it has a special expansion.
            if [[ "${PWD}" != "/" ]] && __cute_pwd_lookup "$(dirname "${PWD}")"; then
                printf '/'
            fi
        fi

        if ! __cute_pwd_lookup "${PWD}"; then
            printf '%s' "${PWD##*/}"
        fi

        _dotTrace "done"
        _dotTrace_exit 0
        return
    }
else
    function __cute_pwd() {
        if [[ "$1" == "--short" ]]; then
            printf '%s' "${PWD##*/}"
            return 0
        fi

        if [[ "${PWD}" == "/" ]]; then
            printf '%s' "${PWD}"
            return 0
        fi

        parent_dir="$(dirname "${PWD}")"
        printf '%s' "${parent_dir##*/}/${PWD##*/}"
    }
fi

function __cute_pwd_short() {
    __cute_pwd --short
}

function __cute_time_prompt() {
    case "$(date +%Z)" in
    UTC)
        printf '%s' "$(date -u +'%H:%Mz')"
        ;;
    *)
        printf '%s' "$(date +'%_H:%M %Z')"
        ;;
    esac
}

function __cute_host() {
    uname -n
}

function __cute_kernel() {
    printf '%s' "$(uname -s)"

    if __is_on_wsl; then
        printf '%s' "${ICON_MAP[WINDOWS]}"
    fi
}

function __cute_shell_path() {
    # alternatively: readlink /proc/$$/exe 2>/dev/null || lsof -p $$ | awk '/txt/{print $9}'
    local cute_shell_path="${0#-}"
    # Zsh rewrites $0 when sourcing and in function calls. Bash does not.
    if [[ -n "${ZSH_ARGZERO}" ]]; then
        cute_shell_path="${ZSH_ARGZERO#-}"
    fi

    cute_shell_path="$(command -v -- "${cute_shell_path}")"
    if [[ "${cute_shell_path}" == "$(command -v -- "$(basename "${cute_shell_path}")")" ]]; then
        cute_shell_path="$(basename "${cute_shell_path}")"
    fi

    printf '%s' "${cute_shell_path}"
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

    printf '%s' "${cute_shell_version}"
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
        if [[ -n ${ZSH_VERSION:-} ]]; then
            eval "arr=(\"\${${value}[@]}\")"
        else
            eval "arr=(\"\${$value[@]}\")"
        fi
        ID_FUNC="${arr[@]:0:1}"
        ICON="${ICON_MAP[${arr[@]:1:1}]}"
        if eval "${ID_FUNC}"; then
            if [[ "$1" != "--noshow" ]]; then
                printf '%s' "${ICON}"
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
        __print_linux_distro
    elif __is_on_unexpected_windows; then
        echo "Unexpected Win32 environment"
    else
        echo "Unhandled"
    fi
    return 1
}

# "key" -> (test_function ICON ICON_COLOR)
# typeset -a GIT_VIRTUALENV_ID=("__git_is_in_repo" "ICON_MAP[GIT]" "yellow")
typeset -a TMUX_VIRTUALENV_ID=("__is_in_tmux" "TMUX" "white")
typeset -a VIM_VIRTUALENV_ID=("__is_in_vimruntime" "VIM" "green")
typeset -a PYTHON_VIRTUALENV_ID=("__is_in_python_venv" "PYTHON" "blue")
typeset -a WSL_WINDOWS_VIRTUALENV_ID=("__is_in_wsl_windows_drive" "WINDOWS" "blue")
typeset -a WSL_LINUX_VIRTUALENV_ID=("__is_in_wsl_linux_drive" "LINUX_PENGUIN" "blue")
typeset -a NODE_VIRTUALENV_UNINITIALIZED_ID=("__is_in_uninitialized_node_project" "NODEJS" "yellow")
typeset -a NODE_VIRTUALENV_STALE_ID=("__is_in_stale_node_project" "NODEJS" "red")
typeset -a NODE_VIRTUALENV_SYNCED_ID=("__is_in_synchronized_node_project" "NODEJS" "blue")

typeset -a VIRTUALENV_ID_FUNCS=( \
    TMUX_VIRTUALENV_ID \
    VIM_VIRTUALENV_ID \
    PYTHON_VIRTUALENV_ID \
    WSL_WINDOWS_VIRTUALENV_ID \
    WSL_LINUX_VIRTUALENV_ID \
    NODE_VIRTUALENV_UNINITIALIZED_ID \
    NODE_VIRTUALENV_STALE_ID \
    NODE_VIRTUALENV_SYNCED_ID)

function __virtualenv_info() {
    local suffix="${1:-}"
    local -i has_virtualenv=1
    for value in "${VIRTUALENV_ID_FUNCS[@]}"; do
        if [[ -n ${ZSH_VERSION:-} ]]; then
            eval "arr=(\"\${${value}[@]}\")"
        else
            eval "arr=(\"\${$value[@]}\")"
        fi
        ID_FUNC="${arr[@]:0:1}"
        ICON="${ICON_MAP[${arr[@]:1:1}]}"
        ICON_COLOR="${arr[@]:2:1}"
        if eval "${ID_FUNC}"; then
            __echo_colored "${ICON_COLOR}" "${ICON}"
            has_virtualenv=0
        fi
    done
    if [[ "${has_virtualenv}" == "0" ]]; then
        printf '%s' "${suffix}"
    fi
    return ${has_virtualenv}
}

# Robust array declaration for both bash and zsh
if [[ -n "${ZSH_VERSION:-}" ]]; then
    typeset -ga CUTE_HEADER_PARTS
else
    declare -a CUTE_HEADER_PARTS
fi

function __cute_startup_time() {
    # Prefer high-resolution timing when available (bash 5+/zsh: EPOCHREALTIME)
    local secs="" formatted=""

    if [[ -n "${EPOCHREALTIME:-}" && -n "${DOTFILES_INIT_EPOCHREALTIME_START:-}" ]]; then
        local now="${EPOCHREALTIME}"
        # Calculate elapsed seconds to millisecond precision
        secs="$(awk -v n="$now" -v s="$DOTFILES_INIT_EPOCHREALTIME_START" 'BEGIN { printf "%.3f", (n - s) }')"
        formatted="${secs}s"
    elif [[ -n "${SECONDS:-}" ]]; then
        secs="${SECONDS}"
        formatted="${SECONDS}s"
    else
        # As a final fallback, skip reporting
            return 1
        fi

    # Prepare display with clock icon
    local display_str
    display_str="${ICON_MAP[CLOCK]} ${formatted}"

    # Highlight slow startups (> 3.000 seconds) in red
    local -i is_slow=0
    if [[ -n "${secs}" ]]; then
        if [[ "$secs" == *.* ]]; then
            # float compare via awk
            is_slow="$(awk -v d="$secs" 'BEGIN { if (d > 3.0) print 1; else print 0 }')"
        else
            # integer seconds
            if (( secs > 3 )); then is_slow="1"; fi
        fi
    fi

    if (( is_slow == 1 )); then
        __echo_colored_stdout red "${display_str}"
    else
        printf '%s' "${display_str}"
    fi
}

function __cute_shell_header() {
    _dotTrace_enter "$@"
    if [[ "$1" != "--force" ]]; then
        if ! __is_shell_interactive; then
            _dotTrace_exit 0
            return
        fi
        if (( SHLVL > 1 )); then
            if __is_embedded_terminal; then
                _dotTrace_exit 0
                return
            fi
        fi
    fi

    if (( SHLVL > 1 )); then
        for ((i = 2; i <= SHLVL; i++)); do
            printf '|'
        done
        printf ' '
    fi

    local startup_part
    startup_part="$(__cute_startup_time)"
    if [[ -n "$startup_part" ]]; then
        echo "$(__cute_shell_path)" "$(__cute_shell_version)" "${CUTE_HEADER_PARTS[@]}" "$startup_part" "${ICON_MAP[MD_SNAPCHAT]}"
    else
        echo "$(__cute_shell_path)" "$(__cute_shell_version)" "${CUTE_HEADER_PARTS[@]}" "${ICON_MAP[MD_SNAPCHAT]}"
    fi
    _dotTrace_exit 0
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
        # Use a POSIX-valid function name; alias hyphenated names to it
        function kd_tree() {
            local arg="${1:-}"
            local -i level=3

            if [[ -n "$arg" && "$arg" =~ ^[0-9]+$ ]]; then
                # If the token is both a number and an existing directory, prefer level (warn user).
                if [[ -d "$arg" ]]; then
                    echo "Warning: ambiguous argument '$arg' (both number and directory); using as level." >&2
                fi
                level="$arg"
                shift
            fi

            # Pass remaining args (which may include a directory or flags) to eza
            eza --tree --level="$level" --group-directories-first "$@"
        }
        alias kt='kd_tree'
        alias realls='\ls -FHG'
    fi
}

function __do_iterm2_shell_integration() {
    _dotTrace_enter "$@"
    # If using iTerm2, try for shell integration.
    # iTerm profile switching requires shell_integration to be installed anyways.
    if ! __is_iterm2_terminal; then
        _dotTrace_exit 0
        return
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
        _dotTrace_exit 1
        return
    fi

    # shellcheck source=SCRIPTDIR/iterm2_funcs.sh
    [[ -f "${DOTFILES_CONFIG_ROOT}/iterm2_funcs.sh" ]] && source "${DOTFILES_CONFIG_ROOT}/iterm2_funcs.sh"
    _dotTrace_exit 0
}

function __do_vscode_shell_integration() {
    _dotTrace_enter "$@"
    if __is_on_macos && ! __is_ssh_session && ! command -v code &> /dev/null; then
        local vscode_warning="!! VSCode CLI unavailable. Check https://code.visualstudio.com/docs/setup/mac !!"
        # shellcheck disable=SC2076
        if [[ ! " ${CUTE_HEADER_PARTS[*]} " =~ " ${vscode_warning} " ]]; then
            CUTE_HEADER_PARTS+=("${vscode_warning}")
        fi
    fi

    if ! __is_vscode_terminal; then
        _dotTrace_exit 0
        return
    fi

    if __is_shell_zsh; then
        if command -v code &> /dev/null; then
            # shellcheck disable=SC1090
            source "$(code --locate-shell-integration-path zsh)"
        fi
    fi
    _dotTrace_exit 0
}

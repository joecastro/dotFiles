#! /usr/bin/env bash
# shellcheck disable=SC2034
#pragma once

#pragma requires debug.sh
_dotTrace "Loading env_funcs.sh"

#pragma requires stack.sh
#pragma requires platform.sh
#pragma requires cache.sh
#pragma requires icons.sh
#pragma requires git_funcs.sh
#pragma wants completion/git-prompt.sh
#pragma wants konsole_funcs.sh
#pragma wants iterm2_funcs.sh

if [[ ":$PATH:" != *":${DOTFILES_CONFIG_ROOT}/bin:"* ]]; then
    PATH="${DOTFILES_CONFIG_ROOT}/bin:${PATH}"
fi

if [[ ":$PATH:" != *":${HOME}/.local/bin:"* ]]; then
    PATH="${HOME}/.local/bin:${PATH}"
fi

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
    _dotTrace_enter
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
    # Returns 0 if the directory contains a package.json and is NOT inside a node_modules tree
    local candidate_dir="${1:-$PWD}"
    # Ignore any path segments under node_modules to avoid treating installed packages as projects
    case "/$candidate_dir/" in
        */node_modules/*) return 1 ;;
    esac
    [[ -f "${candidate_dir}/package.json" ]]
}

function __node_find_root() {
    # Finds the nearest Node project root (package.json) from current_dir upward.
    # Optimization: if already within CWD_NODE_ROOT, we do not scan above it.
    local current_dir="$1"
    local boundary=""

    if [[ -n "${CWD_NODE_ROOT}" && "$current_dir" == "$CWD_NODE_ROOT"* ]]; then
        boundary="$CWD_NODE_ROOT"
    fi

    while :; do
        if __node_is_in_project_root "$current_dir"; then
            printf '%s' "$current_dir"
            return 0
        fi
        if [[ -n "$boundary" && "$current_dir" == "$boundary" ]]; then
            printf '%s' "$boundary"
            return 0
        fi
        # Stop at filesystem root
        [[ "$current_dir" == "/" ]] && break
        # Move to parent directory (portable and fast)
        local parent="${current_dir%/*}"
        [[ -z "$parent" ]] && parent="/"
        # If no progress, abort
        [[ "$parent" == "$current_dir" ]] && break
        current_dir="$parent"
    done
    return 1
}

# Maintain a stack of discovered Node project roots to support nested projects.
# The active Node root is always the top of the stack.
function __node_sync_root_stack() {
    local current_dir="$1"
    _stack_safe_declare NODE_ROOT_STACK

    # Resolve the nearest Node root from the current directory (if any)
    local new_root
    if ! new_root=$(__node_find_root "$current_dir"); then
        # Not in any Node project: clear state
        _stack_clear NODE_ROOT_STACK
        unset CWD_NODE_ROOT
        return 1
    fi

    # Helper: check if A is an ancestor of or equal to B (directory-wise)
    local top
    top=$(_stack_top NODE_ROOT_STACK 2>/dev/null || true)

    if [[ -z "$top" ]]; then
        _stack_push NODE_ROOT_STACK "$new_root"
    elif [[ "$new_root" == "$top" ]]; then
        : # unchanged
    elif [[ "$new_root" == "$top"/* ]]; then
        # We moved into a deeper nested Node project
        _stack_push NODE_ROOT_STACK "$new_root"
    else
        # We moved out of the current top; pop until an ancestor matches, then push if needed
        while ! _stack_is_empty NODE_ROOT_STACK; do
            top=$(_stack_top NODE_ROOT_STACK)
            if [[ "$new_root" == "$top" || "$new_root" == "$top"/* ]]; then
                break
            fi
            _stack_pop NODE_ROOT_STACK >/dev/null
        done

        top=$(_stack_top NODE_ROOT_STACK 2>/dev/null || true)
        if [[ -z "$top" ]]; then
            _stack_push NODE_ROOT_STACK "$new_root"
        elif [[ "$new_root" != "$top" ]]; then
            # new_root is a descendant of the current top (or sibling after pops)
            _stack_push NODE_ROOT_STACK "$new_root"
        fi
    fi

    # shellcheck disable=SC2155
    export CWD_NODE_ROOT=$(_stack_top NODE_ROOT_STACK)
    return 0
}

# Debug helper: print the Node root stack and active root
function __print_node_root_stack() {
    _stack_safe_declare NODE_ROOT_STACK
    if _stack_is_empty NODE_ROOT_STACK; then
        echo "Node root stack: <empty>"
        echo "Active root: ${CWD_NODE_ROOT:-<unset>}"
        return 1
    fi

    echo "Node root stack (bottom -> top):"
    _stack_print NODE_ROOT_STACK " -> "
    echo "Active root: ${CWD_NODE_ROOT:-<unset>}"
}

function __is_in_node_project() {
    _dotTrace_enter
    local current_dir
    current_dir=$(pwd -P)
    local prev_root="${CWD_NODE_ROOT:-}"
    # Sync the Node root stack so nested projects are detected
    if ! __node_sync_root_stack "$current_dir"; then
        _dotTrace_exit 1
        return
    fi

    if [[ "$prev_root" != "$CWD_NODE_ROOT" ]]; then
        _dotTrace "updating node environment variables"
    fi

    _dotTrace_exit 0
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

        case "$(echo "${ACTIVE_DIR##*/}" | tr '[:upper:]' '[:lower:]')" in
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
        "$(echo "$USER" | tr '[:upper:]' '[:lower:]')")
            printf '%s' "${ICON_MAP[ACCOUNT]}"
            return 0
            ;;
        "apps")
            printf '%s' "${ICON_MAP[APPS]}"
            return 0
            ;;
        "www" | "web" | "website" | "websites")
            printf '%s' "${ICON_MAP[WEB]}"
            return 0
            ;;
        "ios")
            printf '%s' "${ICON_MAP[IOS]}"
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

        if [[ $is_short != 0 ]]; then
            # Print the parent directory only if it has a special expansion.
            if [[ "${PWD}" != "/" ]] && __cute_pwd_lookup "$(dirname "${PWD}")"; then
                printf '/'
            fi
        fi

        if ! __cute_pwd_lookup "${PWD}"; then
            printf '%s' "${PWD##*/}"
        fi

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


function __print_abbreviated_path() {
    _dotTrace_enter "$@"
    local input_string="$1"
    local -i expand_prefix=${2:-1}
    local result=""
    local part
    local lookup
    while [[ "$input_string" == *"/"* ]]; do
        part="${input_string%%/*}"
        lookup="$(__cute_pwd_lookup "$part")"
        if [[ -n "$lookup" ]]; then
            result+="$lookup/"
        elif [[ $expand_prefix -eq 0 || ${#part} -le 3 ]]; then
            result+="$part/"
        else
            result+="${part:0:1}/"
        fi
        expand_prefix=1
        input_string="${input_string#*/}"
    done
    lookup="$(__cute_pwd_lookup "$input_string")"
    if [[ -n "$lookup" ]]; then
        result+="$lookup"
    else
        result+="$input_string"
    fi

    printf '%s' "${result}"
    _dotTrace_exit 0
}

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
            # shellcheck disable=SC1087
            eval "arr=(\"\${$value[@]}\")"
        fi
        # shellcheck disable=SC2124
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

typeset -a VIRTUALENV_ID_FUNCS=( \
    TMUX_VIRTUALENV_ID \
    VIM_VIRTUALENV_ID \
    PYTHON_VIRTUALENV_ID )

function __virtualenv_info() {
    _dotTrace_enter "$@"
    local suffix="${1:-}"
    local -i has_virtualenv=1
    for value in "${VIRTUALENV_ID_FUNCS[@]}"; do
        _dotTrace "Checking virtualenv: $value"
        if [[ -n ${ZSH_VERSION:-} ]]; then
            eval "arr=(\"\${${value}[@]}\")"
        else
            # shellcheck disable=SC1087
            eval "arr=(\"\${$value[@]}\")"
        fi
        # shellcheck disable=SC2124
        ID_FUNC="${arr[@]:0:1}"
        ICON="${ICON_MAP[${arr[@]:1:1}]}"
        # shellcheck disable=SC2124
        ICON_COLOR="${arr[@]:2:1}"
        if eval "${ID_FUNC}"; then
            _dotTrace "Found virtualenv with $ID_FUNC"
            __echo_colored "${ICON_COLOR}" "${ICON}"
            has_virtualenv=0
        fi
    done
    if [[ "${has_virtualenv}" == "0" ]]; then
        printf '%s' "${suffix}"
    fi

    _dotTrace_exit ${has_virtualenv}
    return
}

# Robust array declaration for both bash and zsh
if [[ -n "${ZSH_VERSION:-}" ]]; then
    typeset -ga CUTE_HEADER_PARTS
    typeset -ga CUTE_HEADER_WARNINGS
else
    declare -a CUTE_HEADER_PARTS
    declare -a CUTE_HEADER_WARNINGS
fi

# Utilities to add info/warnings to the cute header consistently
function __cute_shell_header_add_info() {
    local msg="${1:-}"
    [[ -z "${msg}" ]] && return 0
    # De-duplicate to avoid repeated entries
    # shellcheck disable=SC2076
    if [[ ! " ${CUTE_HEADER_PARTS[*]} " =~ " ${msg} " ]]; then
        CUTE_HEADER_PARTS+=("${msg}")
    fi
}

function __cute_shell_header_add_warning() {
    local msg="${1:-}"
    [[ -z "${msg}" ]] && return 0
    msg="${ICON_MAP[WARNING]} ${msg}"
    # De-duplicate warnings
    # shellcheck disable=SC2076
    if [[ ! " ${CUTE_HEADER_WARNINGS[*]} " =~ " ${msg} " ]]; then
        CUTE_HEADER_WARNINGS+=("${msg}")
    fi
}

function __cute_startup_time() {
    _dotTrace_enter

    if [[ -z "${DOTFILES_INIT_EPOCHREALTIME_END}" ]]; then
        DOTFILES_INIT_EPOCHREALTIME_END="$(__time_now)"
        export DOTFILES_INIT_EPOCHREALTIME_END
    fi

    local secs
    secs="$(__time_delta "${DOTFILES_INIT_EPOCHREALTIME_START:0}" "$DOTFILES_INIT_EPOCHREALTIME_END")"
    local display_str="${ICON_MAP[CLOCK]} ${secs}s"

    # Highlight slow startups (> 3.000 seconds) in red
    local -i is_slow=0
    is_slow="$(awk -v d="$secs" 'BEGIN { if (d > 3.0) print 1; else print 0 }')"

    if (( is_slow == 1 )); then
        __echo_colored_stdout red "${display_str}"
    else
        printf '%s' "${display_str}"
    fi

    _dotTrace_exit 0
}

function __cute_shell_header() {
    _dotTrace_enter "$@"
    local -i force=0
    if [[ "$1" == "--force" ]]; then
        force=1
    fi

    if (( "$force" != 1 )); then
        if ! __is_shell_interactive; then
            _dotTrace "Skipping cute header in non-interactive shell"
            _dotTrace_exit 0
            return
        fi
        if __is_embedded_terminal; then
            _dotTrace "Skipping cute header in embedded terminal"
            _dotTrace_exit 0
            return
        fi
    fi

    # Build line prefix for nested shells
    local prefix=""
    if (( SHLVL > 1 )); then
        for ((i = 2; i <= SHLVL; i++)); do
            prefix+="|"
        done
        prefix+=" "
    fi

    local startup_part
    # Ensure END timestamp is recorded in the parent shell (not just in a subshell)
    if [[ -z "${DOTFILES_INIT_EPOCHREALTIME_END}" ]]; then
        DOTFILES_INIT_EPOCHREALTIME_END="$(__time_now)"
        export DOTFILES_INIT_EPOCHREALTIME_END
    fi
    # shellcheck disable=SC2119
    startup_part="$(__cute_startup_time)"
    __cute_shell_header_add_info "${startup_part}"

    # Print warnings, one per line, first (if any)
    if (( ${#CUTE_HEADER_WARNINGS[@]} > 0 )); then
        for __warn in "${CUTE_HEADER_WARNINGS[@]}"; do
            printf '%s%s\n' "${prefix}" "${__warn}"
        done
    fi

    echo "${prefix}$(__cute_shell_path)" "$(__cute_shell_version)" "${CUTE_HEADER_PARTS[@]}" "${ICON_MAP[MD_SNAPCHAT]}"

    _dotTrace_exit 0
}

if __is_shell_interactive; then
    __cute_shell_header_add_info "$(__cute_kernel)"
    __cute_shell_header_add_info "$(__cute_host)"
    __cute_shell_header_add_info "$(uname -m)"

    if __is_shell_old_bash; then
        __cute_shell_header_add_warning "Bash ${BASH_VERSINFO[0]} is old o_O"
    fi

    if __is_tool_window; then
        __cute_shell_header_add_info "${ICON_MAP[TOOLS]}"
    fi

    __cute_shell_header_add_info "distro:$(__effective_distribution)"
    if __is_embedded_terminal; then
        __cute_shell_header_add_info "embedded:$(__embedded_terminal_info)"
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
        __cute_shell_header_add_warning "eza not found"
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
        # shellcheck disable=SC2329
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

    if __is_shell_bash; then
        if declare -p precmd_functions &>/dev/null; then
            precmd_functions+=("__iterm_badge_nodeenv")
        else
            __cute_shell_header_add_warning "bash-preexec not loaded"
        fi
    fi
    if __is_shell_zsh; then
        precmd_functions+=(__iterm_badge_nodeenv)
    fi

    _dotTrace_exit 0
}

function __do_vscode_shell_integration() {
    _dotTrace_enter "$@"

    local -i has_code_cmd=0
    if command -v code &> /dev/null; then
        has_code_cmd=1
    fi

    if (( has_code_cmd == 0 )); then
        if __is_on_macos && ! __is_ssh_session; then
            __cute_shell_header_add_warning "VSCode CLI 'code' unavailable.  Check https://code.visualstudio.com/docs/setup/mac"
        fi
        _dotTrace_exit 0
        return
    fi

    if __is_vscode_terminal; then
        if (( has_code_cmd == 0 )); then
            echo "VSCode terminal detected but 'code' CLI unavailable"
        fi
        if __is_shell_bash; then
            # shellcheck disable=SC1090
            source "$(code --locate-shell-integration-path bash)"
        elif __is_shell_zsh; then
            # shellcheck disable=SC1090
            source "$(code --locate-shell-integration-path zsh)"
        fi
    fi

    _dotTrace_exit 0
}

_dotTrace "Finished loading env_funcs.sh"

#! /bin/bash

#pragma once

#pragma requires debug.sh
_dotTrace "Loading platform.sh"

function __need() { command -v "$1" >/dev/null 2>&1; }

function __is_shell_interactive() { [[ $- == *i* ]]; }
function __is_in_screen() { [ "${TERM}" = "screen" ]; }

function __is_in_tmux() {
    if __is_in_screen; then return 1; fi
    [ -n "${TMUX}" ]
}

function __is_ec2_instance() {
    # EC2 exposes a link-local metadata endpoint at http://169.254.169.254
    curl -s --connect-timeout 1 http://169.254.169.254/latest/meta-data/ > /dev/null
}

function __ec2_instance_id() {
    if ! __is_ec2_instance; then
        return 1
    fi
    curl -s http://169.254.169.254/latest/meta-data/instance-id
}

function __is_in_vimruntime() { [ -n "${VIMRUNTIME}" ]; }
function __is_in_python_venv() { [ -n "${VIRTUAL_ENV}" ]; }

function __is_on_wsl() { grep -qE "(Microsoft|WSL)" /proc/version &> /dev/null; }

function __is_in_windows_drive() {
    if [ -z "${WIN_SYSTEM_ROOT-}" ]; then return 1; fi
    [[ "${PWD##"${WIN_SYSTEM_ROOT}"}" != "${PWD}" ]]
}

function __is_in_wsl_windows_drive() { __is_on_wsl && __is_in_windows_drive; }
function __is_in_wsl_linux_drive() { __is_on_wsl && ! __is_in_windows_drive; }

function __is_on_macos() { [[ "$(uname -s)" == "Darwin" ]]; }
function __is_on_windows() { [[ "$(uname -s)" = "MINGW64_NT"* ]] || [[ "$(uname -s)" = "MSYS_NT"* ]]; }
function __is_on_unexpected_windows() { [[ "$(uname -s)" = "MINGW32_NT"* ]]; }
function __is_on_linux() { [[ "$(uname -s)" = "Linux"* ]]; }

function __print_linux_distro() {
    if [[ -f /etc/lsb-release ]]; then
        # shellcheck disable=SC1091
        . /etc/lsb-release
        printf '%s' "${DISTRIB_ID}"
    else
        printf 'Unknown Linux distribution'
    fi
}

function __is_vscode_terminal() {
    if [[ "${VSCODE_RESOLVING_ENVIRONMENT}" == "1" ]]; then return 0; fi
    if [[ "${TERM_PROGRAM}" == "vscode" ]]; then return 0; fi
    return 1
}

function __is_iterm2_terminal() { [[ "iTerm2" == "${LC_TERMINAL}" ]]; }
function __is_konsole_terminal() { [[ -n "${KONSOLE_VERSION}" ]]; }
function __is_ghostty_terminal() { [[ "${TERM}" == "xterm-ghostty" ]]; }
function __is_tool_window() { [[ -n "${TOOL_WINDOW}" ]]; }

function __is_shell_bash() { [[ -n "${BASH_VERSION}" ]]; }
function __is_shell_old_bash() { __is_shell_bash && (( BASH_VERSINFO[0] < 4 )); }
function __is_shell_zsh() { [[ -n "${ZSH_VERSION}" ]]; }

function __has_homebrew() { __need brew; }

function __is_homebrew_bin() {
    local bin_path="$1"
    [[ $bin_path == ${HOMEBREW_PREFIX:-/opt/homebrew}/bin/* ]]
}

function __ensure_path_entry_after_homebrew_bins() {
    local target_entry="$1"
    local homebrew_prefix="${HOMEBREW_PREFIX:-/opt/homebrew}"
    local homebrew_bin="${homebrew_prefix}/bin"
    local homebrew_sbin="${homebrew_prefix}/sbin"

    [[ -d "${target_entry}" ]] || return 0

    case ":${PATH}:" in
    *:"${target_entry}":*)
        return 0
        ;;
    esac

    case "${PATH}" in
    "${homebrew_bin}:${homebrew_sbin}:"*)
        PATH="${homebrew_bin}:${homebrew_sbin}:${target_entry}:${PATH#"${homebrew_bin}:${homebrew_sbin}:"}"
        ;;
    "${homebrew_bin}:"*)
        PATH="${homebrew_bin}:${target_entry}:${PATH#"${homebrew_bin}:"}"
        ;;
    *)
        PATH="${target_entry}:${PATH}"
        ;;
    esac

    export PATH
}

function __zsh_fpath_has_entry() {
    local entry="${1:-}"
    [[ -n "${entry}" ]] || return 1

    case ":${FPATH:-}:" in
    *:"${entry}":*)
        return 0
        ;;
    esac

    return 1
}

function __zsh_fpath_prepend_if_dir() {
    local entry="${1:-}"
    [[ -d "${entry}" ]] || return 0

    if ! __zsh_fpath_has_entry "${entry}"; then
        fpath=("${entry}" "${fpath[@]}")
    fi
}

function __zsh_fpath_append_if_dir() {
    local entry="${1:-}"
    [[ -d "${entry}" ]] || return 0

    if ! __zsh_fpath_has_entry "${entry}"; then
        fpath=("${fpath[@]}" "${entry}")
    fi
}

function __zsh_fpath_has_function_file() {
    local function_name="${1:-}"
    local current_entry=""

    [[ -n "${function_name}" ]] || return 1

    for current_entry in "${fpath[@]}"; do
        if [[ -r "${current_entry}/${function_name}" ]]; then
            return 0
        fi
    done

    return 1
}

function __configure_zsh_function_path() {
    __is_shell_zsh || return 0

    if ! __zsh_fpath_has_function_file colors || ! __zsh_fpath_has_function_file compinit; then
        fpath=()
    fi

    typeset -gaU fpath

    __zsh_fpath_prepend_if_dir "${DOTFILES_CONFIG_ROOT}/zfuncs"

    if [[ -n "${HOMEBREW_PREFIX:-}" ]]; then
        __zsh_fpath_prepend_if_dir "${HOMEBREW_PREFIX}/share/zsh/site-functions"
        __zsh_fpath_append_if_dir "${HOMEBREW_PREFIX}/share/zsh/functions"
    fi

    __zsh_fpath_append_if_dir "/usr/local/share/zsh/site-functions"
    __zsh_fpath_append_if_dir "/usr/share/zsh/site-functions"
    __zsh_fpath_append_if_dir "/usr/share/zsh/${ZSH_VERSION}/functions"
    __zsh_fpath_append_if_dir "/usr/share/zsh/${ZSH_VERSION%.*}/functions"
    __zsh_fpath_append_if_dir "/usr/share/zsh/functions"
}

function __configure_homebrew_shellenv() {
    if command -v brew >/dev/null 2>&1; then
        eval "$(brew shellenv)"
    elif [[ -x "/opt/homebrew/bin/brew" ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -x "/usr/local/bin/brew" ]]; then
        eval "$(/usr/local/bin/brew shellenv)"
    fi

    # brew shellenv on Apple Silicon rebuilds PATH around /opt/homebrew and can
    # drop tools installed in the standard local prefix, such as Docker Desktop.
    __ensure_path_entry_after_homebrew_bins "/usr/local/bin"
    __ensure_path_entry_after_homebrew_bins "/usr/local/sbin"
    __configure_zsh_function_path
}

function __path_prepend_entry() {
    local entry="$1"
    local rebuilt_path=""
    local current_entry=""

    [[ -n "${entry}" ]] || return 1

    while IFS= read -r current_entry; do
        if [[ -z "${current_entry}" || "${current_entry}" == "${entry}" ]]; then
            continue
        fi
        if [[ -n "${rebuilt_path}" ]]; then
            rebuilt_path="${rebuilt_path}:"
        fi
        rebuilt_path="${rebuilt_path}${current_entry}"
    done < <(printf '%s' "${PATH}" | tr ':' '\n')

    PATH="${entry}${rebuilt_path:+:${rebuilt_path}}"
    export PATH

    if __is_shell_bash; then
        hash -r 2>/dev/null || true
    elif __is_shell_zsh; then
        rehash 2>/dev/null || true
    fi
}

function __path_remove_matching_entries() {
    local entry_regex="${1:-}"
    local rebuilt_path=""
    local current_entry=""

    [[ -n "${entry_regex}" ]] || return 1

    while IFS= read -r current_entry; do
        if [[ -z "${current_entry}" || "${current_entry}" =~ ${entry_regex} ]]; then
            continue
        fi
        if [[ -n "${rebuilt_path}" ]]; then
            rebuilt_path="${rebuilt_path}:"
        fi
        rebuilt_path="${rebuilt_path}${current_entry}"
    done < <(printf '%s' "${PATH}" | tr ':' '\n')

    PATH="${rebuilt_path}"
    export PATH

    if __is_shell_bash; then
        hash -r 2>/dev/null || true
    elif __is_shell_zsh; then
        rehash 2>/dev/null || true
    fi
}

function __restore_inherited_nvm_node_bin() {
    local inherited_node_bin="${1:-}"
    [[ -n "${inherited_node_bin}" ]] || return 1

    __path_remove_matching_entries '^'"${HOME}"'/\.nvm/versions/node/[^/]+/bin$'
    __path_prepend_entry "${inherited_node_bin}"
}

function __path_index_of_entry() {
    local target_entry="${1:-}"
    local current_entry=""
    local index=0

    [[ -n "${target_entry}" ]] || return 1

    while IFS= read -r current_entry; do
        if [[ "${current_entry}" == "${target_entry}" ]]; then
            printf '%s' "${index}"
            return 0
        fi
        index=$((index + 1))
    done < <(printf '%s' "${PATH}" | tr ':' '\n')

    return 1
}

function __is_homebrew_prioritized_above_system_bins() {
    local homebrew_prefix="${HOMEBREW_PREFIX:-/opt/homebrew}"
    local homebrew_bin="${homebrew_prefix}/bin"
    local homebrew_index=""
    local system_entry=""
    local system_index=""

    if [[ ! -d "${homebrew_bin}" ]]; then
        return 1
    fi

    if ! homebrew_index="$(__path_index_of_entry "${homebrew_bin}")"; then
        return 1
    fi

    for system_entry in /usr/bin /bin; do
        if system_index="$(__path_index_of_entry "${system_entry}")"; then
            if (( homebrew_index > system_index )); then
                return 1
            fi
        fi
    done

    return 0
}

function __capture_inherited_nvm_node_bin_from_path() {
    local path_snapshot="${1:-${PATH}}"
    local path_entry=""

    while IFS= read -r path_entry; do
        case "${path_entry}" in
        "${HOME}"/.nvm/versions/node/*/bin)
            printf '%s' "${path_entry}"
            return 0
            ;;
        esac
    done < <(printf '%s' "${path_snapshot}" | tr ':' '\n')

    return 1
}

function __homebrew_node_bin_path() {
    local homebrew_prefix="${HOMEBREW_PREFIX:-/opt/homebrew}"
    local homebrew_node_bin="${homebrew_prefix}/bin/node"
    if [[ -x "${homebrew_node_bin}" ]]; then
        printf '%s' "${homebrew_node_bin}"
        return 0
    fi
    return 1
}

function __has_homebrew_node() {
    __homebrew_node_bin_path >/dev/null 2>&1
}

function __nvm_installed_node_bin_path() {
    local nvm_root="${NVM_DIR:-$HOME/.nvm}"
    local nvm_node_bin=""

    while IFS= read -r nvm_node_bin; do
        [[ -x "${nvm_node_bin}" ]] || continue
        printf '%s' "${nvm_node_bin}"
        return 0
    done < <(find "${nvm_root}/versions/node" -mindepth 3 -maxdepth 3 -type f -path '*/bin/node' 2>/dev/null | sort)

    return 1
}

function __has_nvm_installed_node() {
    __nvm_installed_node_bin_path >/dev/null 2>&1
}

function __active_node_provider() {
    local node_path="${1:-}"
    if [[ -z "${node_path}" ]]; then
        node_path="$(command -v node 2>/dev/null || true)"
    fi

    if [[ -z "${node_path}" ]]; then
        return 1
    fi

    case "${node_path}" in
    "${HOME}"/.nvm/versions/node/*/bin/node)
        printf '%s' "nvm"
        return 0
        ;;
    esac

    if __is_homebrew_bin "${node_path}"; then
        printf '%s' "brew"
        return 0
    fi

    printf '%s' "system"
    return 0
}

function __active_node_header_label() {
    local node_path node_version node_provider
    node_path="$(command -v node 2>/dev/null || true)"
    [[ -n "${node_path}" ]] || return 1

    node_version="$(node -v 2>/dev/null || true)"
    [[ -n "${node_version}" ]] || return 1

    node_provider="$(__active_node_provider "${node_path}")"
    printf '%s %s (%s)' "${ICON_MAP[NODEJS]}" "${node_version}" "${node_provider}"
}

function __has_conflicting_node_installations() {
    __has_homebrew_node && __has_nvm_installed_node
}

function __has_rbenv() { __need rbenv; }

function __has_rust() { __need cargo; }

function __has_nvm() { [[ -s "$NVM_DIR/nvm.sh" ]]; }

function __is_bash_preexec_loaded() {
    __is_shell_bash && \
    ! __is_shell_old_bash && \
    [[ -n "${bash_preexec_imported:-}" ]]
}

_dotTrace "Finished loading platform.sh"

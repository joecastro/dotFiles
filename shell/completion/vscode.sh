#! /usr/bin/env bash

#pragma once

#pragma requires debug.sh
#pragma requires env_funcs.sh

_dotTrace "Configuring VSCode shell integration"

if ! command -v code >/dev/null 2>&1; then
    if __is_vscode_terminal; then
        echo "VSCode terminal detected but 'code' CLI unavailable"
    fi

    if __is_on_macos && ! __is_ssh_session; then
        __cute_shell_header_add_warning "VSCode CLI 'code' unavailable. Check https://code.visualstudio.com/docs/setup/mac"
    fi
    return 0
fi

if ! __is_vscode_terminal; then
    _dotTrace "Skipping VSCode integration: not inside VSCode terminal"
    return 0
fi

__vscode_shell_target="bash"
if __is_shell_zsh; then
    __vscode_shell_target="zsh"
elif ! __is_shell_bash; then
    _dotTrace "Skipping VSCode integration: unsupported shell"
    return 0
fi

if __vscode_integration_path="$(code --locate-shell-integration-path "${__vscode_shell_target}" 2>/dev/null)"; then
    if [[ -z "${__vscode_integration_path}" || ! -f "${__vscode_integration_path}" ]]; then
        _dotTrace "VSCode shell integration script missing for ${__vscode_shell_target}"
    else
        # shellcheck disable=SC1090
        source "${__vscode_integration_path}"
    fi
else
    _dotTrace "VSCode shell integration path lookup failed for ${__vscode_shell_target}"
fi

unset __vscode_shell_target
unset __vscode_integration_path

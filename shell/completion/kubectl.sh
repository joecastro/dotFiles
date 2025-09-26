#! /usr/bin/env bash

#pragma once

#pragma requires debug.sh
#pragma requires env_funcs.sh

if ! command -v kubectl >/dev/null 2>&1; then
    _dotTrace "Skipping kubectl completions: kubectl command not found"
    return 0
fi

__kubectl_completion_target="bash"
if __is_shell_zsh; then
    __kubectl_completion_target="zsh"
fi

if kubectl completion "${__kubectl_completion_target}" >/dev/null 2>&1; then
    # shellcheck disable=SC1090
    source <(kubectl completion "${__kubectl_completion_target}")
else
    _dotTrace "kubectl does not support completion for ${__kubectl_completion_target}"
fi

unset __kubectl_completion_target

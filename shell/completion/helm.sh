#! /usr/bin/env bash

#pragma once

#pragma requires debug.sh
#pragma requires env_funcs.sh

if ! command -v helm >/dev/null 2>&1; then
    _dotTrace "Skipping Helm completions: helm command not found"
    return 0
fi

__helm_completion_target="bash"
if __is_shell_zsh; then
    __helm_completion_target="zsh"
fi

if helm completion "${__helm_completion_target}" >/dev/null 2>&1; then
    # shellcheck disable=SC1090
    source <(helm completion "${__helm_completion_target}")
else
    _dotTrace "Helm does not support completion for ${__helm_completion_target}"
fi

unset __helm_completion_target

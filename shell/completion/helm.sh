#! /usr/bin/env bash

#pragma once

#pragma requires debug.sh
#pragma requires env_funcs.sh

__helm_completion_target="bash"
if __is_shell_zsh; then
    __helm_completion_target="zsh"
fi

__helm_generated_completion="${DOTFILES_CONFIG_ROOT}/completion/generated/helm.${__helm_completion_target}"
if [[ -r "${__helm_generated_completion}" ]]; then
    # shellcheck disable=SC1090
    source "${__helm_generated_completion}"
else
    _dotTrace "Generated Helm completion missing for ${__helm_completion_target}"
fi

unset __helm_generated_completion
unset __helm_completion_target

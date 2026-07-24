#! /usr/bin/env bash

#pragma once

#pragma requires debug.sh
#pragma requires env_funcs.sh

__kubectl_completion_target="bash"
if __is_shell_zsh; then
    __kubectl_completion_target="zsh"
fi

__kubectl_generated_completion="${DOTFILES_CONFIG_ROOT}/completion/generated/kubectl.${__kubectl_completion_target}"
if [[ -r "${__kubectl_generated_completion}" ]]; then
    # shellcheck disable=SC1090
    source "${__kubectl_generated_completion}"
else
    _dotTrace "Generated kubectl completion missing for ${__kubectl_completion_target}"
fi

unset __kubectl_generated_completion
unset __kubectl_completion_target

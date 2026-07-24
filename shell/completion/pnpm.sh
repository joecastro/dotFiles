#! /usr/bin/env bash

#pragma once

#pragma requires debug.sh
#pragma requires env_funcs.sh

__pnpm_completion_target="bash"
if __is_shell_zsh; then
    __pnpm_completion_target="zsh"
fi

__pnpm_generated_completion="${DOTFILES_CONFIG_ROOT}/completion/generated/pnpm.${__pnpm_completion_target}"
if [[ -r "${__pnpm_generated_completion}" ]]; then
    # shellcheck disable=SC1090
    source "${__pnpm_generated_completion}"
else
    _dotTrace "Generated pnpm completion missing for ${__pnpm_completion_target}"
fi

unset __pnpm_generated_completion
unset __pnpm_completion_target

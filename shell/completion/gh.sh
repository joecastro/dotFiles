#! /usr/bin/env bash

#pragma once

#pragma requires debug.sh
#pragma requires env_funcs.sh

__gh_completion_target="bash"
if __is_shell_zsh; then
    __gh_completion_target="zsh"
fi

__gh_generated_completion="${DOTFILES_CONFIG_ROOT}/completion/generated/gh.${__gh_completion_target}"
if [[ -r "${__gh_generated_completion}" ]]; then
    # shellcheck disable=SC1090
    source "${__gh_generated_completion}"
else
    _dotTrace "Generated gh completion missing for ${__gh_completion_target}"
fi

unset __gh_generated_completion
unset __gh_completion_target

#! /usr/bin/env bash

#pragma once

#pragma requires debug.sh
#pragma requires env_funcs.sh

__docker_completion_target="bash"
if __is_shell_zsh; then
    __docker_completion_target="zsh"
fi

__docker_generated_completion="${DOTFILES_CONFIG_ROOT}/completion/generated/docker.${__docker_completion_target}"
if [[ -r "${__docker_generated_completion}" ]]; then
    # shellcheck disable=SC1090
    source "${__docker_generated_completion}"
else
    _dotTrace "Generated Docker completion missing for ${__docker_completion_target}"
fi

__docker_compose_generated_completion="${DOTFILES_CONFIG_ROOT}/completion/generated/docker-compose.${__docker_completion_target}"
if [[ -r "${__docker_compose_generated_completion}" ]]; then
    # shellcheck disable=SC1090
    source "${__docker_compose_generated_completion}"
else
    _dotTrace "Generated Docker Compose completion missing for ${__docker_completion_target}"
fi

unset __docker_generated_completion
unset __docker_compose_generated_completion
unset __docker_completion_target

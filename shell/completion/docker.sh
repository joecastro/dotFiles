#! /usr/bin/env bash

#pragma once

#pragma requires debug.sh
#pragma requires env_funcs.sh

if ! command -v docker >/dev/null 2>&1; then
    _dotTrace "Skipping Docker completions: docker command not found"
    return 0
fi

__docker_completion_target="bash"
if __is_shell_zsh; then
    __docker_completion_target="zsh"
fi

if docker completion "${__docker_completion_target}" >/dev/null 2>&1; then
    # shellcheck disable=SC1090
    source <(docker completion "${__docker_completion_target}")
else
    _dotTrace "Docker does not support completion for ${__docker_completion_target}"
fi

if docker compose version >/dev/null 2>&1; then
    if docker compose completion "${__docker_completion_target}" >/dev/null 2>&1; then
        # shellcheck disable=SC1090
        source <(docker compose completion "${__docker_completion_target}")
    else
        _dotTrace "Docker Compose does not support completion for ${__docker_completion_target}"
    fi
fi

unset __docker_completion_target

#! /usr/bin/env bash

#pragma once

#pragma requires debug.sh
#pragma requires env_funcs.sh

#pragma requires completion/homebrew.sh

_dotTrace "Configuring AWS CLI completions"

if ! command -v aws >/dev/null 2>&1; then
    _dotTrace "Skipping AWS CLI completions: aws command not found"
    return 0
fi

if __is_shell_bash; then
    if command -v aws_completer >/dev/null 2>&1; then
        complete -C "$(command -v aws_completer)" aws
    else
        _dotTrace "Skipping AWS CLI completions: aws_completer not found"
    fi
elif __is_shell_zsh; then
    aws_completion_script=""
    aws_completion_dir=""

    if command -v aws_zsh_completer.sh >/dev/null 2>&1; then
        aws_completion_script="$(command -v aws_zsh_completer.sh)"
    elif command -v aws_completer >/dev/null 2>&1; then
        aws_completion_dir="$(dirname "$(command -v aws_completer)")"
        if [[ -r "${aws_completion_dir}/aws_zsh_completer.sh" ]]; then
            aws_completion_script="${aws_completion_dir}/aws_zsh_completer.sh"
        fi
    fi

    if [[ -n "${aws_completion_script}" ]]; then
        # shellcheck disable=SC1090
        source "${aws_completion_script}"
    else
        _dotTrace "Skipping AWS CLI completions for zsh: aws_zsh_completer.sh not found"
    fi
fi

unset aws_completion_script
unset aws_completion_dir

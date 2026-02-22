#! /usr/bin/env bash

#pragma once

#pragma requires debug.sh
#pragma requires env_funcs.sh

_dotTrace "Configuring nvm"

nvm_prefix=""

if command -v brew >/dev/null 2>&1 && brew --prefix nvm >/dev/null 2>&1; then
    nvm_prefix="$(brew --prefix nvm 2>/dev/null)"
    if [[ -d "${nvm_prefix}" ]]; then
        _dotTrace "Using Homebrew nvm"
        if [[ -s "${nvm_prefix}/nvm.sh" ]]; then
            # shellcheck disable=SC1090
            source "${nvm_prefix}/nvm.sh"
        fi
        if __is_shell_bash && [[ -s "${nvm_prefix}/etc/bash_completion.d/nvm" ]]; then
            # shellcheck disable=SC1091
            source "${nvm_prefix}/etc/bash_completion.d/nvm"
        fi
        unset nvm_prefix
        return 0
    fi
fi

nvm_dir="${NVM_DIR:-$HOME/.nvm}"
if [[ -s "${nvm_dir}/nvm.sh" ]]; then
    # shellcheck disable=SC1090
    source "${nvm_dir}/nvm.sh"
else
    _dotTrace "Skipping nvm setup: ${nvm_dir}/nvm.sh missing"
fi

if __is_shell_bash && [[ -s "${nvm_dir}/bash_completion" ]]; then
    # shellcheck disable=SC1091
    source "${nvm_dir}/bash_completion"
fi

unset nvm_prefix
unset nvm_dir

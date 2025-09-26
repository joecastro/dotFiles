#! /usr/bin/env bash

#pragma once

#pragma requires debug.sh

_dotTrace "Configuring Rust environment"

rust_env_file="${HOME}/.cargo/env"
if [[ -s "${rust_env_file}" ]]; then
    # shellcheck disable=SC1090
    source "${rust_env_file}"
else
    _dotTrace "Skipping Rust setup: ${rust_env_file} missing"
fi

unset rust_env_file

#! /usr/bin/env bash

#pragma once

#pragma requires debug.sh
#pragma requires env_funcs.sh

_dotTrace "Configuring uv"

if ! command -v uv &> /dev/null; then
    __cute_shell_header_add_warning "uv is required but not installed. See https://docs.astral.sh/uv/getting-started/."
    return 1
fi


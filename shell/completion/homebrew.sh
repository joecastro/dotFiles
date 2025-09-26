#! /usr/bin/env bash

#pragma once

#pragma requires debug.sh

_dotTrace "Configuring Homebrew environment"

if command -v brew >/dev/null 2>&1; then
    eval "$(brew shellenv)"
    return 0
fi

if [[ -x "/opt/homebrew/bin/brew" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
    return 0
fi

_dotTrace "Skipping Homebrew setup: brew not found"

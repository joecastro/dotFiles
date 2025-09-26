#! /usr/bin/env bash

#pragma once

#pragma requires debug.sh

_dotTrace "Configuring rbenv"

if [[ -d "${HOME}/.rbenv/bin" ]]; then
    export PATH="${HOME}/.rbenv/bin:${PATH}"
fi

if command -v rbenv >/dev/null 2>&1; then
    eval "$(rbenv init -)"
else
    _dotTrace "Skipping rbenv init: rbenv not found"
fi

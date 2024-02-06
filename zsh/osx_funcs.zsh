#!/bin/zsh

#pragma once

function battery_charge {
    echo -n $(python3 "${DOTFILES_CONFIG_ROOT}"/batcharge.py)
}

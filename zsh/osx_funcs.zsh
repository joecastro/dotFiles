#!/bin/zsh

#pragma once

function battery_charge {
    echo -n $(python3 "${DOTFILES_CONFIG_ROOT}"/batcharge.py)
}

function chjava() {
    local jver=${1:?"Version must be specified"}
    if [[ -n $JAVA_HOME ]]; then
        PATH=$(echo "$PATH" | tr ':' '\n' | grep -v "$JAVA_HOME" | tr '\n' ':')
        PATH=${PATH%?} # Remove the trailing ':'
    fi
    JAVA_HOME=$(/usr/libexec/java_home -v "$jver")
    export JAVA_HOME
    PATH=$JAVA_HOME/bin:$PATH
    export PATH
}

function google-chrome() {
    if [[ -z "$1" ]]; then
        open -a "/Applications/Google Chrome.app" "$1"
    else
        open "/Applications/Google Chrome.app"
    fi
}

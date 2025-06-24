#!/bin/bash

#pragma once
#pragma validate-dotfiles

export RESET='\[\e[0m\]'

# Named colors (basic ANSI 16)
declare -A COLOR_ANSI=(
    [black]='\[\e[30m\]'
    [red]='\[\e[31m\]'
    [green]='\[\e[32m\]'
    [yellow]='\[\e[33m\]'
    [blue]='\[\e[34m\]'
    [magenta]='\[\e[35m\]'
    [cyan]='\[\e[36m\]'
    [white]='\[\e[37m\]'
    [bblack]='\[\e[90m\]'
    [bred]='\[\e[91m\]'
    [bgreen]='\[\e[92m\]'
    [byellow]='\[\e[93m\]'
    [bblue]='\[\e[94m\]'
    [bmagenta]='\[\e[95m\]'
    [bcyan]='\[\e[96m\]'
    [bwhite]='\[\e[97m\]'
)

# Background color ANSI map (basic and bright)
declare -A BG_COLOR_ANSI=(
    [black]='\[\e[40m\]'
    [red]='\[\e[41m\]'
    [green]='\[\e[42m\]'
    [yellow]='\[\e[43m\]'
    [blue]='\[\e[44m\]'
    [magenta]='\[\e[45m\]'
    [cyan]='\[\e[46m\]'
    [white]='\[\e[47m\]'
    [bblack]='\[\e[100m\]'
    [bred]='\[\e[101m\]'
    [bgreen]='\[\e[102m\]'
    [byellow]='\[\e[103m\]'
    [bblue]='\[\e[104m\]'
    [bmagenta]='\[\e[105m\]'
    [bcyan]='\[\e[106m\]'
    [bwhite]='\[\e[107m\]'
)

# Named colors
export PINK_FLAMINGO='\[\e[38;2;255;95;255m\]'

# Function for 256-color foreground: fg256 COLOR_CODE
function fg256() {
    printf '\[\e[38;5;%sm\]' "$1"
}

# Function for 256-color background: bg256 COLOR_CODE
function bg256() {
    printf '\[\e[48;5;%sm\]' "$1"
}

function is_valid_ansicolor() {
    local color="$1"
    [[ -n "${COLOR_ANSI[$color]}" ]]
}

function is_valid_rgb() {
    local hex=${1#\#}  # strip leading # if present
    [[ "$hex" =~ ^[0-9A-Fa-f]{6}$ ]]
}

function fg_rgb() {
    local hex=${1#\#}  # strip leading # if present
    local r=$((16#${hex:0:2}))
    local g=$((16#${hex:2:2}))
    local b=$((16#${hex:4:2}))
    printf '\[\e[38;2;%s;%s;%sm\]' "$r" "$g" "$b"
}

# RGB background with hex: bg_rgb 112233
function bg_rgb() {
    local hex=${1#\#}
    local r=$((16#${hex:0:2}))
    local g=$((16#${hex:2:2}))
    local b=$((16#${hex:4:2}))
    printf '\[\e[48;2;%s;%s;%sm\]' "$r" "$g" "$b"
}


function fg_color() {
    local color="$1"
    if is_valid_rgb "$color"; then
        fg_rgb "$color"
    elif is_valid_ansicolor "$color"; then
        printf "%s" "${COLOR_ANSI[$color]}"
    else
        printf "%s" "${COLOR_ANSI[white]}"  # Default to white if invalid
    fi
}

function bg_color() {
    local color="$1"
    if is_valid_rgb "$color"; then
        bg_rgb "$color"
    elif is_valid_ansicolor "$color"; then
        printf "%s" "${BG_COLOR_ANSI[$color]}"
    else
        printf "%s" "${BG_COLOR_ANSI[black]}"  # Default to black if invalid
    fi
}

function colorize() {
    local text="$1"
    local fg_input="$2"
    local bg_input="$3"

    local fg=""
    local bg=""

    # Foreground
    if is_valid_rgb "$fg_input"; then
        fg="$(fg_rgb "$fg_input")"
    else
        fg="${COLOR_ANSI[$fg_input]}"
    fi

    # Background (optional)
    if [ -n "$bg_input" ]; then
        if is_valid_rgb "$bg_input"; then
            bg="$(bg_rgb "$bg_input")"
        else
            bg="${BG_COLOR_ANSI[$bg_input]}"
        fi
    fi

    printf "%s%s%s%s" "$fg" "$bg" "$text" "$RESET"
}
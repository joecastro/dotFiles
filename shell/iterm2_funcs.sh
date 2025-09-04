#! /bin/bash

#pragma once
#pragma requires iterm2_color_funcs.sh

declare -a ITERM_COLOR_KEYS=( \
    "fg" \
    "bg" \
    "bold" \
    "link" \
    "selbg" \
    "selfg" \
    "curbg" \
    "curfg" \
    "underline" \
    "tab" \
    "black" \
    "red" \
    "green" \
    "yellow" \
    "blue" \
    "magenta" \
    "cyan" \
    "white" \
    "br_black" \
    "br_red" \
    "br_green" \
    "br_yellow" \
    "br_blue" \
    "br_magenta" \
    "br_cyan" \
    "br_white" \
)

# https://iterm2.com/documentation-escape-codes.html
function iterm_set_color() {
    local color_key=$1
    local color_value=$2

    # shellcheck disable=SC2199,SC2076
    if [[ ! "${ITERM_COLOR_KEYS[@]}" =~ "${color_key}" ]]; then
        echo "Invalid color key: ${color_key}"
        return 1
    fi

    printf '\033]1337;SetColors=%s=%s\007' "${color_key}" "${color_value}"
}

function iterm_get_attention() {
    printf "\033]" && printf "1337;RequestAttention=fireworks" && printf "\a"
}

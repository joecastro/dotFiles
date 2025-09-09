#!/bin/bash

#pragma once
#pragma validate-dotfiles

#pragma requires platform.sh

# Named colors
export PINK_FLAMINGO='#FF5FFF'

if __is_shell_zsh; then
    # Zsh has better native handling of colors in prompts.
    return 0
fi

export RESET='\[\e[0m\]'

export COLOR_ANSI_BLACK='\[\e[30m\]'
export COLOR_ANSI_RED='\[\e[31m\]'
export COLOR_ANSI_GREEN='\[\e[32m\]'
export COLOR_ANSI_YELLOW='\[\e[33m\]'
export COLOR_ANSI_BLUE='\[\e[34m\]'
export COLOR_ANSI_MAGENTA='\[\e[35m\]'
export COLOR_ANSI_CYAN='\[\e[36m\]'
export COLOR_ANSI_WHITE='\[\e[37m\]'
export COLOR_ANSI_BBLACK='\[\e[90m\]'
export COLOR_ANSI_BRED='\[\e[91m\]'
export COLOR_ANSI_BGREEN='\[\e[92m\]'
export COLOR_ANSI_BYELLOW='\[\e[93m\]'
export COLOR_ANSI_BBLUE='\[\e[94m\]'
export COLOR_ANSI_BMAGENTA='\[\e[95m\]'
export COLOR_ANSI_BCYAN='\[\e[96m\]'
export COLOR_ANSI_BWHITE='\[\e[97m\]'

export BG_COLOR_ANSI_BLACK='\[\e[40m\]'
export BG_COLOR_ANSI_RED='\[\e[41m\]'
export BG_COLOR_ANSI_GREEN='\[\e[42m\]'
export BG_COLOR_ANSI_YELLOW='\[\e[43m\]'
export BG_COLOR_ANSI_BLUE='\[\e[44m\]'
export BG_COLOR_ANSI_MAGENTA='\[\e[45m\]'
export BG_COLOR_ANSI_CYAN='\[\e[46m\]'
export BG_COLOR_ANSI_WHITE='\[\e[47m\]'
export BG_COLOR_ANSI_BBLACK='\[\e[100m\]'
export BG_COLOR_ANSI_BRED='\[\e[101m\]'
export BG_COLOR_ANSI_BGREEN='\[\e[102m\]'
export BG_COLOR_ANSI_BYELLOW='\[\e[103m\]'
export BG_COLOR_ANSI_BBLUE='\[\e[104m\]'
export BG_COLOR_ANSI_BMAGENTA='\[\e[105m\]'
export BG_COLOR_ANSI_BCYAN='\[\e[106m\]'
export BG_COLOR_ANSI_BWHITE='\[\e[107m\]'

if __is_shell_old_bash; then

    export COLOR_ANSI='\[\e[37m\]'
    export BG_COLOR_ANSI='\[\e[40m\]'

    function is_valid_ansicolor() {
        case "$1" in
            white|black|red|green|yellow|blue|magenta|cyan) return 0 ;;
            bwhite|bblack|bred|bgreen|byellow|bblue|bmagenta|bcyan) return 0 ;;
            *) return 1 ;;
        esac
    }

else

# Named colors (basic ANSI 16)
declare -A COLOR_ANSI=(
    [black]="$COLOR_ANSI_BLACK"
    [red]="$COLOR_ANSI_RED"
    [green]="$COLOR_ANSI_GREEN"
    [yellow]="$COLOR_ANSI_YELLOW"
    [blue]="$COLOR_ANSI_BLUE"
    [magenta]="$COLOR_ANSI_MAGENTA"
    [cyan]="$COLOR_ANSI_CYAN"
    [white]="$COLOR_ANSI_WHITE"
    [bblack]="$COLOR_ANSI_BBLACK"
    [bred]="$COLOR_ANSI_BRED"
    [bgreen]="$COLOR_ANSI_BGREEN"
    [byellow]="$COLOR_ANSI_BYELLOW"
    [bblue]="$COLOR_ANSI_BBLUE"
    [bmagenta]="$COLOR_ANSI_BMAGENTA"
    [bcyan]="$COLOR_ANSI_BCYAN"
    [bwhite]="$COLOR_ANSI_BWHITE"
)

declare -A BG_COLOR_ANSI=(
    [black]="$BG_COLOR_ANSI_BLACK"
    [red]="$BG_COLOR_ANSI_RED"
    [green]="$BG_COLOR_ANSI_GREEN"
    [yellow]="$BG_COLOR_ANSI_YELLOW"
    [blue]="$BG_COLOR_ANSI_BLUE"
    [magenta]="$BG_COLOR_ANSI_MAGENTA"
    [cyan]="$BG_COLOR_ANSI_CYAN"
    [white]="$BG_COLOR_ANSI_WHITE"
    [bblack]="$BG_COLOR_ANSI_BBLACK"
    [bred]="$BG_COLOR_ANSI_BRED"
    [bgreen]="$BG_COLOR_ANSI_BGREEN"
    [byellow]="$BG_COLOR_ANSI_BYELLOW"
    [bblue]="$BG_COLOR_ANSI_BBLUE"
    [bmagenta]="$BG_COLOR_ANSI_BMAGENTA"
    [bcyan]="$BG_COLOR_ANSI_BCYAN"
    [bwhite]="$BG_COLOR_ANSI_BWHITE"
)

function is_valid_ansicolor() {
    local color="$1"
    [[ -n "${COLOR_ANSI[$color]}" ]]
}

fi

# Function for 256-color foreground: fg256 COLOR_CODE
function fg256() {
    printf '\[\e[38;5;%sm\]' "$1"
}

# Function for 256-color background: bg256 COLOR_CODE
function bg256() {
    printf '\[\e[48;5;%sm\]' "$1"
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
        local varname="COLOR_ANSI_${color^^}"
        printf "%s" "${!varname}"
    else
        printf "%s" "${COLOR_ANSI_WHITE}"  # Default to white if invalid
    fi
}

function bg_color() {
    local color="$1"
    if is_valid_rgb "$color"; then
        bg_rgb "$color"
    elif is_valid_ansicolor "$color"; then
        local varname="BG_COLOR_ANSI_${color^^}"
        printf "%s" "${!varname}"
    else
        printf "%s" "${BG_COLOR_ANSI_BLACK}"  # Default to black if invalid
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
        fg="$(fg_color "$fg_input")"
    fi

    # Background (optional)
    if [ -n "$bg_input" ]; then
        if is_valid_rgb "$bg_input"; then
            bg="$(bg_rgb "$bg_input")"
        else
            bg=$(bg_color "$bg_input")
        fi
    fi

    printf "%s%s%s%s" "$fg" "$bg" "$text" "$RESET"
}
#!/bin/bash
# shellcheck disable=SC2034

#pragma once
#pragma validate-dotfiles

# shellcheck source=SCRIPTDIR/profile.sh
source ~/.profile

# Exit if not running interactively
__is_shell_interactive || return

# shellcheck source=/dev/null
source "${DOTFILES_CONFIG_ROOT}/completion/git-completion.bash"

# PS1 components
Time12h="\T"
Time12a="\@"
PathShort="\w"
PathFull="\W"
NewLine="\n"
Jobs="\j"

# Colors
Color_Off='\e[0m'  # Reset

# Normal Colors
Black='\e[0;30m'
DarkGray='\e[01;30m'
Red='\e[0;31m'
BrightRed='\e[01;31m'
Green='\e[0;32m'
BrightGreen='\e[01;32m'
Brown='\e[0;33m'
Yellow='\e[1;33m'
Blue='\e[0;34m'
BrightBlue='\e[1;34m'
Purple='\e[0;35m'
LightPurple='\e[1;35m'
Cyan='\e[0;36m'
BrightCyan='\e[1;36m'
LightGray='\e[0;37m'
White='\e[1;37m'

# Bold Colors
BBlack='\e[1;30m'
BRed='\e[1;31m'
BGreen='\e[1;32m'
BYellow='\e[1;33m'
BBlue='\e[1;34m'
BPurple='\e[1;35m'
BCyan='\e[1;36m'
BWhite='\e[1;37m'

# Background Colors
On_Black='\e[40m'
On_Red='\e[41m'
On_Green='\e[42m'
On_Yellow='\e[43m'
On_Blue='\e[44m'
On_Purple='\e[45m'
On_Cyan='\e[46m'
On_White='\e[47m'

# Shell options
shopt -s checkwinsize  # Update terminal size after each command
if ! __is_shell_old_bash; then
    shopt -s globstar  # Enable recursive globbing (**)
fi

# History settings
HISTFILE="${HOME}/.bash_history"
HISTSIZE=2000
HISTFILESIZE=5000
shopt -s histappend  # Append to history instead of overwriting
export HISTCONTROL=ignoredups:erasedups  # Ignore duplicate commands
export HISTIGNORE="ls:cd:cd -:pwd:exit:date:* --help"  # Ignore common commands

# Disable virtualenv prompt change
export VIRTUAL_ENV_DISABLE_PROMPT=1

# Set vi mode for command-line editing
set -o vi

# Cursor shape adjustment
function __set_cursor_shape() {
    if [[ $READLINE_LINE ]]; then
        echo -ne '\e[5 q'  # Beam
    else
        echo -ne '\e[1 q'  # Block
    fi
}

# Key bindings
bind '"\e[A": history-search-backward'
bind '"\e[B": history-search-forward'
bind '"\C-r": reverse-search-history'
bind '"\C-u": unix-line-discard'
bind '"\C-w": kill-line'

function __remove_nonprintable_regions() {
    local input="$1"
    echo "$input" | sed -E 's/\\\[[^]]*\\\]//g'
}

function __calculate_host_color() {
    local prompt_host_color="$Brown"

    if [[ -n "${HOST_COLOR}" ]]; then
        # Convert hex color code to RGB
        local r g b
        r=$(printf '%d' 0x"${HOST_COLOR:1:2}")
        g=$(printf '%d' 0x"${HOST_COLOR:3:2}")
        b=$(printf '%d' 0x"${HOST_COLOR:5:2}")

        # Convert RGB to ANSI escape sequence
        prompt_host_color="\033[38;2;${r};${g};${b}m"
    fi

    echo "$prompt_host_color"
}

# Calculate host name
function __calculate_host_name() {
    local prompt_host_name="\h"

    if __is_in_tmux; then
        prompt_host_name=""
    elif ! __is_ssh_session && [[ -n "${LOCALHOST_PREFERRED_DISPLAY}" ]]; then
        prompt_host_name="${LOCALHOST_PREFERRED_DISPLAY}"
    fi

    echo "$prompt_host_name"
}

function __cute_prompt_command() {
    local last_command_status=$?

    local END_OF_PROMPT_ICON='%'
    local ELEVATED_END_OF_PROMPT_ICON='#'

    local time_part
    time_part=$(__cute_time_prompt)
    PS1=''
    if [[ $last_command_status -ne 0 ]]; then
        PS1+="\\[${On_Red}\\]"
    fi

    PS1+="\\[${White}\\]${time_part}\\[${Color_Off}\\] "
    PS1+="\\[${BrightGreen}\\]\u\\[${Yellow}\\]@"
    PS1+="\\[$(__calculate_host_color)\\]$(__calculate_host_name)\\[${Color_Off}\\] "
    PS1+="$(__cute_pwd)"
    if [[ $EUID -eq 0 ]]; then
        PS1+=" ${ELEVATED_END_OF_PROMPT_ICON} "
    else
        PS1+=" ${END_OF_PROMPT_ICON} "
    fi

    __set_cursor_shape
}

PS1=""
PROMPT_COMMAND=__cute_prompt_command
export PROMPT_COMMAND
export PS1

__do_iterm2_shell_integration
__do_vscode_shell_integration
__do_konsole_shell_integration
__do_eza_aliases

if declare -f chjava &>/dev/null; then
    chjava 22
fi

if declare -f __is_on_glinux &>/dev/null && __is_on_glinux; then
    __on_glinux_bashrc_load_complete
fi

__cute_shell_header

#! /bin/bash
#shellcheck disable=SC2034

#pragma once

#pragma validate-dotfiles

# shellcheck source=SCRIPTDIR/profile.sh
source ~/.profile

# If not running interactively, don't do anything
__is_shell_interactive || return

# shellcheck source=/dev/null
source "${DOTFILES_CONFIG_ROOT}/completion/git-completion.bash"

# Enable vi mode
set -o vi

# Various PS1 aliases

Time12h="\T"
Time12a="\@"
PathShort="\w"
PathFull="\W"
NewLine="\n"
Jobs="\j"

# Reset
Color_Off='\e[0m'

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

IBlack="\033[0;90m"       # Black

# Bold
BBlack='\e[1;30m'       # Black
BRed='\e[1;31m'         # Red
BGreen='\e[1;32m'       # Green
BYellow='\e[1;33m'      # Yellow
BBlue='\e[1;34m'        # Blue
BPurple='\e[1;35m'      # Purple
BCyan='\e[1;36m'        # Cyan
BWhite='\e[1;37m'       # White

# Background
On_Black='\e[40m'       # Black
On_Red='\e[41m'         # Red
On_Green='\e[42m'       # Green
On_Yellow='\e[43m'      # Yellow
On_Blue='\e[44m'        # Blue
On_Purple='\e[45m'      # Purple
On_Cyan='\e[46m'        # Cyan
On_White='\e[47m'       # White

# Check the window size after each command and update the values of lines and columns
shopt -s checkwinsize

if ! __is_shell_old_bash; then
    # Use "**" in pathname expansion will match files in subdirectories - Needs Bash 4+
    shopt -s globstar
fi

if __is_iterm2_terminal; then
    # Disable extdebug because it causes issues with iTerm shell integration
    shopt -u extdebug
fi

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

function __calculate_host_name() {
    local prompt_host_name="\h"

    if __is_in_tmux; then
        prompt_host_name=""
    elif ! __is_ssh_session && [[ -n "${LOCALHOST_PREFERRED_DISPLAY}" ]]; then
        prompt_host_name="${LOCALHOST_PREFERRED_DISPLAY}"
    fi

    echo "$prompt_host_name"
}

# disable the default virtualenv prompt change
# export VIRTUAL_ENV_DISABLE_PROMPT=1

PS1=\\[$White\\]$(__cute_time_prompt)\\[$Color_Off\\]' '\\[$BrightGreen\\]'\u'\\[$Yellow\\]'@'\\[$(__calculate_host_color)\\]$(__calculate_host_name)\\[$Color_Off\\]' $(__cute_pwd) % '
export PS1

__do_iterm2_shell_integration

__do_eza_aliases

if declare -f chjava &>/dev/null; then
    chjava 22
fi

if declare -f __is_on_glinux &>/dev/null && __is_on_glinux; then
    __on_glinux_bashrc_load_complete
fi

__cute_shell_header

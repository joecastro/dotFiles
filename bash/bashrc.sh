#! /bin/bash
#shellcheck disable=SC2034

#pragma once

# shellcheck source=/dev/null
source ~/.profile

# If not running interactively, don't do anything
__is_shell_interactive || return

# Various PS1 aliases

Time12h="\T"
Time12a="\@"
PathShort="\w"
PathFull="\W"
NewLine="\n"
Jobs="\j"

# Reset
Color_Off='\e[0m'       # Text Reset

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

# Use "**" in pathname expansion will match files in subdirectories - Needs Bash 4+
shopt -s globstar >/dev/null 2>&1

# Disable extdebug because it causes issues with iTerm shell integration
shopt -u extdebug

# Use a different color for displaying the host name when we're logged into SSH
if __is_ssh_session; then
    HostColor=$Yellow
    if __is_in_tmux; then
        HostNameDisplay=""
    else
        HostNameDisplay=%M
    fi
else
    HostColor=$Brown
    HostNameDisplay=%m
fi

# disable the default virtualenv prompt change
# export VIRTUAL_ENV_DISABLE_PROMPT=1

PS1=\\[$White\\]$(__cute_time_prompt)\\[$Color_Off\\]' '\\[$BrightGreen\\]'\u'\\[$HostColor\\]'@\h'\\[$Color_Off\\]' $(__cute_pwd) % '
export PS1

__do_iterm2_shell_integration

# shellcheck source=/dev/null
source "${DOTFILES_CONFIG_ROOT}/git-prompt.sh" # defines __git_ps1

if declare -f chjava &>/dev/null; then
    chjava 22
fi

__do_eza_aliases

if __is_on_osx; then
    if [ -d "/opt/homebrew/bin" ]; then
        if [[ -f "$(brew --prefix)/etc/bash_completion.d/git-completion.bash" ]]; then
            # shellcheck source=/dev/null
            source "$(brew --prefix)/etc/bash_completion.d/git-completion.bash"
            # shellcheck source=/dev/null
            source "$(brew --prefix)/etc/bash_completion.d/git-prompt.sh"
        fi
    fi

    JAVA_HOME=$(/usr/libexec/java_home)
    export JAVA_HOME

    export PATH=$JAVA_HOME/bin:$PATH

    export PATH=${PATH}:$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools:$ANDROID_NDK
fi

__cute_shell_header

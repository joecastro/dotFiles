#! /bin/bash
#shellcheck disable=SC2034

#pragma once

# eval "`dircolors -b ~/.dircolorsrc`"

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

[ "${BASH_VERSINFO[0]}" -lt 4 ] && echo "WARN: This is a really old version of Bash. $BASH_VERSION"

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

export LS_OPTIONS='--color=auto'

# Check the window size after each command and update the values of lines and columns
shopt -s checkwinsize

# Use "**" in pathname expansion will match files in subdirectories - Needs Bash 4+
shopt -s globstar >/dev/null 2>&1

# Disable extdebug because it causes issues with iTerm shell integration
shopt -u extdebug

function __is_ssh_session() {
    if [ -n "$SSH_CLIENT" ] || [ -n "$SSH_TTY" ] || [ -n "$SSH_CONNECTION" ]; then
        return 0
    fi
    return 1
}

function __is_in_git_repo() {
    if git branch > /dev/null 2>&1; then
        return 0
    fi
    return 1
}

function __is_in_git_dir() {
    if git rev-parse --is-inside-git-dir | grep "true" > /dev/null 2>&1; then
        return 0
    fi
    return 1
}

function __is_in_repo() {
    local verbose=0
    if [[ -z "$1" ]]; then
        unset verbose
    fi

    if repo --show-toplevel > /dev/null 2>&1; then
        return 0
    fi

    if (( ${+verbose} )); then
        echo "error: Not in Android repo tree"
    fi

    return 1
}

function __is_interactive() {
    if [[ $- == *i* ]]; then
        return 0
    fi
    return 1
}

function __is_in_tmux() {
    if [ "$TERM" = "screen" ]; then
        return 1
    elif [ -n "$TMUX" ]; then
        return 0
    fi
    return 1
}

function __is_on_wsl() {
    grep -qE "(Microsoft|WSL)" /proc/version &> /dev/null
}

function __is_in_windows_drive() {
    if (( ${+WIN_SYSTEM_ROOT} )); then
        if test "${PWD##"$WIN_SYSTEM_ROOT"}" != "${PWD}"; then
            return 0
        fi
    fi
    return 1
}

function __is_on_osx() {
    if [[ "$(uname)" == "Darwin" ]]; then
        return 0
    fi
    return 1
}

function __is_on_windows() {
    if [[ "$(uname -s)" = "MINGW64_NT"* ]] || [[ "$(uname -s)" = "MSYS_NT"* ]]; then
        return 0
    fi
    return 1
}

function __is_on_unexpected_windows() {
    if [[ "$(uname -s)" = "MINGW32_NT"* ]]; then
        return 0
    fi
    return 1
}

function __is_on_unexpected_linux() {
    if [[ "$(uname -s)" = "Linux"* ]]; then
        return 0
    fi
    return 1
}

function __is_embedded_terminal() {
    # This isn't quite the same thing as running in an embedded terminal.
    # Code will launch an interactive shell to resolve environment variables.
    # This value can be used to detect that.
    if [[ "$VSCODE_RESOLVING_ENVIRONMENT" == "1" ]]; then
        return 0
    fi
    if [[ "$TERM_PROGRAM" == "vscode" ]]; then
        return 0
    fi
    return 1
}

# TODO: Similar to below TODO, consider not using unicode glyphs based on something like this...
unset RESTRICT_ASCII_CHARACTERS
EXPECT_NERD_FONTS=1

# emojipedia.org
ANCHOR_ICON=⚓
PIN_ICON=📌
HUT_ICON=🛖
HOUSE_ICON=🏠
TREE_ICON=🌲
DISK_ICON=💾
OFFICE_ICON=🏢
SNAKE_ICON=🐍
ROBOT_ICON=🤖

#Nerdfonts - https://www.nerdfonts.com/cheat-sheet
WINDOWS_ICON=
GITHUB_ICON=
GOOGLE_ICON=
VIM_ICON=
ANDROID_HEAD_ICON=󰀲
ANDROID_BODY_ICON=
PYTHON_ICON=
GIT_BRANCH_ICON=
GIT_COMMIT_ICON=
HOME_FOLDER_ICON=󱂵
TMUX_ICON=

NF_VIM_ICON=$(test -n "$EXPECT_NERD_FONTS" && echo $VIM_ICON || echo "{vim}")
NF_ANDROID_ICON=$(test -n "$EXPECT_NERD_FONTS" && echo "$ANDROID_BODY_ICON" || echo "$ROBOT_ICON")
NF_PYTHON_ICON=$(test -n "$EXPECT_NERD_FONTS" && echo "$PYTHON_ICON" || echo "$SNAKE_ICON")
NF_GIT_BRANCH_ICON=$(test -n "$EXPECT_NERD_FONTS" && echo "$GIT_BRANCH_ICON" || echo "(b)")
NF_GIT_COMMIT_ICON=$(test -n "$EXPECT_NERD_FONTS" && echo "$GIT_COMMIT_ICON" || echo "(d)")

function __cute_pwd() {
    if __is_in_git_repo; then
        if ! __is_in_git_dir; then
            # If we're in a git repo then show the current directory relative to the root of that repo.
            # These commands wind up spitting out an extra slash, so backspace to remove it on the console.
            echo -e "$ANCHOR_ICON$(git rev-parse --show-toplevel | xargs basename)/$(git rev-parse --show-prefix)\b"
        else
            echo "🚧"
        fi
        return 0
    fi

    # These should only match if they're exact.
    case "$PWD" in
        "$HOME")
            echo 🏠
            return 0
            ;;
        # ${WIN_USERPROFILE##*/})
        #    echo $WINDOWS_ICON$HOUSE_ICON
        #    ;;
        /)
            echo 🌲
            return 0
            ;;
    esac

    case "${PWD##*/}" in
        github)
            echo "$GITHUB_ICON"
            return 0
            ;;
        src | source | master | main)
            echo 💾
            return 0
            ;;
        work)
            echo 🏢
            return 0
            ;;
        *)
            ;;
    esac

    echo -n "${PWD##*/}"
    return 0
}

function __cute_time_prompt() {
    case "$(date +%Z)" in
        UTC)
            echo -n "$(date +'%_H:%Mz')"
            ;;
        *)
            echo -n "$(date +'%_H:%M %Z')"
            ;;
    esac
}

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

function __virtualenv_info() {
    if __is_in_tmux; then
        echo -n "$TMUX_ICON "
    fi
    # venv="${VIRTUAL_ENV##*/}"
    test -n "$VIRTUAL_ENV" && echo "$NF_PYTHON_ICON "
    test -n "$VIMRUNTIME" && echo "$NF_VIM_ICON "
}

# disable the default virtualenv prompt change
export VIRTUAL_ENV_DISABLE_PROMPT=1

PS1=\\[$White\\]$(__cute_time_prompt)\\[$Color_Off\\]' '\\[$BrightGreen\\]'\u'\\[$HostColor\\]'@\h'\\[$Color_Off\\]' $(__cute_pwd) % '
export PS1

# If using iTerm2, try for shell integration.
# When in SSH TERM_PROGRAM isn't getting propagated.
# iTerm profile switching requires shell_integration to be installed anyways.
if [[ "iTerm2" == "$LC_TERMINAL" ]]; then
    if [ ! -f "${DOTFILES_CONFIG_ROOT}/iterm2_shell_integration.bash" ]; then
        echo "Bootstrapping iTerm2 Shell Integration on a new machine through curl"
        curl -L https://iterm2.com/shell_integration/bash -o "${DOTFILES_CONFIG_ROOT}/iterm2_shell_integration.bash"
    fi
    # shellcheck disable=SC1091
    test -e "${DOTFILES_CONFIG_ROOT}/iterm2_shell_integration.bash" && \
        source "${DOTFILES_CONFIG_ROOT}/iterm2_shell_integration.bash"
fi

EFFECTIVE_DISTRIBUTION="Unhandled"
if __is_on_wsl; then
    EFFECTIVE_DISTRIBUTION="WSL"
elif __is_on_osx; then
    EFFECTIVE_DISTRIBUTION="OSX"
elif __is_on_unexpected_linux; then
    EFFECTIVE_DISTRIBUTION="Unexpected Linux environment"
elif __is_on_unexpected_windows; then
    EFFECTIVE_DISTRIBUTION="Unexpected Win32 environment"
elif __is_on_windows; then
    EFFECTIVE_DISTRIBUTION="Windows"
fi

if [ ! -f "${DOTFILES_CONFIG_ROOT}/git-prompt.sh" ]; then
    echo "Bootstrapping git-prompt installation on new machine through curl"
    curl -o "${DOTFILES_CONFIG_ROOT}/git-prompt.sh" \
    https://raw.githubusercontent.com/git/git/master/contrib/completion/git-prompt.sh
fi

# shellcheck source=/dev/null
source "${DOTFILES_CONFIG_ROOT}/git-prompt.sh" # defines __git_ps1

# echo $EFFECTIVE_DISTRIBUTION
# Variables
case $EFFECTIVE_DISTRIBUTION in
    OSX)
        if [ -f "$(brew --prefix)/etc/bash_completion.d/git-completion.bash" ]; then
            # shellcheck source=/dev/null
            source "$(brew --prefix)/etc/bash_completion.d/git-completion.bash"
            # shellcheck source=/dev/null
            source "$(brew --prefix)/etc/bash_completion.d/git-prompt.sh"
        fi

        export PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin
        JAVA_HOME=$(/usr/libexec/java_home)
        export JAVA_HOME

        export PATH=$JAVA_HOME/bin:$PATH

        # android / gradle / buck setup
        export ANDROID_HOME=/Users/$USER/Library/Android/sdk
        export ANDROID_SDK=$ANDROID_HOME
        export ANDROID_SDK_ROOT=$ANDROID_SDK
        export ANDROID_NDK=$ANDROID_SDK/ndk-bundle
        export ANDROID_NDK_HOME=$ANDROID_NDK
        unset ANDROID_NDK_REPOSITORY

        export PATH=${PATH}:$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools:$ANDROID_NDK

        # appengine setup
        export APPENGINE_HOME=~/Downloads/appengine-java-sdk-1.9.54
        export PATH=$PATH:$APPENGINE_HOME/bin/
        ;;
    Windows)

        export JAVA_HOME=/c/Program\ Files/Java/jdk1.8.0_161/bin/
        export PATH=$JAVA_HOME/bin:$PATH
        export PATH=/c/Program\ Files\ \(x86\)/Vim/vim81/:$PATH
        ;;
esac

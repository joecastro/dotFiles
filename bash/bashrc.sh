#!/bin/bash
# shellcheck disable=SC2034

#pragma once
#pragma validate-dotfiles

# shellcheck source=SCRIPTDIR/profile.sh
source ~/.profile

# Exit if not running interactively
__is_shell_interactive || return

source "${DOTFILES_CONFIG_ROOT}/colors.sh"

# shellcheck source=/dev/null
source "${DOTFILES_CONFIG_ROOT}/completion/git-completion.bash"

# PS1 components
Time12h="\T"
Time12a="\@"
PathShort="\w"
PathFull="\W"
NewLine="\n"
Jobs="\j"

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

function set_cursor_command_mode() { printf '\e[1 q'; }
function set_cursor_insert_mode() { printf '\e[5 q'; }

# Key bindings
bind '"\e[A": history-search-backward'
bind '"\e[B": history-search-forward'
bind '"\C-r": reverse-search-history'
bind '"\C-u": unix-line-discard'
bind '"\C-w": kill-line'

bind -m vi-command '"": "set_cursor_command_mode\n"'
bind -m vi-insert  '"": "set_cursor_insert_mode\n"'

set_cursor_insert_mode

function __print_git_worktree_prompt() {
    if __git_is_in_worktree; then
        colorize "$(__print_git_worktree)" "${PINK_FLAMINGO}"
    fi
}

function __generate_static_prompt_part() {
    local host_color="${COLOR_ANSI[yellow]}"
    local host_display="\h"

    if is_valid_rgb "${HOST_COLOR:-}"; then
        host_color="$(fg_rgb "${HOST_COLOR}")"
    fi

    if __is_in_tmux; then
        host_display=""
    elif ! __is_ssh_session && [ -n "${LOCALHOST_PREFERRED_DISPLAY}" ]; then
        host_display="${LOCALHOST_PREFERRED_DISPLAY}"
    fi

    echo -n "${COLOR_ANSI[green]}\u${COLOR_ANSI[yellow]}@${host_color}${host_display}${RESET} "
}

function __generate_preamble_color() {
    case "$1" in
        Git) echo -n "${COLOR_ANSI[green]}" ;;
        Repo) echo -n "${COLOR_ANSI[yellow]}" ;;
        Piper) echo -n "${COLOR_ANSI[blue]}" ;;
        *) echo -n "${RESET}" ;;
    esac
}

function __generate_dynamic_prompt_part() {
    local style="$1"
    local dynamic_part=""

    case "$style" in
        Git)
            dynamic_part+="$(__print_git_worktree_prompt)"
            dynamic_part+="$(colorize "$(__print_git_branch)" "$(__git_branch_color_hint)") "
            dynamic_part+="$(__print_git_pwd --no-branch) "
            ;;
        Repo)
            dynamic_part+="$(__print_repo_worktree) "
            dynamic_part+="$(__cute_pwd)"
            ;;
        Piper)
            dynamic_part+="$(__print_citc_workspace) "
            dynamic_part+="$(__cute_pwd)"
            ;;
        *)
            dynamic_part="$(__cute_pwd)"
            ;;
    esac

    echo -n "${dynamic_part}"
}

function __generate_prompt() {
    local END_OF_PROMPT_ICON="%"
    local ELEVATED_END_OF_PROMPT_ICON="#"

    local preamble=""
    preamble+="${COLOR_ANSI[red]}${PS1_PREAMBLE_PREFIX}"
    preamble+="$(__generate_preamble_color "$1")"
    # shellcheck disable=SC2016
    preamble+='$(__cute_time_prompt) '

    local static_part suffix
    static_part="$(__generate_static_prompt_part)"
    [ "$EUID" -eq 0 ] && suffix=" ${ELEVATED_END_OF_PROMPT_ICON} " || suffix=" ${END_OF_PROMPT_ICON} "

    echo -n "${preamble}${static_part}$(__generate_dynamic_prompt_part "$1")${suffix}${RESET}"
}

function __cute_prompt_command() {
    local last_exit=$?  # capture immediately!
    _dotTrace "__update_prompt"

    if [ ${last_exit} -ne 0 ]; then
        PS1_PREAMBLE_PREFIX="!"
    else
        PS1_PREAMBLE_PREFIX=""
    fi

    local last_pwd
    last_pwd="$(__cache_get UPDATE_PROMPT_PWD)"
    if [ "$last_pwd" = "$PWD" ]; then
        _dotTrace "__update_prompt - no change - done"
        return
    fi
    __cache_put UPDATE_PROMPT_PWD "$PWD"

    _dotTrace "__update_prompt - calculating new style (${PWD})"
    local new_style="None"

    if [ -n "$UNSMART_PROMPT" ]; then
        new_style="None"
    elif __is_in_repo; then
        new_style="Repo"
    elif __is_in_git_repo; then
        new_style="Git"
    elif __has_citc && __is_in_citc; then
        new_style="Piper"
    fi

    local current_style
    current_style="$(__cache_get ACTIVE_DYNAMIC_PROMPT_STYLE)"
    if [ "$current_style" != "$new_style" ]; then
        _dotTrace "__update_prompt - updating prompt to ${new_style}"
        PS1="$(__generate_prompt "$new_style")"
        __cache_put ACTIVE_DYNAMIC_PROMPT_STYLE "$new_style"
    fi
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

__cute_shell_header

#!/bin/bash
# shellcheck disable=SC2034

#pragma once
#pragma validate-dotfiles

# shellcheck source=SCRIPTDIR/profile.sh
source ~/.profile

# Exit if not running interactively
__is_shell_interactive || return

#pragma requires colors.sh
#pragma requires debug.sh
#pragma requires git_funcs.sh
#pragma requires completion/git-completion.bash

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
    local host_color="${COLOR_ANSI_YELLOW}"
    local host_display="\h"

    if is_valid_rgb "${HOST_COLOR:-}"; then
        host_color="$(fg_rgb "${HOST_COLOR}")"
    fi

    if __is_in_tmux; then
        host_display=""
    elif ! __is_ssh_session && [ -n "${LOCALHOST_PREFERRED_DISPLAY}" ]; then
        host_display="${LOCALHOST_PREFERRED_DISPLAY}"
    fi

    printf '%s' "${COLOR_ANSI_GREEN}\u${COLOR_ANSI_YELLOW}@${host_color}${host_display}${RESET} "
}

function __generate_preamble_color() {
    case "$1" in
        Git)   printf '%s' "${COLOR_ANSI_GREEN}" ;;
        Repo)  printf '%s' "${COLOR_ANSI_YELLOW}" ;;
        Piper) printf '%s' "${COLOR_ANSI_BLUE}" ;;
        *)     printf '%s' "${RESET}" ;;
    esac
}

function __generate_dynamic_prompt_part() {
    _dotTrace_enter "$@"
    local style="$1"
    local dynamic_part=""

    case "$style" in
        Git)
            # shellcheck disable=SC2016
            dynamic_part+='$(__print_git_worktree_prompt)'
            # shellcheck disable=SC2016
            dynamic_part+='$(__print_git_pwd)'
            ;;
        Repo)
            # shellcheck disable=SC2016
            dynamic_part+='$(__print_repo_worktree) '
            # shellcheck disable=SC2016
            dynamic_part+='$(__cute_pwd)'
            ;;
        *)
            # shellcheck disable=SC2016
            dynamic_part+='$(__cute_pwd)'
            ;;
    esac

    printf '%s' "${dynamic_part}"
    _dotTrace_exit
}

function __generate_prompt() {
    _dotTrace_enter "$@"

    local END_OF_PROMPT_ICON="%"
    local ELEVATED_END_OF_PROMPT_ICON="#"

    local preamble=""
    preamble+="${COLOR_ANSI_RED}${PS1_PREAMBLE_PREFIX}"
    preamble+="$(__generate_preamble_color "$1")"
    # shellcheck disable=SC2016
    preamble+='$(__cute_time_prompt) $(__virtualenv_info " ")'

    local static_part suffix
    static_part="$(__generate_static_prompt_part)"
    [ "$EUID" -eq 0 ] && suffix=" ${ELEVATED_END_OF_PROMPT_ICON} " || suffix=" ${END_OF_PROMPT_ICON} "

    local local_ps1
    local_ps1="${preamble}${static_part}$(__generate_dynamic_prompt_part "$1")${suffix}${RESET}"
    _dotTrace "Generated PS1: \"${local_ps1}\""
    printf '%s' "${local_ps1}"
    _dotTrace_exit
}

function __cute_prompt_command() {
    local -i last_exit=$?  # capture immediately!
    _dotTrace_enter "$@"
    _dotTrace "Previous PS1: \"${PS1}\" and last exit code: ${last_exit}"

    if [ ${last_exit} -ne 0 ]; then
        PS1_PREAMBLE_PREFIX="!"
    else
        PS1_PREAMBLE_PREFIX=""
    fi

    local last_pwd
    last_pwd="$(__cache_get UPDATE_PROMPT_PWD)"
    if [ "$last_pwd" = "$PWD" ]; then
        _dotTrace "no change"
        _dotTrace_exit "$last_exit"
        return
    fi
    __cache_put UPDATE_PROMPT_PWD "$PWD"

    if ! __is_embedded_terminal && ! __is_tool_window; then
        _dotTrace "Auto-activating venv if needed"
        __auto_activate_venv
    fi

    _dotTrace "calculating new style (${PWD})"
    local new_style="None"

    if [ -n "$UNSMART_PROMPT" ]; then
        new_style="None"
    elif __is_in_repo; then
        new_style="Repo"
    elif __git_is_in_repo; then
        new_style="Git"
    fi
    _dotTrace "new style: ${new_style}"

    local current_style
    current_style="$(__cache_get ACTIVE_DYNAMIC_PROMPT_STYLE)"
    if [ "$current_style" == "$new_style" ]; then
        _dotTrace "no change in style"
        _dotTrace_exit $last_exit
        return
    fi

    _dotTrace "updating prompt to ${new_style}"
    PS1="$(__generate_prompt "$new_style")"
    export PS1
    _dotTrace "Updated PS1: \"${PS1}\""
    __cache_put ACTIVE_DYNAMIC_PROMPT_STYLE "$new_style"

    _dotTrace_exit "$last_exit"
}

PS1=""
export PS1

if __is_bash_preexec_loaded; then
    # PROMPT_COMMAND was already hooked. Don't override it.
    precmd_functions+=("__cute_prompt_command")
else
    PROMPT_COMMAND=__cute_prompt_command
    export PROMPT_COMMAND
fi

# Workaround for https://github.com/ghostty-org/ghostty/discussions/5582
# Ghostty is using bash-preexec for its shell integration which only works
# on newer bash anyways.
if __is_ghostty_terminal && ! __is_shell_old_bash && ! __is_ssh_session; then

_dotTrace "Setting up Ghostty shell integration"

# This is set to 1 when we're executing a command so that we don't
# send prompt marks multiple times.
_ghostty_executing=""
_ghostty_last_reported_cwd=""

_GHOSTTY_PS0_SUFFIX=""
_GHOSTTY_PS1_SUFFIX=""
_GHOSTTY_PS2_SUFFIX=""

# Remove suffix helper
function __remove_suffix() {
    local str="$1"
    local suffix="$2"
    if [[ "$str" == *"$suffix" ]]; then
        builtin printf '%s' "${str%"$suffix"}"
    else
        builtin printf '%s' "$str"
    fi
}

function __ghostty_precmd2() {
    local -i ret="$?"

    _dotTrace_enter "$@"

    # Suffixes used for Ghostty integration
    local ghostty_marks='\[\e]133;B\a\]'
    local ghostty_multiline='\[\e]133;A;k=s\a\]'
    local ghostty_cursor='\[\e[5 q\]'
    local ghostty_cursor0='\[\e[0 q\]'
    local ghostty_title='\[\e]2;\w\a\]'

    if test "$_ghostty_executing" != "0"; then
      _dotTrace "Ghostty shell integration - executing command"

      # Marks
      _GHOSTTY_PS1_SUFFIX+="$ghostty_marks"
      _GHOSTTY_PS2_SUFFIX+="$ghostty_marks"

      # bash doesn't redraw the leading lines in a multiline prompt so
      # mark the last line as a secondary prompt (k=s) to prevent the
      # preceding lines from being erased by ghostty after a resize.
      if [[ "${PS1}" == *"\n"* || "${PS1}" == *$'\n'* ]]; then
        _GHOSTTY_PS1_SUFFIX+="$ghostty_multiline"
      fi

      # Cursor
      if test "$GHOSTTY_SHELL_INTEGRATION_NO_CURSOR" != "1"; then
        _GHOSTTY_PS1_SUFFIX+="$ghostty_cursor"
        _GHOSTTY_PS0_SUFFIX+="$ghostty_cursor0"
      fi

      # Title (working directory)
      if [[ "$GHOSTTY_SHELL_INTEGRATION_NO_TITLE" != 1 ]]; then
        _GHOSTTY_PS1_SUFFIX+="$ghostty_title"
      fi

      # Update PS0, PS1, PS2 with the suffixes
      PS0="${PS0}${_GHOSTTY_PS0_SUFFIX}"
      PS1="${PS1}${_GHOSTTY_PS1_SUFFIX}"
      PS2="${PS2}${_GHOSTTY_PS2_SUFFIX}"
    fi

    if test "$_ghostty_executing" != ""; then
      # End of current command. Report its status.
      builtin printf "\e]133;D;%s;aid=%s\a" "$ret" "$BASHPID"
    fi

    # unfortunately bash provides no hooks to detect cwd changes
    # in particular this means cwd reporting will not happen for a
    # command like cd /test && cat. PS0 is evaluated before cd is run.
    if [[ "$_ghostty_last_reported_cwd" != "$PWD" ]]; then
      _ghostty_last_reported_cwd="$PWD"
      builtin printf "\e]7;kitty-shell-cwd://%s%s\a" "$HOSTNAME" "$PWD"
    fi

    # Fresh line and start of prompt.
    builtin printf "\e]133;A;aid=%s\a" "$BASHPID"
    _ghostty_executing=0

    _dotTrace_exit "$ret"
}

function __ghostty_preexec2() {
    local -i rc=$?
    _dotTrace_enter "$@"

    builtin local cmd="$1"

    PS0="$(__remove_suffix "$PS0" "$_GHOSTTY_PS0_SUFFIX")"
    PS1="$(__remove_suffix "$PS1" "$_GHOSTTY_PS1_SUFFIX")"
    PS2="$(__remove_suffix "$PS2" "$_GHOSTTY_PS2_SUFFIX")"
    _GHOSTTY_PS0_SUFFIX=""
    _GHOSTTY_PS1_SUFFIX=""
    _GHOSTTY_PS2_SUFFIX=""

    # Title (current command)
    if [[ -n $cmd && "$GHOSTTY_SHELL_INTEGRATION_NO_TITLE" != 1 ]]; then
      builtin printf "\e]2;%s\a" "${cmd//[[:cntrl:]]}"
    fi

    # End of input, start of output.
    builtin printf "\e]133;C;\a"
    _ghostty_executing=1

    _dotTrace_exit "$rc"
}

function __array_index_of() {
    local array_name="$1"
    local item="$2"
    local -n arr="$array_name"
    for i in "${!arr[@]}"; do
        if [[ "${arr[$i]}" == "$item" ]]; then
            printf '%d' "$i"
            return 0
        fi
    done
    return 1
}

function __patch_array() {
    _dotTrace_enter "$@"
    # Usage: __patch_array array_name old_item new_item
    local array_name="$1"
    local old_item="$2"
    local new_item="$3"
    local -n arr="$array_name"
    local idx
    if idx=$(__array_index_of "$array_name" "$old_item"); then
        arr[$idx]="$new_item"
        _dotTrace_exit 0
        return
    fi

    _dotTrace "'$old_item' not found in array '$array_name'"
    arr+=("$new_item")
    _dotTrace_exit
}

__patch_array precmd_functions "__ghostty_precmd" "__ghostty_precmd2"
__patch_array preexec_functions "__ghostty_preexec" "__ghostty_preexec2"

unset -f __array_index_of
unset -f __patch_array

HAS_UPDATED_FOR_GHOSTTY=1

_dotTrace "Ghostty shell integration updated"

fi

__do_iterm2_shell_integration
__do_vscode_shell_integration
__do_konsole_shell_integration
__do_eza_aliases

if declare -f chjava &>/dev/null; then
    chjava 22
fi

_dotTrace "Sourcing rbenv"
[ -d "$HOME/.rbenv/bin" ] && export PATH="$HOME/.rbenv/bin:$PATH"
[ -x "$(command -v rbenv)" ] && eval "$(rbenv init -)"

_dotTrace "Sourcing Homebrew"
# Set PATH, MANPATH, etc., for Homebrew.
[ -d "/opt/homebrew/bin" ] && eval "$(/opt/homebrew/bin/brew shellenv)"

_dotTrace "Sourcing Rust"
# shellcheck disable=SC1090
[ -s ~/.cargo/env ] && source ~/.cargo/env

_dotTrace "Sourcing nvm"
if __has_homebrew && [[ -d "$(brew --prefix nvm)" ]]; then
    _dotTrace "Using Homebrew nvm"
    [ -s "$(brew --prefix nvm)/nvm.sh" ] && \. "$(brew --prefix nvm)/nvm.sh"
    if __is_shell_bash; then
        # shellcheck disable=SC1091
        [ -s "$(brew --prefix nvm)/etc/bash_completion.d/nvm" ] && \. "$(brew --prefix nvm)/etc/bash_completion.d/nvm"
    fi
else
    # shellcheck disable=SC1091
    [ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"

    if __is_shell_bash; then
        # shellcheck disable=SC1091
        [ -s "$NVM_DIR/bash_completion" ] && source "$NVM_DIR/bash_completion"
    fi
fi
_dotTrace "Finished loading nvm - This takes a stupidly long time on Linux... especially zsh."

__cute_shell_header

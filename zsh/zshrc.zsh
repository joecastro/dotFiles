#! /bin/zsh

#pragma once

#pragma validate-dotfiles

# In some contexts .zprofile isn't sourced (e.g. when started inside the Python debug console.)
# shellcheck disable=SC1090
source ${ZDOTDIR:-$HOME}/.zprofile

# Useful reference: https://scriptingosx.com/2019/07/moving-to-zsh-part-7-miscellanea/

# autoload -Uz promptinit; promptinit
# prompt fire

HISTFILE=${ZDOTDIR:-$HOME}/.zsh_history
SAVEHIST=5000
HISTSIZE=2000

# Remove mode switching delay.
KEYTIMEOUT=5

# disable the default virtualenv prompt change
VIRTUAL_ENV_DISABLE_PROMPT=1

END_OF_PROMPT_ICON=${ICON_MAP[MD_GREATER_THAN]}
ELEVATED_END_OF_PROMPT_ICON="$"

fpath=("${DOTFILES_CONFIG_ROOT}/zfuncs" $fpath)

autoload -Uz async && async

async_init

# Color cheat sheet: https://jonasjacek.github.io/colors/
autoload -U colors && colors

setopt NO_CASE_GLOB
setopt AUTO_CD

setopt PROMPT_SUBST
setopt SHARE_HISTORY
setopt EXTENDED_HISTORY
setopt HIST_IGNORE_ALL_DUPS

setopt CORRECT

# Vim mode
bindkey -v

bindkey -v '^?' backward-delete-char

bindkey ^R history-incremental-search-backward
bindkey ^S history-incremental-search-forward

bindkey "^[[A" history-beginning-search-backward # up arrow bindkey
bindkey "^[[B" history-beginning-search-forward # down arrow bindkey
bindkey \^U backward-kill-line
bindkey \^W kill-line
bindkey "\e[3~" delete-char

autoload -Uz edit-command-line
zle -N edit-command-line
bindkey -M vicmd v edit-command-line

# Use modern completion system
autoload -Uz compinit; compinit

# $PATH is tied to $path - Can use one as an array and the other as a scalar.
typeset -U path # force unique values.

zstyle ':completion:*' verbose true
zstyle ':completion:*' auto-description 'specify: %d'
# zstyle ':completion:*' list-colors ''
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}
# zstyle ':completion:*' completer _expand _complete _correct _approximate
# zstyle ':completion:*' format 'Completing %d'
# zstyle ':completion:*' group-name ''
# zstyle ':completion:*' menu select=2
# zstyle ':completion:*' list-prompt %SAt %p: Hit TAB for more, or the character to insert%s
# zstyle ':completion:*' matcher-list '' 'm:{a-z}={A-Z}' 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=* l:|=*'
# zstyle ':completion:*' menu select=long
# zstyle ':completion:*' select-prompt %SScrolling active: current selection at %p%s
# zstyle ':completion:*' use-compctl false
# zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;31'
# zstyle ':completion:*:kill:*' command 'ps -u $USER -o pid,%cpu,tty,cputime,cmd'

# ZSH's git-completion needs git's bash completion script installed. :shrug:
zstyle ':completion:*:*:git:*' script "${DOTFILES_CONFIG_ROOT}/completion/git-completion.bash"

# Set cursor style (DECSCUSR), VT520.
# 0 ⇒ blinking block.
# 1 ⇒ blinking block (default).
# 2 ⇒ steady block.
# 3 ⇒ blinking underline.
# 4 ⇒ steady underline.
# 5 ⇒ blinking bar, xterm.
# 6 ⇒ steady bar, xterm.

function _set_cursor_beam() {
   echo -ne '\e[5 q'
}

function _set_cursor_block() {
   echo -ne '\e[1 q'
}

function zle-keymap-select {
    case $KEYMAP in
    vicmd)
        _set_cursor_block
        ;;
    viins|main)
        _set_cursor_beam
        ;;
    esac
}

zle -N zle-keymap-select

zle-line-finish() {
    _set_cursor_block
}

zle -N zle-line-finish

zle-line-init() {
    _set_cursor_beam
}

zle -N zle-line-init

# Finish all the autoloads before sourcing. Some scripts presume compinit and no more zle's
source "${HOME}/.config/zshext/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"

chpwd_functions=($chpwd_functions __update_prompt __auto_apply_venv_on_chpwd)

# Use beam shape cursor for each new prompt.
preexec_functions=($preexec_functions _set_cursor_beam)

precmd_functions=($precmd_functions __update_prompt)

function __print_git_worktree_prompt() {
    if __git_is_in_worktree; then
        local PINK_FLAMINGO_FG="%F{#ff5fff}"
        echo -ne "%{$PINK_FLAMINGO_FG%}$(__print_git_worktree) "
    fi
}

function __update_prompt() {
    _dotTrace "__update_prompt"

    function __generate_static_prompt_part() {
        local PromptHostColor="$fg[yellow]"
        local PromptHostName="%m"

        if (( ${+HOST_COLOR} )); then
            PromptHostColor="%F{${HOST_COLOR}}"
        fi

        if __is_in_tmux; then
            PromptHostName=""
        elif ! __is_ssh_session && [[ -n ${LOCALHOST_PREFERRED_DISPLAY} ]]; then
            PromptHostName=${LOCALHOST_PREFERRED_DISPLAY}
        fi

        # All optional segments have spaces embedded in the output suffix if non-empty.
        echo -n '%{$fg[green]%}$USER%{$fg[yellow]%}@%B%{'${PromptHostColor}'%}'${PromptHostName}'%{$reset_color%} '
    }

    function __generate_prompt() {
        local preamble=''
        local dynamic_part=''
        local style="$1"
        case "${style}" in
        "Git")
            preamble="%{$fg[green]%}"

            dynamic_part+='$(__print_git_worktree_prompt)'
            dynamic_part+='$(__echo_colored "$(__git_branch_color_hint)" "$(__print_git_branch)") '
            dynamic_part+='$(__print_git_pwd --no-branch)'
            ;;
        "Repo")
            preamble="%{$fg[yellow]%}"

            dynamic_part+='$(__print_repo_worktree) '
            dynamic_part+='$(__cute_pwd)'
            ;;
        "Piper")
            preamble="%{$fg[blue]%}"

            dynamic_part+='$(__print_citc_workspace) '
            dynamic_part+='$(__cute_pwd)'
            ;;
        *)
            preamble="%{$reset_color%}"
            dynamic_part='$(__cute_pwd)'
        esac

        preamble+='$(__cute_time_prompt) $(__virtualenv_info " ")'

        local static=$(__generate_static_prompt_part)
        local suffix=' %(!.$ELEVATED_END_OF_PROMPT_ICON.$END_OF_PROMPT_ICON) '

        echo -n "${preamble}${static}${dynamic_part}${suffix}"
    }

    _dotTrace "__update_prompt - calculating new style"
    local new_dynamic_style
    if (( ${+UNSMART_PROMPT} )); then
        new_dynamic_style="None"
    elif __is_in_repo; then
        new_dynamic_style="Repo"
    elif __is_in_git_repo; then
        new_dynamic_style="Git"
    elif __has_citc && __is_in_citc; then
        new_dynamic_style="Piper"
    else
        new_dynamic_style="None"
    fi

    local active_dynamic_prompt_style=$(__cache_get "ACTIVE_DYNAMIC_PROMPT_STYLE")

    if [[ "${active_dynamic_prompt_style}" != "${new_dynamic_style}" ]]; then
        _dotTrace "__update_prompt - updating prompt to ${new_dynamic_style}"
        PROMPT="$(__generate_prompt ${new_dynamic_style})"
        __cache_put "ACTIVE_DYNAMIC_PROMPT_STYLE" "${new_dynamic_style}"
    fi
    _dotTrace "__update_prompt - done"
}

PROMPT="XXX"
__update_prompt
RPROMPT=''
# RPOMPT+='%* '

if ! __is_tool_window && ! __z_is_embedded_terminal; then
    function __auto_apply_venv_on_chpwd() {
        # If I am no longer in the same directory hierarchy as the venv that was last activated, deactivate.
        if [[ -n "${VIRTUAL_ENV}" ]]; then
            local P_DIR="$(dirname "$VIRTUAL_ENV")"
            if [[ "$PWD"/ != "${P_DIR}"/* ]] && command -v deactivate &> /dev/null; ; then
                echo "${ICON_MAP[PYTHON]} Deactivating venv for ${P_DIR}"
                deactivate
            fi
        fi

        # If I enter a directory with a .venv and I am already activated with another one, let me know but don't activate.
        if [[ -d ./.venv ]]; then
            if [[ -z "$VIRTUAL_ENV" ]]; then
                source ./.venv/bin/activate
                echo "${ICON_MAP[PYTHON]} Activating venv with $(python --version) for $PWD/.venv"
            # else: CONSIDER: test "$PWD" -ef "$VIRUAL_ENV" && "🐍 Avoiding implicit activation of .venv environment because $VIRTUAL_ENV is already active"
            fi
        fi
    }
fi

__do_iterm2_shell_integration
__do_vscode_shell_integration
__do_konsole_shell_integration
__do_eza_aliases

# echo "Welcome to $(__z_effective_distribution)!"
case "$(__z_effective_distribution)" in
"GLINUX")
    # echo "GLinux zshrc load complete"
    __on_glinux_zshrc_load_complete

    ;;
"OSX")
    # echo "OSX zshrc load complete"
    if __has_homebrew; then
        gnubin_path="$(brew --prefix)/opt/coreutils/libexec/gnubin"
        if [ -d "${gnubin_path}" ]; then
            path=("${gnubin_path}" "${path[@]}")
        fi
        unset gnubin_path
    fi

    # RPROMPT='$(battery_charge)'
    chjava 22

    if declare -f __on_gmac_zshrc_load_complete > /dev/null; then
        __on_gmac_zshrc_load_complete
    fi

    ;;
"WSL")
    export WIN_SYSTEM_DRIVE=$(powershell.exe '$env:SystemDrive')
    export WIN_SYSTEM_ROOT="/mnt/${WIN_SYSTEM_DRIVE:0:1:l}"
    export WIN_USERNAME=$(powershell.exe '$env:UserName')
    export WIN_USERPROFILE=$(echo $(wslpath $(powershell.exe '$env:UserProfile')) | sed $'s/\r//')

    typeset -a WSL_WINDOWS_VIRTUALENV_ID=("__is_on_wsl && __is_in_windows_drive" "ICON_MAP[WINDOWS]" "blue")
    typeset -a WSL_LINUX_VIRTUALENV_ID=("__is_on_wsl && ! __is_in_windows_drive" "ICON_MAP[LINUX_PENGUIN]" "blue")
    VIRTUALENV_ID_FUNCS+=(WSL_WINDOWS_VIRTUALENV_ID WSL_LINUX_VIRTUALENV_ID)

    # export WIN_USERPROFILE=$(wslpath $(powershell.exe '$env:UserProfile'))

    alias winGo='pushd $WIN_USERPROFILE'
    ;;
esac

__cute_shell_header

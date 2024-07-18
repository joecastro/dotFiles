#! /bin/zsh

#pragma once

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
# Repo is implemented in terms of worktrees, so this gets noisy.
SKIP_WORKTREE_IN_ANDROID_REPO=0

END_OF_PROMPT_ICON=${ICON_MAP[MD_GREATER_THAN]}
ELEVATED_END_OF_PROMPT_ICON="$"

fpath=("${DOTFILES_CONFIG_ROOT}/zfuncs" $fpath)

# defines __git_ps1
[[ -f "${DOTFILES_CONFIG_ROOT}/git-prompt.sh" ]] && source "${DOTFILES_CONFIG_ROOT}/git-prompt.sh"
[[ -f "~/.zshext/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]] \
    && source "~/.zshext/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"

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

chpwd_functions=($chpwd_functions __update_prompt __auto_apply_venv_on_chpwd)

# Use beam shape cursor for each new prompt.
preexec_functions=($preexec_functions _set_cursor_beam)

precmd_functions=($precmd_functions __update_prompt)

ACTIVE_DYNAMIC_PROMPT_STYLE="Unknown"

function __generate_prompt() {
    local style="${1:-None}"
    local ACTIVE_TIME_COLOR="%{$fg[white]%}"
    case "${style}" in
    "Git")
        ACTIVE_TIME_COLOR="%{$fg[green]%}"
        ;;
    "Repo")
        ACTIVE_TIME_COLOR="%{$fg[yellow]%}"
        ;;
    esac

    local preamble='${ACTIVE_TIME_COLOR}$(__cute_time_prompt) $(__virtualenv_info "%{${reset_colors}%} ")'
    local static="$(__generate_static_prompt_part)"
    local dynamic="$(__generate_dynamic_prompt_part $style)"
    local suffix=' %(!.$ELEVATED_END_OF_PROMPT_ICON.$END_OF_PROMPT_ICON) '

    echo -n "${preamble}${static}${dynamic}${suffix}"
}

function __update_prompt() {
    local new_dynamic_style
    if __is_in_repo; then
        new_dynamic_style="Repo"
    elif __is_in_git_repo; then
        new_dynamic_style="Git"
    else
        new_dynamic_style="None"
    fi

    if [[ "${ACTIVE_DYNAMIC_PROMPT_STYLE}" != "${new_dynamic_style}" ]]; then
        PROMPT="$(__generate_prompt ${new_dynamic_style})"
        ACTIVE_DYNAMIC_PROMPT_STYLE="${new_dynamic_style}"
    fi
}

function __print_git_worktree() {
    if ! __is_in_git_repo; then
        echo -n ""
        return 1
    fi

    if __is_in_git_dir; then
        echo -n "${fg[yellow]%}${ICON_MAP[COD_TOOLS]} "
        return 0
    fi

    local COMMIT_TEMPLATE_STRING=$([[ ${EXPECT_NERD_FONTS} = 0 ]] && echo "${ICON_MAP[GIT_COMMIT]}%s" || echo "%s")
    local COMMIT_MOD_TEMPLATE_STRING=$([[ ${EXPECT_NERD_FONTS} = 0 ]] && echo "${ICON_MAP[GIT_COMMIT]}%s*" || echo "{%s *}")
    local BRANCH_TEMPLATE_STRING=$([[ ${EXPECT_NERD_FONTS} = 0 ]] && echo "${ICON_MAP[GIT_BRANCH]}%s" || echo "(%s)")
    local BRANCH_MOD_TEMPLATE_STRING=$([[ ${EXPECT_NERD_FONTS} = 0 ]] && echo "${ICON_MAP[GIT_BRANCH]}%s*" || echo "{%s *}")

    local PINK_FLAMINGO_FG="%F{#ff5fff}"

    local ROOT_WORKTREE=$(git worktree list | head -n1 | awk '{print $1;}')
    local ACTIVE_WORKTREE=$(git worktree list | grep "$(git rev-parse --show-toplevel)" | head -n1 | awk '{print $1;}')
    git status | grep "HEAD detached" > /dev/null 2>&1
    local IS_DETACHED_HEAD=$?
    git status | grep "nothing to commit" > /dev/null 2>&1
    local IS_NOTHING_TO_COMMIT=$?

    if [[ "${ROOT_WORKTREE}" != "${ACTIVE_WORKTREE}" ]]; then
        local SUBMODULE_WORKTREE=$(git rev-parse --show-superproject-working-tree)
        if [[ "${SUBMODULE_WORKTREE}" == "" ]]; then
            echo -n "%{$fg[green]%}${ICON_MAP[OCT_FILE_SUBMODULE]}%{$PINK_FLAMINGO_FG%}${ROOT_WORKTREE##*/}:%{$fg[green]%}${ACTIVE_WORKTREE##*/} "
        else
            echo -n "%{$PINK_FLAMINGO_FG%}${ICON_MAP[COD_FILE_SUBMODULE]}${SUBMODULE_WORKTREE##*/} "
        fi
    fi

    if [[ "${IS_DETACHED_HEAD}" == "0" ]]; then
        if [[ "${IS_NOTHING_TO_COMMIT}" == "0" ]]; then
            echo -ne "%{$fg[red]%}"$(__git_ps1 ${COMMIT_TEMPLATE_STRING})"%{$reset_color%} "
        else
            echo -ne "%{$fg[red]%}"$(__git_ps1 ${COMMIT_MOD_TEMPLATE_STRING})"%{$reset_color%} "
        fi
    else
        if [[ "${IS_NOTHING_TO_COMMIT}" == "0" ]]; then
            echo -ne "%{$fg[green]%}"$(__git_ps1 ${BRANCH_TEMPLATE_STRING})"%{$reset_color%} "
        else
            echo -ne "%{$fg[yellow]%}"$(__git_ps1 ${BRANCH_MOD_TEMPLATE_STRING})"%{$reset_color%} "
        fi
    fi
}

function __print_repo_worktree() {
    if ! __is_in_repo; then
        echo -n ""
        return 0
    fi

    local line="${ICON_MAP[ANDROID_BODY]}"
    local manifest_branch
    local current_branch
    local fg_color="%{$fg[red]%}"

    if ! manifest_branch=$(repo_print_manifest_branch); then
        line+="Unknown"
    else
        fg_color="%{$fg[green]%}"
        line="${ICON_MAP[ANDROID_BODY]}${manifest_branch}"
        if current_branch=$(repo_print_current_project); then
            line+=":${current_branch}"
        fi
    fi

    echo -n "${fg_color}${line}%{$reset_color%} "
}

function __generate_static_prompt_part() {
    local SELECTIVE_YELLOW_FG="%F{#ffb506}"

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

function __generate_dynamic_prompt_part() {
    local style=$1
    local prompt_builder=''

    if [[ "${style}" == "Git" ]]; then
        prompt_builder+='$(__print_git_worktree)'
    elif [[ "${style}" == "Repo" ]]; then
        prompt_builder+='$(__print_repo_worktree)'
    fi

    # if declare -f __print_citc_workspace > /dev/null; then
    #     prompt_builder+='$(__print_citc_workspace)'
    # fi
    prompt_builder+='$(__cute_pwd)'

    echo -n ${prompt_builder}
}

PROMPT="$(__generate_prompt None)"
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

__do_eza_aliases

# echo "Welcome to $(__z_effective_distribution)!"
case "$(__z_effective_distribution)" in
"GLinux")
    # echo "GLinux zshrc load complete"
    if declare -f __on_glinux_zshrc_load_complete > /dev/null; then
        __on_glinux_zshrc_load_complete
    fi

    ;;
"OSX")
    # echo "OSX zshrc load complete"
    if [[ -f "${DOTFILES_CONFIG_ROOT}/osx_funcs.zsh" ]]; then
        source "${DOTFILES_CONFIG_ROOT}/osx_funcs.zsh"
        # RPROMPT='$(battery_charge)'
        chjava 22
    fi

    if command -v brew > /dev/null; then
        [[ -f "$(brew --prefix)/opt/zsh-git-prompt/zshrc.sh" ]] && source "$(brew --prefix)/opt/zsh-git-prompt/zshrc.sh"

        if [ -d "$(brew --prefix)/opt/coreutils/libexec/gnubin" ]; then
            PATH="$(brew --prefix)/opt/coreutils/libexec/gnubin:$PATH"
        fi
    fi

    if ! __is_ssh_session && ! command -v code &> /dev/null; then
        echo "## CLI for VSCode is unavailable. Check https://code.visualstudio.com/docs/setup/mac"
    fi

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

    alias winGo='pushd $WIN_USERPROFILE; cd .'
    ;;
esac

__cute_shell_header
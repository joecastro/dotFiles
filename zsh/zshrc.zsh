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

_prompt_executing=""
function __konsole_integration_precmd() {
    local ret="$?"
    if test "$_prompt_executing" != "0"
    then
      _PROMPT_SAVE_PS1="$PS1"
      _PROMPT_SAVE_PS2="$PS2"
      PS1=$'%{\e]133;P;k=i\a%}'$PS1$'%{\e]133;B\a\e]122;> \a%}'
      PS2=$'%{\e]133;P;k=s\a%}'$PS2$'%{\e]133;B\a%}'
    fi
    if test "$_prompt_executing" != ""
    then
       printf "\033]133;D;%s;aid=%s\007" "$ret" "$$"
    fi
    printf "\033]133;A;cl=m;aid=%s\007" "$$"
    _prompt_executing=0
}

function __konsole_integration_preexec() {
    PS1="$_PROMPT_SAVE_PS1"
    PS2="$_PROMPT_SAVE_PS2"
    printf "\033]133;C;\007"
    _prompt_executing=1
}

chpwd_functions=($chpwd_functions __update_prompt __auto_apply_venv_on_chpwd __update_title)

# Use beam shape cursor for each new prompt.
preexec_functions=($preexec_functions _set_cursor_beam)

precmd_functions=($precmd_functions __update_prompt)

function toggle_konsole_semantic_integration() {
    function is_konsole_semantic_integration_active() {
        [[ -n $(echo $preexec_functions | grep __konsole_integration_preexec) ]]
    }

    function add_konsole_semantic_integration() {
        if ! is_konsole_semantic_integration_active; then
            preexec_functions+=("__konsole_integration_preexec")
            precmd_functions+=("__konsole_integration_precmd")
        fi
    }

    function remove_konsole_semantic_integration() {
        if is_konsole_semantic_integration_active; then
            preexec_functions=(${preexec_functions:#__konsole_integration_preexec})
            precmd_functions=(${precmd_functions:#__konsole_integration_precmd})
        fi
    }

    if [[ "$1" == "0" ]]; then
        remove_konsole_semantic_integration
        return 0
    elif [[ "$1" == "1" ]]; then
        add_konsole_semantic_integration
        return 0
    fi

    if is_konsole_semantic_integration_active; then
        remove_konsole_semantic_integration
    else
        add_konsole_semantic_integration
    fi
}

toggle_konsole_semantic_integration 1

ACTIVE_DYNAMIC_PROMPT_STYLE="Unknown"

function __update_prompt() {
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
            dynamic_part='$(__print_git_info)'
            ;;
        "Repo")
            preamble="%{$fg[yellow]%}"
            dynamic_part='$(__print_repo_info)'
            ;;
        *)
            preamble="%{$reset_color%}"
            dynamic_part=''
        esac

        preamble+='$(__cute_time_prompt) $(__virtualenv_info " ")'
        dynamic_part+='$(__cute_pwd)'

        local static=$(__generate_static_prompt_part)
        local suffix=' %(!.$ELEVATED_END_OF_PROMPT_ICON.$END_OF_PROMPT_ICON) '

        echo -n "${preamble}${static}${dynamic_part}${suffix}"
    }

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

function __update_title() {
    local title=''
    title+=$(__virtualenv_info " ")
    case "${ACTIVE_DYNAMIC_PROMPT_STYLE}" in
    "Git")
        title+=$(__print_git_branch_short)
        ;;
    "Repo")
        title+=$(__print_repo_worktree)
        ;;
    esac

    title+=$(__cute_pwd_short)
    title=$(echo "${title}" | sed 's/%{[^}]*%}//g')

    for key val in "${(@kv)NF_ICON_MAP}"; do
        title="${title//${val}/${EMOJI_ICON_MAP[$key]}}"
    done

    if [[ "$1" == "--print" ]]; then
        echo "Title: ${title}"
    fi

    echo -ne "\e]0;${title}\a"
}

function __git_is_detached_head() {
    git status | grep "HEAD detached" > /dev/null 2>&1
}

function __git_is_nothing_to_commit() {
    git status | grep "nothing to commit" > /dev/null 2>&1
}

function __print_git_branch() {
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

    if __git_is_detached_head; then
        if __git_is_nothing_to_commit; then
            echo -ne "%{$fg[red]%}"$(__git_ps1 ${COMMIT_TEMPLATE_STRING})"%{$reset_color%} "
        else
            echo -ne "%{$fg[red]%}"$(__git_ps1 ${COMMIT_MOD_TEMPLATE_STRING})"%{$reset_color%} "
        fi
    else
        if __git_is_nothing_to_commit; then
            echo -ne "%{$fg[green]%}"$(__git_ps1 ${BRANCH_TEMPLATE_STRING})"%{$reset_color%} "
        else
            echo -ne "%{$fg[yellow]%}"$(__git_ps1 ${BRANCH_MOD_TEMPLATE_STRING})"%{$reset_color%} "
        fi
    fi
}

function __print_git_branch_short() {
    if ! __is_in_git_repo; then
        echo -n ""
        return 1
    fi

    if __is_in_git_dir; then
        echo -n "${fg[yellow]%}${ICON_MAP[COD_TOOLS]} "
        return 0
    fi

    local head_commit
    head_commit=$(git rev-parse --short HEAD)
    local matching_branch
    matching_branch=$(git show-ref --head | grep "$head_commit" | grep -o 'refs/remotes/[^ ]*' | head -n 1)

    local has_matching_branch=1
    if [ -n "$matching_branch" ]; then
        # echo -n "${matching_branch#refs/remotes/}"
        has_matching_branch=0
    fi

    local icon="$ICON_MAP[GIT_COMMIT]"
    if [[ "${has_matching_branch}" == 0 ]]; then
        icon="$ICON_MAP[GIT_BRANCH]"
    fi
    local icon_color="$fg[green]"
    if ! __git_is_nothing_to_commit; then
        icon_color="$fg[yellow]"
    fi

    echo -n "%{${icon_color}%}${icon}%{${reset_color}%} "
}

function __print_git_worktree() {
    if ! __is_in_git_repo || __is_in_git_dir; then
        echo -n ""
        return 1
    fi

    local PINK_FLAMINGO_FG="%F{#ff5fff}"

    local ROOT_WORKTREE=$(git worktree list | head -n1 | awk '{print $1;}')
    local ACTIVE_WORKTREE=$(git worktree list | grep "$(git rev-parse --show-toplevel)" | head -n1 | awk '{print $1;}')

    if [[ "${ROOT_WORKTREE}" != "${ACTIVE_WORKTREE}" ]]; then
        local SUBMODULE_WORKTREE=$(git rev-parse --show-superproject-working-tree)
        if [[ "${SUBMODULE_WORKTREE}" == "" ]]; then
            echo -n "%{$fg[green]%}${ICON_MAP[OCT_FILE_SUBMODULE]}%{$PINK_FLAMINGO_FG%}${ROOT_WORKTREE##*/}:%{$fg[green]%}${ACTIVE_WORKTREE##*/} "
        else
            echo -n "%{$PINK_FLAMINGO_FG%}${ICON_MAP[COD_FILE_SUBMODULE]}${SUBMODULE_WORKTREE##*/} "
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
    local fg_color="$fg[red]"

    if ! manifest_branch=$(repo_print_manifest_branch); then
        line+="Unknown"
    else
        fg_color="$fg[green]"
        line="${ICON_MAP[ANDROID_BODY]}${manifest_branch}"
        if current_branch=$(repo_print_current_project); then
            line+=":${current_branch}"
        fi
    fi

    echo -n "%{${fg_color}%}${line}%{$reset_color%} "
}

function __print_git_info() {
    if __is_in_git_repo; then
        __print_git_worktree
        __print_git_branch
    fi
}

function __print_repo_info() {
    __print_repo_worktree
    if __is_in_git_repo; then
        if ! __git_is_detached_head; then
            __print_git_branch
        else
            __print_git_branch_short
        fi
    fi
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

    alias winGo='pushd $WIN_USERPROFILE'
    ;;
esac

__cute_shell_header
# Initialize the title to the distribution. chpwd will handle it from here on out.
wintitle $(__z_effective_distribution)
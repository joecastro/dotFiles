#! /bin/zsh

#pragma once

# Useful reference: https://scriptingosx.com/2019/07/moving-to-zsh-part-7-miscellanea/

# autoload -Uz promptinit
# promptinit
# prompt fire

# Color cheat sheet: https://jonasjacek.github.io/colors/
autoload -U colors && colors


setopt NO_CASE_GLOB
setopt AUTO_CD

HISTFILE=${ZDOTDIR:-$HOME}/.zsh_history
SAVEHIST=5000
HISTSIZE=2000

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

fpath=("${DOTFILES_CONFIG_ROOT}/zfuncs" $fpath)
# Use modern completion system
autoload -Uz compinit && compinit

# $PATH is tied to $path - Can use one as an array and the other as a scalar.
typeset -U path # force unique values.

zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}
# zstyle ':completion:*' auto-description 'specify: %d'
# zstyle ':completion:*' completer _expand _complete _correct _approximate
# zstyle ':completion:*' format 'Completing %d'
# zstyle ':completion:*' group-name ''
# zstyle ':completion:*' menu select=2
# eval "$(dircolors -b)"
# zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}
# zstyle ':completion:*' list-colors ''
# zstyle ':completion:*' list-prompt %SAt %p: Hit TAB for more, or the character to insert%s
# zstyle ':completion:*' matcher-list '' 'm:{a-z}={A-Z}' 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=* l:|=*'
# zstyle ':completion:*' menu select=long
# zstyle ':completion:*' select-prompt %SScrolling active: current selection at %p%s
# zstyle ':completion:*' use-compctl false
# zstyle ':completion:*' verbose true

# zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;31'
# zstyle ':completion:*:kill:*' command 'ps -u $USER -o pid,%cpu,tty,cputime,cmd'

# Vim stuff

# Remove mode switching delay.
KEYTIMEOUT=5

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

CMD_LAST_START=0

# This gets run before any new command.
preexec() {
    CMD_LAST_START=$(date +%s)
    # Use beam shape cursor for each new prompt.
    _set_cursor_beam
}

function __cute_pwd_helper() {
    local ACTIVE_DIR=$1
    local SUFFIX=$2
    local ICO_COLOR=$reset_color

    # These should only match if they're exact.
    case "${ACTIVE_DIR}" in
    "${HOME}")
        echo -n %{${ICO_COLOR}%}${ICON_MAP[COD_HOME]}%{$reset_color%}${SUFFIX}
        return 0
        ;;
    "${WIN_USERPROFILE}")
        echo -n %{${ICO_COLOR}%}${ICON_MAP[WINDOWS]}%{$reset_color%}${SUFFIX}
        return 0
        ;;
    "/")
        echo -n %{${ICO_COLOR}%}${ICON_MAP[FAE_TREE]}%{$reset_color%}${SUFFIX}
        return 0
        ;;
    esac

    if (( ${+ANDROID_REPO_BRANCH} )); then
        if [[ "${ACTIVE_DIR##*/}" == "${ANDROID_REPO_BRANCH}" ]]; then
            echo -n %{${ICO_COLOR}%}${ICON_MAP[ANDROID_HEAD]}%{$reset_color%}${SUFFIX}
            return 0
        fi
    fi

    case "${ACTIVE_DIR##*/}" in
    "github")
        echo -n %{${ICO_COLOR}%}${ICON_MAP[GITHUB]}%{$reset_color%}${SUFFIX}
        return 0
        ;;
    "src" | "source")
        echo -n %{${ICO_COLOR}%}${ICON_MAP[COD_SAVE]}%{$reset_color%}${SUFFIX}
        return 0
        ;;
    "cloud")
        echo -n %{${ICO_COLOR}%}${ICON_MAP[CLOUD]}%{$reset_color%}${SUFFIX}
        return 0
        ;;
    "$USER")
        echo -n %{${ICO_COLOR}%}${ICON_MAP[ACCOUNT]}%{$reset_color%}${SUFFIX}
        return 0
        ;;
    *)
        ;;
    esac

    # If there is a suffix here then don't print the directory.
    if [[ ${SUFFIX} == "" ]]; then
        echo -n ${ACTIVE_DIR##*/}
    fi

    return 0
}

function __cute_pwd() {
    if __is_in_git_repo; then
        if ! __is_in_git_dir; then
            # If we're in a git repo then show the current directory relative to the root of that repo.
            # These commands wind up spitting out an extra slash, so backspace to remove it on the console.
            # Because this messes with the shell's perception of where the cursor is, make the anchor icon
            # appear like an escape sequence instead of a printed character.
            echo -e "%{${ICON_MAP[COD_PINNED]} %}$(git rev-parse --show-toplevel | xargs basename)/$(git rev-parse --show-prefix)\b"
        else
            echo -n $PWD
        fi
        return 0
    fi

    if [[ $PWD != "/" ]]; then
        __cute_pwd_helper "$(dirname $PWD)" "/"
    fi
    __cute_pwd_helper $PWD ""
    return 0
}

function __cute_pwd_short() {
    __cute_pwd_helper $PWD ""
}

function __cute_time_prompt() {
    case "$(date +%Z)" in
    UTC)
        echo -n "%Tz"
        ;;
    *)
        echo -n "%T %D{%Z}"
        ;;
    esac
}

function __print_git_worktree() {
    local PINK_FLAMINGO_FG="%F{#ff5fff}"
    if __is_in_repo && (( ${+SKIP_WORKTREE_IN_ANDROID_REPO} )); then
        echo ""
        return 0
    fi

    if ! __is_in_git_repo; then
        echo ""
        return 0
    fi

    if __is_in_git_dir; then
        echo "${fg[yellow]%}${ICON_MAP[COD_TOOLS]} "
        return 0
    fi

    local ROOT_WORKTREE=$(git worktree list | head -n1 | awk '{print $1;}')
    local ACTIVE_WORKTREE=$(git worktree list | grep "$(git rev-parse --show-toplevel)" | head -n1 | awk '{print $1;}')

    if [[ "${ROOT_WORKTREE}" == "${ACTIVE_WORKTREE}" ]]; then
        echo ""
        return 0
    fi

    local SUBMODULE_WORKTREE=$(git rev-parse --show-superproject-working-tree)
    if [[ "${SUBMODULE_WORKTREE}" == "" ]]; then
        echo "%{$fg[green]%}${ICON_MAP[OCT_FILE_SUBMODULE]}%{$PINK_FLAMINGO_FG%}${ROOT_WORKTREE##*/}:%{$fg[green]%}${ACTIVE_WORKTREE##*/} "
        return 0
    fi

    echo "%{$PINK_FLAMINGO_FG%}${ICON_MAP[COD_FILE_SUBMODULE]}${SUBMODULE_WORKTREE##*/} "
    return 0
}

function __print_repo_worktree() {
    if ! __is_in_repo; then
        echo ""
        return 0
    fi

    local MANIFEST_BRANCH=""

    if (( ${+ANDROID_REPO_ROOT} )) && [[ "${PWD}" == "${ANDROID_REPO_ROOT}" || "${PWD}" == "${ANDROID_REPO_ROOT}"/* ]]; then
        MANIFEST_BRANCH=$ANDROID_REPO_BRANCH
    else
        MANIFEST_BRANCH=$(repo info --outer-manifest -l -q "platform/no-project" 2>/dev/null | grep -i "Manifest branch" | sed 's/^Manifest branch: //')
    fi

    echo "%{$fg[green]%}${ICON_MAP[ANDROID_BODY]}${MANIFEST_BRANCH}%{$reset_color%} "
}

function __print_git_info() {
    if ! __is_in_git_repo || __is_in_git_dir; then
        echo ""
        return 0
    fi

    local COMMIT_TEMPLATE_STRING=$([[ ${EXPECT_NERD_FONTS} = 0 ]] && echo "${ICON_MAP[GIT_COMMIT]}%s" || echo "%s")
    local COMMIT_MOD_TEMPLATE_STRING=$([[ ${EXPECT_NERD_FONTS} = 0 ]] && echo "${ICON_MAP[GIT_COMMIT]}%s*" || echo "{%s *}")
    local BRANCH_TEMPLATE_STRING=$([[ ${EXPECT_NERD_FONTS} = 0 ]] && echo "${ICON_MAP[GIT_BRANCH]}%s" || echo "(%s)")
    local BRANCH_MOD_TEMPLATE_STRING=$([[ ${EXPECT_NERD_FONTS} = 0 ]] && echo "${ICON_MAP[GIT_BRANCH]}%s*" || echo "{%s *}")

    git status | grep "HEAD detached" > /dev/null 2>&1
    local IS_DETACHED_HEAD=$?
    git status | grep "nothing to commit" > /dev/null 2>&1
    local IS_NOTHING_TO_COMMIT=$?

    if [[ "${IS_DETACHED_HEAD}" == "0" ]]; then
        if [[ "${IS_NOTHING_TO_COMMIT}" == "0" ]]; then
            echo -e "%{$fg[red]%}"$(__git_ps1 ${COMMIT_TEMPLATE_STRING})"%{$reset_color%} "
        else
            echo -e "%{$fg[red]%}"$(__git_ps1 ${COMMIT_MOD_TEMPLATE_STRING})"%{$reset_color%} "
        fi
    else
        if [[ "${IS_NOTHING_TO_COMMIT}" == "0" ]]; then
            echo -e "%{$fg[green]%}"$(__git_ps1 ${BRANCH_TEMPLATE_STRING})"%{$reset_color%} "
        else
            echo -e "%{$fg[yellow]%}"$(__git_ps1 ${BRANCH_MOD_TEMPLATE_STRING})"%{$reset_color%} "
        fi
    fi
}

function __print_virtualenv_info() {
    __virtualenv_info
    if [[ "$?" == "0" ]]; then
        echo -n "%{${reset_colors}%} "
    fi
}

# Tricks adapted from anothermark@google
# Global variable to track command interruption
CMD_INTERRUPTED=1
CMD_LONG_RUNNING_THRESHOLD_SECONDS=15

# SIGINT (Ctrl-C) Handler
TRAPINT() {
    CMD_INTERRUPTED=0
    return $(( 128 + $1 ))
}

# Don't use this... Args will often get interpreted as regular expressions.
# Fix this at some point...
function __is_cmd_interactive() {
    ARG="$1 "
    local CMDS_THAT_NEVER_RETURN=(vim less ssh screen tmux tmx2)
    for cmd in "${CMDS_THAT_NEVER_RETURN[@]}"; do
        if [[ "${cmd} " =~ ^"${ARG}" ]]; then
            return 0
        fi
    done
    return 1
}

function __print_did_last_command_take_a_while() {
    if [[ "${CMD_INTERRUPTED}" == "0" ]] || [[ "${CMD_LAST_START}" == "0" ]]; then
        # Clear this.
        CMD_INTERRUPTED=1
        CMD_LAST_START=0
        echo -n ""
        return 0
    fi

    # if __is_cmd_interactive "$(fc -ln -1)"; then
    #     echo -n "SALUTE"
    #     return 0
    # fi

    local NOW=$(date +%s)
    local CMD_DURATION=$(( NOW - CMD_LAST_START ))
    CMD_LAST_START=0

    if [[ $CMD_DURATION -lt ${CMD_LONG_RUNNING_THRESHOLD_SECONDS} ]]; then
        echo -n ""
        return 0
    fi

    echo -n "%{$fg[yellow]%}${ICON_MAP[YAWN]}%{${reset_colors}%} "
    if (( ${+BE_LOUD_ABOUT_SLOW_COMMANDS} )); then
        if __is_iterm2_terminal; then
            if __is_in_screen ; then
                printf "\033Ptmux;\033\033]" && printf "1337;RequestAttention=fireworks"  && printf "\a\033\\"
            else
                printf "\033]" && printf "1337;RequestAttention=fireworks" && printf "\a"
            fi
        fi
    fi
    return 0;
}

# disable the default virtualenv prompt change
VIRTUAL_ENV_DISABLE_PROMPT=1
# Repo is implemented in terms of worktrees, so this gets noisy.
SKIP_WORKTREE_IN_ANDROID_REPO=0

END_OF_PROMPT_ICON=${ICON_MAP[MD_GREATER_THAN]}
ELEVATED_END_OF_PROMPT_ICON="$"

function __generate_standard_prompt() {
    local SELECTIVE_YELLOW_FG="%F{#ffb506}"

    local PromptHostColor=""
    local PromptHostName=""

    if (( ${+HOST_COLOR} )); then
        PromptHostColor="%F{${HOST_COLOR}}"
    # Use a different color for displaying the host name when we're logged into SSH
    elif __is_ssh_session; then
        PromptHostColor=$SELECTIVE_YELLOW_FG
    else
        PromptHostColor=$fg[yellow]
    fi

    if __is_in_tmux; then
        PromptHostName=""
    elif __is_embedded_terminal; then
        PromptHostName=%m
    elif __is_ssh_session; then
        PromptHostName=%M
    elif [[ -n ${LOCALHOST_PREFERRED_DISPLAY} ]]; then
        PromptHostName=${LOCALHOST_PREFERRED_DISPLAY}
    else
        PromptHostName=%m
    fi

    # All optional segments have spaces embedded in the output suffix if non-empty.
    local prompt_builder=''
    prompt_builder+='%{$fg[white]%}$(__cute_time_prompt) '
    prompt_builder+='$(__print_virtualenv_info)'
    prompt_builder+='$(__print_did_last_command_take_a_while)'
    prompt_builder+='%{$fg[green]%}$USER%{$fg[yellow]%}@%B%{'${PromptHostColor}'%}'${PromptHostName}'%{$reset_color%} '
    prompt_builder+='$(__print_repo_worktree)'
    prompt_builder+='$(__print_git_worktree)$(__print_git_info)'
    if declare -f __print_citc_workspace > /dev/null; then
        prompt_builder+='$(__print_citc_workspace)'
    fi
    prompt_builder+='$(__cute_pwd)'
    prompt_builder+=' %(!.$ELEVATED_END_OF_PROMPT_ICON.$END_OF_PROMPT_ICON) '

    # If I ever want to profile the generation of the prompt: "print -P $PROMPT"
    echo -n ${prompt_builder}
}

PROMPT=$(__generate_standard_prompt)
RPROMPT=''
# RPOMPT+='%* '

function __venv_aware_cd() {
    builtin cd "$@"

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

# Basically this lets me override cd and still get file completion...
function ___venv_aware_cd() {
  ((CURRENT == 2)) &&
  _files -/
}

compdef ___venv_aware_cd __venv_aware_cd

# defines __git_ps1
[[ -f "${DOTFILES_CONFIG_ROOT}/git-prompt.sh" ]] && source "${DOTFILES_CONFIG_ROOT}/git-prompt.sh"

command -v hub &> /dev/null && eval "$(hub alias -s)"
command -v chjava &> /dev/null && chjava 18

# If using iTerm2, try for shell integration.
# iTerm profile switching requires shell_integration to be installed anyways.
if __is_iterm2_terminal; then
    [[ -f "${DOTFILES_CONFIG_ROOT}/iterm2_shell_integration.zsh" ]] && source "${DOTFILES_CONFIG_ROOT}/iterm2_shell_integration.zsh"
    [[ -f "${DOTFILES_CONFIG_ROOT}/iterm2_funcs.sh" ]] && source "${DOTFILES_CONFIG_ROOT}/iterm2_funcs.sh"
fi

[[ -f "~/.zshext/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]] && source "~/.zshext/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"

if ! __is_tool_window; then
    if __is_embedded_terminal; then
        __refresh_icon_map 1 # No nerdfonts in embedded terminals.
        echo "Limiting zsh initialization because inside $(__embedded_terminal_info) terminal."
        if __is_vscode_terminal; then
            if command -v code &> /dev/null; then
                source "$(code --locate-shell-integration-path zsh)"
            fi

            # Also, in some contexts .zprofile isn't sourced when started inside the Python debug console.
            source ~/.zprofile
        fi
    else
        alias cd='__venv_aware_cd'
    fi
fi

# if eza is installed prefer that to ls
# options aren't the same, but I also need it less often...
if ! command -v eza &> /dev/null; then
    echo "## Using native ls because missing eza"
    # by default, show slashes, follow symbolic links, colorize
    alias ls='ls -FHG'
else
    export EZA_STRICT=0
    export EZA_ICONS_AUTO=0
    alias ls='eza -l --group-directories-first'
    # https://github.com/orgs/eza-community/discussions/239#discussioncomment-9834010
    alias kd='eza --group-directories-first'
    alias realls='\ls -FHG'
fi

# echo "Welcome to $(__effective_distribution)!"
case "$(__effective_distribution)" in
"GLinux")
    # echo "GLinux zshrc load complete"
    if declare -f __on_glinux_zshrc_load_complete > /dev/null; then
        __on_glinux_zshrc_load_complete
    fi

    ;;
"OSX")
    # echo "OSX zshrc load complete"
    [[ -f "${DOTFILES_CONFIG_ROOT}/osx_funcs.zsh" ]] && source "${DOTFILES_CONFIG_ROOT}/osx_funcs.zsh"

    # RPROMPT='$(battery_charge)'

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
    VIRTUALENV_ID_FUNCS[WSL_WINDOWS]=WSL_WINDOWS_VIRTUALENV_ID
    VIRTUALENV_ID_FUNCS[WSL_LINUX]=WSL_LINUX_VIRTUALENV_ID

    # export WIN_USERPROFILE=$(wslpath $(powershell.exe '$env:UserProfile'))

    alias winGo='pushd $WIN_USERPROFILE; cd .'
    ;;
esac

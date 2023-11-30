#! /bin/zsh

#pragma once

# Useful reference: https://scriptingosx.com/2019/07/moving-to-zsh-part-7-miscellanea/

# autoload -Uz promptinit
# promptinit
# prompt fire

setopt PROMPT_SUBST
setopt histignorealldups sharehistory

# Color cheat sheet: https://jonasjacek.github.io/colors/
autoload -U colors && colors

export LSCOLORS="Gxfxcxdxbxegedabagacad"
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}

setopt NO_CASE_GLOB
setopt AUTO_CD
setopt EXTENDED_HISTORY

HISTFILE=${ZDOTDIR:-$HOME}/.zsh_history
SAVEHIST=5000
HISTSIZE=2000

setopt SHARE_HISTORY
setopt APPEND_HISTORY
setopt INC_APPEND_HISTORY

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

# Use modern completion system
autoload -Uz compinit
compinit

# $PATH is tied to $path - Can use one as an array and the other as a scalar.
typeset -U path # force unique values.

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

# Use beam shape cursor for each new prompt.
preexec() {
    _set_cursor_beam
}

#start_timer=0
#end_timer=0
#elapsed_timer=0

#function __start_timer() {
#    export start_timer=$(($(gdate +%s%N)/1000000))
#    echo ""
#}

#function __complete_timer() {
#    export end_timer=$(($(gdate +%s%N)/1000000))
#    export elapsed_timer=$(($end_timer-$start_timer))
#    echo ""
#}

#autoload -Uz add-zsh-hook
#add-zsh-hook precmd __start_timer

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
LINUX_PENGUIN_ICON=
GITHUB_ICON=
GOOGLE_ICON=
VIM_ICON=
ANDROID_HEAD_ICON=󰀲
ANDROID_BODY_ICON=
PYTHON_ICON=
GIT_BRANCH_ICON=
GIT_COMMIT_ICON=
HOME_FOLDER_ICON=󱂵
COD_FILE_SUBMODULE_ICON=
TMUX_ICON=
VS_CODE_ICON=󰨞
COD_HOME_ICON=
COD_PINNED_ICON=
COD_TOOLS_ICON=
COD_TAG_ICON=
COD_PACKAGE_ICON=
COD_SAVE_ICON=
FAE_TREE_ICON=
MD_SUBMARINE_ICON=󱕬
MD_GREATER_THAN_ICON=󰥭
MD_CHEVRON_DOUBLE_RIGHT_ICON=󰄾
MD_MICROSOFT_VISUAL_STUDIO_CODE_ICON=󰨞
MD_SNAPCHAT=󰒶
OCT_FILE_SUBMODULE_ICON=
COD_TERMINAL_BASH=
FA_DOLLAR_ICON=

function __cute_pwd_helper() {
    local ACTIVE_DIR=$1
    local SUFFIX=$2
    local ICO_COLOR=$reset_color

    # These should only match if they're exact.
    case "${ACTIVE_DIR}" in
        "${HOME}")
            echo -n %{${ICO_COLOR}%}${COD_HOME_ICON}%{$reset_color%}${SUFFIX}
            return 0
            ;;
        "${WIN_USERPROFILE}")
            echo -n %{${ICO_COLOR}%}${WINDOWS_ICON}${COD_HOME_ICON}%{$reset_color%}${SUFFIX}
            return 0
            ;;
        "/")
            echo -n %{${ICO_COLOR}%}${FAE_TREE_ICON}%{$reset_color%}${SUFFIX}
            return 0
            ;;
    esac

    if (( ${+ANDROID_REPO_BRANCH} )); then
        if [[ "${ACTIVE_DIR##*/}" == "${ANDROID_REPO_BRANCH}" ]]; then
            echo -n %{${ICO_COLOR}%}${ANDROID_HEAD_ICON}%{$reset_color%}${SUFFIX}
            return 0
        fi
    fi

    case "${ACTIVE_DIR##*/}" in
        "github")
            echo -n %{${ICO_COLOR}%}${GITHUB_ICON}%{$reset_color%}${SUFFIX}
            return 0
            ;;
        "src" | "source")
            echo -n %{${ICO_COLOR}%}${COD_SAVE_ICON}%{$reset_color%}${SUFFIX}
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
            echo -e "%{${COD_PINNED_ICON} %}$(git rev-parse --show-toplevel | xargs basename)/$(git rev-parse --show-prefix)\b"
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
    if __is_in_repo && (( ${+SKIP_WORKTREE_IN_ANDROID_REPO} )); then
        echo ""
        return 0
    fi

    if ! __is_in_git_repo; then
        echo ""
        return 0
    fi

    if __is_in_git_dir; then
        echo "${fg[yellow]%}${COD_TOOLS_ICON} "
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
        echo "%{$fg[green]%}${OCT_FILE_SUBMODULE_ICON}%{%F{207}%}${ROOT_WORKTREE##*/}:%{$fg[green]%}${ACTIVE_WORKTREE##*/} "
        return 0
    fi

    echo "%{%F{207}%}${COD_FILE_SUBMODULE_ICON}${SUBMODULE_WORKTREE##*/} "
    return 0
}

function __print_repo_worktree() {
    if ! __is_in_repo; then
        echo ""
        return 0
    fi

    local MANIFEST_BRANCH=""

    if (( ${+ANDROID_REPO_ROOT} )) && test "${PWD##$ANDROID_REPO_ROOT}" != "${PWD}"; then
        MANIFEST_BRANCH=$ANDROID_REPO_BRANCH
    else
        MANIFEST_BRANCH=$(repo info -o --outer-manifest -l | grep -i "Manifest branch" | sed 's/^Manifest branch: //')
    fi

    echo "%{$fg[green]%}$ANDROID_BODY_ICON$MANIFEST_BRANCH "
}

function __print_git_info() {
    if ! __is_in_git_repo || __is_in_git_dir; then
        echo ""
        return 0
    fi

    local COMMIT_TEMPLATE_STRING=$(test -n "$EXPECT_NERD_FONTS" && echo "$GIT_COMMIT_ICON%s" || echo "%s")
    local COMMIT_MOD_TEMPLATE_STRING=$(test -n "$EXPECT_NERD_FONTS" && echo "$GIT_COMMIT_ICON%s*" || echo "{%s *}")
    local BRANCH_TEMPLATE_STRING=$(test -n "$EXPECT_NERD_FONTS" && echo "$GIT_BRANCH_ICON%s" || echo "(%s)")
    local BRANCH_MOD_TEMPLATE_STRING=$(test -n "$EXPECT_NERD_FONTS" && echo "$GIT_BRANCH_ICON%s*" || echo "{%s *}")

    git status | grep "HEAD detached" > /dev/null 2>&1
    local IS_DETACHED_HEAD=$?
    git status | grep "nothing to commit" > /dev/null 2>&1
    local IS_NOTHING_TO_COMMIT=$?

    if [[ "${IS_DETACHED_HEAD}" == "0" ]]; then
        if [[ "${IS_NOTHING_TO_COMMIT}" == "0" ]]; then
            echo -e "%{$fg[red]%}"$(__git_ps1 ${COMMIT_TEMPLATE_STRING})" "
        else
            echo -e "%{$fg[red]%}"$(__git_ps1 ${COMMIT_MOD_TEMPLATE_STRING})" "
        fi
    else
        if [[ "${IS_NOTHING_TO_COMMIT}" == "0" ]]; then
            echo -e "%{$fg[green]%}"$(__git_ps1 ${BRANCH_TEMPLATE_STRING})" "
        else
            echo -e "%{$fg[yellow]%}"$(__git_ps1 ${BRANCH_MOD_TEMPLATE_STRING})" "
        fi
    fi
}

function __virtualenv_info() {
    local HAS_VIRTUALENV=1
    if __is_in_tmux; then echo -n "%{$fg[white]%}$TMUX_ICON" && HAS_VIRTUALENV=0; fi
    # venv="${VIRTUAL_ENV##*/}"
    if __is_on_wsl; then
        if __is_in_windows_drive; then echo -n "%{$fg[blue]%}$WINDOWS_ICON";
        else; echo -n "%{$fg[blue]%}$LINUX_PENGUIN_ICON"; fi
        HAS_VIRTUALENV=0
    fi
    if (( ${+VIRTUAL_ENV} )); then echo -n "%{$fg[green]%}$PYTHON_ICON" && HAS_VIRTUALENV=0; fi
    if (( ${+VIMRUNTIME} )); then echo -n "%{$fg[green]%}$VIM_ICON" && HAS_VIRTUALENV=0; fi
    if [[ "$HAS_VIRTUALENV" == "0" ]]; then
        echo -n "%{$reset_color%} "
    fi
}

# disable the default virtualenv prompt change
VIRTUAL_ENV_DISABLE_PROMPT=1
SKIP_WORKTREE_IN_ANDROID_REPO=0 # Repo is implemented in terms of worktrees, so this gets noisy.

if [[ -z "${HOST_COLOR}" ]]; then
    # Use a different color for displaying the host name when we're logged into SSH
    if __is_ssh_session; then
        HOST_COLOR=%F{214}
    else
        HOST_COLOR=$fg[yellow]
    fi
fi

if __is_ssh_session; then
    if __is_in_tmux; then
        HostNameDisplay=""
    else
        HostNameDisplay=%M
    fi
else
    if [[ -n $LOCALHOST_PREFERRED_DISPLAY ]]; then
        HostNameDisplay=$LOCALHOST_PREFERRED_DISPLAY
    else
        HostNameDisplay=%m
    fi
fi


END_OF_PROMPT_ICON=$MD_GREATER_THAN_ICON
ELEVATED_END_OF_PROMPT_ICON="$"

PROMPT=''
PROMPT+='${white}$(__cute_time_prompt) '
PROMPT+='$(__virtualenv_info)'
PROMPT+='%{$fg[green]%}$USER%{$fg[yellow]%}@%B%{${HOST_COLOR}%}$HostNameDisplay%{$reset_color%} '
# Optional - spaces are embedded in output suffix if these are non-empty.
PROMPT+='$(__print_repo_worktree)%{$reset_color%}'
PROMPT+='$(__print_git_worktree)$(__print_git_info)%{$reset_color%}'
PROMPT+='$(__cute_pwd)'
PROMPT+=' %(!.$ELEVATED_END_OF_PROMPT_ICON.$END_OF_PROMPT_ICON) '

RPROMPT=''
# RPOMPT+='%* '
# Optional
# RPROMPT+='$(__virtualenv_info)'

function __venv_aware_cd() {
    builtin cd "$@"

    # If I am no longer in the same directory hierarchy as the venv that was last activated, deactivate.
    if [[ -n "${VIRTUAL_ENV}" ]]; then
        local P_DIR="$(dirname "$VIRTUAL_ENV")"
        if [[ "$PWD"/ != "${P_DIR}"/* ]]; then
            echo "$NF_PYTHON_ICON Deactivating venv for $P_DIR"
            deactivate
        fi
    fi

    # If I enter a directory with a .venv and I am already activated with another one, let me know but don't activate.
    if [[ -d ./.venv ]]; then
        if [[ -z "$VIRTUAL_ENV" ]]; then
            source ./.venv/bin/activate
            echo "$NF_PYTHON_ICON Activating venv with $(python --version) for $PWD/.venv"
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

if [ ! -f ${DOTFILES_CONFIG_ROOT}/git-prompt.sh ]; then
    echo "Bootstrapping git-prompt installation on new machine through curl"
    curl -o ${DOTFILES_CONFIG_ROOT}/git-prompt.sh \
    https://raw.githubusercontent.com/git/git/master/contrib/completion/git-prompt.sh
fi

source ${DOTFILES_CONFIG_ROOT}/git-prompt.sh # defines __git_ps1

command -v hub &> /dev/null && eval "$(hub alias -s)"
command -v chjava &> /dev/null && chjava 18

# If using iTerm2, try for shell integration.
# When in SSH TERM_PROGRAM isn't getting propagated.
# iTerm profile switching requires shell_integration to be installed anyways.
if [[ "iTerm2" == "$LC_TERMINAL" ]]; then
    if [ ! -f ${DOTFILES_CONFIG_ROOT}/iterm2_shell_integration.zsh ]; then
        echo "Bootstrapping iTerm2 Shell Integration on a new machine through curl"
        curl -L https://iterm2.com/shell_integration/zsh -o ${DOTFILES_CONFIG_ROOT}/iterm2_shell_integration.zsh
    fi
    test -e ${DOTFILES_CONFIG_ROOT}/iterm2_shell_integration.zsh && \
        source ${DOTFILES_CONFIG_ROOT}/iterm2_shell_integration.zsh
fi

test -e ~/.zshext/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh && \
    source ~/.zshext/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

if ! __is_embedded_terminal; then
    alias cd='__venv_aware_cd'
else
    echo "Limiting zsh initialization because inside $MD_MICROSOFT_VISUAL_STUDIO_CODE_ICON terminal."
    # Also, in some contexts .zprofile isn't sourced when started inside the Python debug console.
    source ~/.zprofile
fi

if command -v code &> /dev/null; then
    [[ "$TERM_PROGRAM" == "vscode" ]] && source "$(code --locate-shell-integration-path zsh)"
fi

# if exa is installed prefer that to ls
# options aren't the same, but I also need it less often...
if ! command -v exa &> /dev/null; then
    echo "## Using native ls because missing exa"
    # by default, show slashes, follow symbolic links, colorize
    alias ls='ls -FHG'
else
    alias ls='exa -l'
    alias realls='\ls -FHG'
fi

# echo "Welcome to $(__effective_distribution)!"
case "$(__effective_distribution)" in
    "GLinux")
        # echo "GLinux zshrc load complete"
        __on_glinux_zshrc_load_complete

        ;;
    "OSX")
        # echo "OSX zshrc load complete"
        source ${DOTFILES_CONFIG_ROOT}/osx_funcs.zsh

        # RPROMPT='$(battery_charge)'

        if command -v brew > /dev/null; then
            test -e "$(brew --prefix)/opt/zsh-git-prompt/zshrc.sh" && source "$(brew --prefix)/opt/zsh-git-prompt/zshrc.sh"
        fi

        if ! __is_ssh_session && ! command -v code &> /dev/null; then
            echo "## CLI for VSCode is unavailable. Check https://code.visualstudio.com/docs/setup/mac"
        fi

        ANDROID_SDK=~/android_sdk
        path=($path ~/android_sdk/cmdline-tools/latest/bin)
        # https://developer.android.com/tools/variables
        # ANDROID_HOME=~/Library/Android/sdk
        # path=($path $ANDROID_HOME/tools $ANDROID_HOME/tools/bin $ANDROID_HOME/platform-tools)
        ;;
    "WSL")
        WIN_SYSTEM_DRIVE=$(powershell.exe '$env:SystemDrive')
        WIN_SYSTEM_ROOT="/mnt/${WIN_SYSTEM_DRIVE:0:1:l}"
        WIN_USERNAME=$(powershell.exe '$env:UserName')
        WIN_USERPROFILE=$(echo $(wslpath $(powershell.exe '$env:UserProfile')) | sed $'s/\r//')

        # export WIN_USERPROFILE=$(wslpath $(powershell.exe '$env:UserProfile'))

        alias winGo='pushd $WIN_USERPROFILE'
        ;;
esac

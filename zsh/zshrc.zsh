#! /bin/zsh

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

zle-line-finish() { _set_cursor_block }
zle -N zle-line-finish

zle-line-init() { _set_cursor_beam }
zle -N zle-line-init

# Use beam shape cursor for each new prompt.
preexec() { _set_cursor_beam }

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
            # Because this messes with the shell's perception of where the cursor is, make the anchor icon
            # appear like an escape sequence instead of a printed character.
            echo -e "%{$ANCHOR_ICON%}$(git rev-parse --show-toplevel | xargs basename)/$(git rev-parse --show-prefix)\b"
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
        "/")
            echo 🌲
            return 0
            ;;
    esac

    case "${PWD##*/}" in
        "github")
            echo $GITHUB_ICON
            return 0
            ;;
        src | source)
            echo 💾
            return 0
            ;;
        "work")
            echo 🏢
            return 0
            ;;
        *)
            ;;
    esac

    echo -n ${PWD##*/}
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

    ROOT_WORKTREE=$(git worktree list | head -n1 | awk '{print $1;}')
    ACTIVE_WORKTREE=$(git worktree list | grep "$(git rev-parse --show-toplevel)" | head -n1 | awk '{print $1;}')

    if [[ "$ROOT_WORKTREE" == "$ACTIVE_WORKTREE" ]]; then
        echo ""
        return 0
    fi

    SUBMODULE_WORKTREE=$(git rev-parse --show-superproject-working-tree)
    if [[ "$SUBMODULE_WORKTREE" == "" ]]; then
        echo 🌲"%{$fg[green]%}[${ROOT_WORKTREE##*/}/${ACTIVE_WORKTREE##*/}] "
        return 0
    fi

    echo 🛶"%{%F{207}%}[${SUBMODULE_WORKTREE##*/}/${ROOT_WORKTREE##*/}] "
    return 0
}

function __print_repo_worktree() {
    if __is_in_repo; then
        # REPO_ROOT=$(repo --show-toplevel | head -n1 | awk '{print $1;}')
        REPO_ROOT=$(repo info -o --outer-manifest -l | grep -i "Manifest branch" | sed 's/^Manifest branch: //')
        echo "%{$fg[green]%}$NF_ANDROID_ICON${REPO_ROOT##*/} "
    else
        echo ""
    fi
}

function __print_git_info() {
    if ! __is_in_git_repo || __is_in_git_dir; then
        echo ""
        return 0
    fi

    git status | grep "HEAD detached" > /dev/null 2>&1
    IS_DETACHED_HEAD=$?
    git status | grep "nothing to commit" > /dev/null 2>&1
    IS_NOTHING_TO_COMMIT=$?

    if [[ "$IS_DETACHED_HEAD" == "0" ]]; then
        if [[ "$IS_NOTHING_TO_COMMIT" == "0" ]]; then
            COMMIT_TEMPLATE_STRING=$(test -n "$EXPECT_NERD_FONTS" && echo "$GIT_COMMIT_ICON%s" || echo "%s")
            echo -e "%{$fg[red]%}"$(__git_ps1 $COMMIT_TEMPLATE_STRING)" "
        else
            COMMIT_MOD_TEMPLATE_STRING=$(test -n "$EXPECT_NERD_FONTS" && echo "$GIT_COMMIT_ICON%s*" || echo "{%s *}")
            echo -e "%{$fg[red]%}"$(__git_ps1 $COMMIT_MOD_TEMPLATE_STRING)" "
        fi
    else
        if [[ "$IS_NOTHING_TO_COMMIT" == "0" ]]; then
            BRANCH_TEMPLATE_STRING=$(test -n "$EXPECT_NERD_FONTS" && echo "$GIT_BRANCH_ICON%s" || echo "(%s)")
            echo -e "%{$fg[green]%}"$(__git_ps1 $BRANCH_TEMPLATE_STRING)" "
        else
            BRANCH_MOD_TEMPLATE_STRING=$(test -n "$EXPECT_NERD_FONTS" && echo "$GIT_BRANCH_ICON%s*" || echo "{%s *}")
            echo -e "%{$fg[yellow]%}"$(__git_ps1 $BRANCH_MOD_TEMPLATE_STRING)" "
        fi
    fi
}

# Use a different color for displaying the host name when we're logged into SSH
if __is_ssh_session; then
    HostColor=%F{214}
    if __is_in_tmux; then
        HostNameDisplay=""
    else
        HostNameDisplay=%M
    fi
else
    HostColor=%{$fg[yellow]%}
    HostNameDisplay=%m
fi

function __virtualenv_info() {
    if __is_in_tmux; then echo -n "%{$fg[white]%}$TMUX_ICON "; fi
    # venv="${VIRTUAL_ENV##*/}"
    if (( ${+VIRTUAL_ENV} )); then echo -n "%{$fg[green]%}$NF_PYTHON_ICON "; fi
    if (( ${+VIMRUNTIME} )); then echo -n "%{$fg[green]%}$NF_VIM_ICON "; fi
    echo -n "%{$reset_color%}"
}

# disable the default virtualenv prompt change
VIRTUAL_ENV_DISABLE_PROMPT=1
SKIP_WORKTREE_IN_ANDROID_REPO=1 # Repo is implemented in terms of worktrees, so this gets noisy.

PROMPT=''
PROMPT+='${white}$(__cute_time_prompt) '
# Optional
PROMPT+='$(__virtualenv_info)'
PROMPT+='%{$fg[green]%}$USER%{$fg[yellow]%}@%B$HostColor$HostNameDisplay%{$reset_color%} '
# Optional - spaces are embedded in output suffix if these are non-empty.
PROMPT+='$(__print_repo_worktree)%{$reset_color%}'
PROMPT+='$(__print_git_worktree)$(__print_git_info)%{$reset_color%}'
PROMPT+='$(__cute_pwd)'
PROMPT+=' $ '
# RPROMPT='%*'

# if exa is installed prefer that to ls
# options aren't the same, but I also need it less often...
if ! command -v exa &> /dev/null; then
    echo "## Using native ls because missing exa"
    # by default, show slashes, follow symbolic links, colorize
    alias ls='ls -FHG'
else
    alias ls=exa
    alias realls='\ls -FHG'
fi

function __venv_aware_cd() {
    builtin cd "$@"

    # If I am no longer in the same directory hierarchy as the venv that was last activated, deactivate.
    if [[ -n "$VIRTUAL_ENV" ]]; then
        P_DIR="$(dirname "$VIRTUAL_ENV")"
        if [[ "$PWD"/ != "$P_DIR"/* ]]; then
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

test -e ~/.google_funcs.zsh && source ~/.google_funcs.zsh
source ~/.android_funcs.zsh # Android shell utility functions
source ~/.util_funcs.zsh

if [ ! -f ~/.git-prompt.sh ]; then
    echo "Bootstrapping git-prompt installation on new machine through curl"
    curl -o ~/.git-prompt.sh \
    https://raw.githubusercontent.com/git/git/master/contrib/completion/git-prompt.sh
fi

source ~/.git-prompt.sh # defines __git_ps1

command -v hub &> /dev/null && eval "$(hub alias -s)"
command -v chjava &> /dev/null && chjava 18

# If using iTerm2, try for shell integration.
# When in SSH TERM_PROGRAM isn't getting propagated.
# iTerm profile switching requires shell_integration to be installed anyways.
if [[ "iTerm2" == "$LC_TERMINAL" ]]; then
    if [ ! -f ~/.iterm2_shell_integration.zsh ]; then
        echo "Bootstrapping iTerm2 Shell Integration on a new machine through curl"
        curl -L https://iterm2.com/shell_integration/zsh -o ~/.iterm2_shell_integration.zsh
    fi
    test -e ~/.iterm2_shell_integration.zsh && source ~/.iterm2_shell_integration.zsh
fi

if ! __is_embedded_terminal; then
    alias cd='__venv_aware_cd'
else
     echo "Limiting zsh initialization because inside vscode terminal."
fi

# echo "Welcome to $(__effective_distribution)!"
case "$(__effective_distribution)" in
    GLinux)
        __on_glinux_zshrc_load_complete

        ;;
    OSX)
        source ~/.osx_funcs.zsh

        # RPROMPT='$(battery_charge)'

        if command -v brew > /dev/null; then
            test -e "$(brew --prefix)/opt/zsh-git-prompt/zshrc.sh" && source "$(brew --prefix)/opt/zsh-git-prompt/zshrc.sh"
        fi

        if ! __is_ssh_session && ! command -v code &> /dev/null; then
            echo "## CLI for VSCode is unavailable. Check https://code.visualstudio.com/docs/setup/mac"
        fi

        # https://developer.android.com/tools/variables
        export ANDROID_HOME=~/Library/Android/sdk
        path=($path $ANDROID_HOME/tools $ANDROID_HOME/tools/bin $ANDROID_HOME/platform-tools)
        ;;
    WSL)
        export WIN_USERNAME=$(powershell.exe '$env:UserName')
        export WIN_USERPROFILE=$(echo $(wslpath $(powershell.exe '$env:UserProfile')) | sed $'s/\r//')
        # export WIN_USERPROFILE=$(wslpath $(powershell.exe '$env:UserProfile'))

        alias winhome='cd $WIN_USERPROFILE'
        ;;
esac

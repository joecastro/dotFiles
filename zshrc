#! /bin/zsh

setopt PROMPT_SUBST

# Color cheat sheet: https://jonasjacek.github.io/colors/
autoload -U colors
colors

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

function wintitle() {
    if [ -z "$1" ]
    then
        echo "Missing window title"
    else
        echo -ne "\e]0;$1\a"
    fi
}

# emojipedia.org
function __cute_pwd() {
    # If we're in a git repo then show the current directory relative to the root of that repo.
    git branch > /dev/null 2>&1;
    if [ "$?" -ne "0" ]; then
        case "${PWD##*/}" in
            ${HOME##*/})
                echo 🏠
                ;;
            /)
                echo 🌲
                ;;
            src | source)
                echo 💾
                ;;
            *)
                echo -n ${PWD##*/}
                ;;
        esac
    else
        echo "📌$(git rev-parse --show-toplevel | xargs basename)/$(git rev-parse --show-prefix)" 
    fi
}

function __print_git_info() {
    git branch > /dev/null 2>&1;
    if [ "$?" -ne "0" ]; then
        echo "";
    else
        echo "$(echo `git status 2>/dev/null` | grep "HEAD detached" > /dev/null 2>&1;
        if [ "$?" -eq "0" ]; then
            echo "$(echo `git status 2>/dev/null` | grep "nothing to commit" > /dev/null 2>&1; 
            if [ "$?" -eq "0" ]; then 
                echo -e "%{$fg[red]%}"$(__git_ps1 "%s")" ";
            else 
                echo -e "%{$fg[red]%}"$(__git_ps1 "{%s *}")" ";
            fi)"; 
        else 
            echo "$(echo `git status 2>/dev/null` | grep "nothing to commit" > /dev/null 2>&1; 
            if [ "$?" -eq "0" ]; then 
                echo -e "%{$fg[green]%}"$(__git_ps1 "(%s)")" ";
            else 
                echo -e "%{$fg[yellow]%}"$(__git_ps1 "{%s *}")" ";
            fi)"; 
        fi)"; 
    fi
}

#curl -ocurl -o ~/.git-prompt.sh \
#    https://raw.githubusercontent.com/git/git/master/contrib/completion/git-prompt.sh

if [ -f ~/.git-prompt.sh ]; then
    source ~/.git-prompt.sh
fi

if [ -f $(brew --prefix)/opt/zsh-git-prompt/zshrc.sh ]; then
    source $(brew --prefix)/opt/zsh-git-prompt/zshrc.sh
fi

# Use a different color for displaying the host name when we're logged into SSH
if [ -n "$SSH_CLIENT" ] || [ -n "$SSH_TTY" ] || [ -n "$SSH_CONNECTION" ]; then
     HostColor=%F{214}
else
     HostColor=%{$fg[yellow]%}
fi

PROMPT='%F{234}%T %{$fg[green]%}$USER%{$fg[yellow]%}@%B$HostColor%m%{$reset_color%} $(__print_git_info)%{$reset_color%}$(__cute_pwd) $ '


# by default, show slashes, follow symbolic links, colorize
alias ls='ls -FHG'

alias myip='curl http://ipecho.net/plain; echo'

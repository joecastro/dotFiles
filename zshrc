
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

function __cute_pwd() {
    case "${PWD##*/}" in
        ${HOME##*/})
            printf 🏠
            ;;
        /)
            printf 🌲
            ;;
        src | source)
            printf 💾
            ;;
        *)
        echo -n ${PWD##*/}
        ;;
    esac
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

source ~/.git-prompt.sh
source "/opt/brew/opt/zsh-git-prompt/zshrc.sh"

# Use a different color for displaying the host name when we're logged into     ↪\SSH
if [ -n "$SSH_CLIENT" ] || [ -n "$SSH_TTY" ] || [ -n "$SSH_CONNECTION" ]; then
     HostColor=%F{11}
else
     HostColor=%F{10}
fi

PROMPT='%F{234}%T %{$fg[green]%}$USER%{$fg[yellow]%}@%B$HostColor%m%{$reset_color%} $(__print_git_info)%{$reset_color%}$(__cute_pwd) $ '

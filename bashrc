# Various variables you might want for your PS1 prompt instead
Time12h="\T"
Time12a="\@"
PathShort="\w"
PathFull="\W"
NewLine="\n"
Jobs="\j"

# Reset
Color_Off="\[\033[0m\]"       # Text Reset

# Normal Colors
Black='\e[0;30m'        # Black
Red='\e[0;31m'          # Red
Green='\e[0;32m'        # Green
Yellow='\e[0;33m'       # Yellow
Blue='\e[0;34m'         # Blue
Purple='\e[0;35m'       # Purple
Cyan='\e[0;36m'         # Cyan
White='\e[0;37m'        # White

IBlack="\[\033[0;90m\]"       # Black

# Bold
BBlack='\e[1;30m'       # Black
BRed='\e[1;31m'         # Red
BGreen='\e[1;32m'       # Green
BYellow='\e[1;33m'      # Yellow
BBlue='\e[1;34m'        # Blue
BPurple='\e[1;35m'      # Purple
BCyan='\e[1;36m'        # Cyan
BWhite='\e[1;37m'       # White

# Background
On_Black='\e[40m'       # Black
On_Red='\e[41m'         # Red
On_Green='\e[42m'       # Green
On_Yellow='\e[43m'      # Yellow
On_Blue='\e[44m'        # Blue
On_Purple='\e[45m'      # Purple
On_Cyan='\e[46m'        # Cyan
On_White='\e[47m'       # White

RESET="\[\017\]"
SMILEY="${WHITE}:)${NORMAL}"
FROWNY="${RED}:(${NORMAL}"

export PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin
export JAVA_HOME=`/usr/libexec/java_home`
export PATH=$JAVA_HOME/bin:$PATH

# curl -o ~/.git-prompt.sh \
#    https://raw.githubusercontent.com/git/git/master/contrib/completion/git-prompt.sh
source ~/.git-prompt.sh

#if [ -f `brew --prefix`/etc/bash_completion.d/git-completion.bash ]; then
#    . `brew --prefix`/etc/bash_completion.d/git-completion.bash
#    . `brew --prefix`/etc/bash_completion.d/git-prompt.sh
#
#    export PS1=$IBlack$Time12h$Color_Off' \u@\h $(__git_ps1 "(%s) ")\W $ '
#else # Not OS X

    # Note that this tends to cause error messages when inside a .git folder.
    # I'm not sure of a good way to suppress that.
    export PS1=$IBlack$Time12h$Color_Off' \u@\h $(git branch &>/dev/null;\

    if [ "$?" -ne "0" ]; then \
        echo ""; \
    else
        echo "$(echo `git status` | grep "HEAD detached" > /dev/null 2>&1; \
        if [ "$?" -eq "0" ]; then \
            echo "'$Red'"$(__git_ps1 " %s");\
        else \
            echo "$(echo `git status` | grep "nothing to commit" > /dev/null 2>&1; \
            if [ "$?" -eq "0" ]; then \
                echo "'$Green'"$(__git_ps1 " (%s)");\
            else \
                echo "'$Yellow'"$(__git_ps1 " {%s *}");\
            fi) "; \
        fi) "; \
    fi)'$Color_Off'\W] $ '

# fi

SELECT="if [ \$? = 0 ]; then echo \"${SMILEY}\"; else echo \"${FROWNY}\"; fi"

# Throw it all together 
#PS1="${RESET}${YELLOW}\h${NORMAL} \`${SELECT}\` ${YELLOW}>${NORMAL} "


# Various variables you might want for your PS1 prompt instead
Time12h="\T"
Time12a="\@"
PathShort="\w"
PathFull="\W"
NewLine="\n"
Jobs="\j"

# Normal Colors
Black='\e[0;30m'        # Black
Red='\e[0;31m'          # Red
Green='\e[0;32m'        # Green
Yellow='\e[0;33m'       # Yellow
Blue='\e[0;34m'         # Blue
Purple='\e[0;35m'       # Purple
Cyan='\e[0;36m'         # Cyan
White='\e[0;37m'        # White

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

# Hurley Stuff
export WORKON_HOME=~/Envs
source /usr/local/bin/virtualenvwrapper.sh

export PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin

if [ -f `brew --prefix`/etc/bash_completion.d/git-completion.bash ]; then
    . `brew --prefix`/etc/bash_completion.d/git-completion.bash
    . `brew --prefix`/etc/bash_completion.d/git-prompt.sh

    export PS1='[\u@\h $(__git_ps1 " (%s)")\W] $ '
else # Not OS X

    # Note that this tends to cause error messages when inside a .git folder.
    # I'm not sure of a good way to suppress that.
    export PS1='[\u@\h $(git branch &>/dev/null;\

    if [ $? -eq 0 ]; then \
        echo "$(echo `git status` | grep "nothing to commit" > /dev/null 2>&1; \
        if [ "$?" -eq "0" ]; then \
            # @4 - Clean repository - nothing to commit
            echo $(__git_ps1 " (%s)"); \
        else \
            # @5 - Changes to working tree
            echo $(__git_ps1 " {%s *}"); \
        fi) "; \
    else \
        # @2 - Prompt when not in GIT repo
        echo ""; \
    fi)\W] $ '

fi

SELECT="if [ \$? = 0 ]; then echo \"${SMILEY}\"; else echo \"${FROWNY}\"; fi"

# Throw it all together 
#PS1="${RESET}${YELLOW}\h${NORMAL} \`${SELECT}\` ${YELLOW}>${NORMAL} "


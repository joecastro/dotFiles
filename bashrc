 export DISPLAY=:0

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# Various PS1 aliases

Time12h="\T"
Time12a="\@"
PathShort="\w"
PathFull="\W"
NewLine="\n"
Jobs="\j"

# Reset
Color_Off='\e[0m'       # Text Reset

# Normal Colors
Black='\e[0;30m'        # Black
Red='\e[0;31m'          # Red
Green='\e[0;32m'        # Green
Yellow='\e[0;33m'       # Yellow
Blue='\e[0;34m'         # Blue
Purple='\e[0;35m'       # Purple
Cyan='\e[0;36m'         # Cyan
White='\e[0;37m'        # White

IBlack="\033[0;90m"       # Black

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

RESET="\017"
SMILEY="${WHITE}:)${NORMAL}"
FROWNY="${RED}:(${NORMAL}"

eval "`dircolors -b ~/.dircolorsrc`"
export LS_OPTIONS='--color=auto'

# Check the window size after each command and update the values of lines and columns
shopt -s checkwinsize
# Use "**" in pathname expansion will match files in subdirectories
shopt -s globstar

function wintitle() {
    if [ -z "$1" ]
    then
        echo "Missing window title"
    else
        echo -ne "\e]0;$1\a"
    fi
}

function print_git_info() {
    git branch > /dev/null 2>&1;
    if [ "$?" -ne "0" ]; then
        echo "";
    else
        echo "$(echo `git status` | grep "HEAD detached" > /dev/null 2>&1;
        if [ "$?" -eq "0" ]; then
            echo "$(echo `git status` | grep "nothing to commit" > /dev/null 2>&1; 
            if [ "$?" -eq "0" ]; then 
                echo -e "\001$Red\002"$(__git_ps1 "%s")" ";
            else 
                echo -e "\001$Red\002"$(__git_ps1 "{%s *}")" ";
            fi)"; 
        else 
            echo "$(echo `git status` | grep "nothing to commit" > /dev/null 2>&1; 
            if [ "$?" -eq "0" ]; then 
                echo -e "\001$Green\002"$(__git_ps1 "(%s)")" ";
            else 
                echo -e "\001$Yellow\002"$(__git_ps1 "{%s *}")" ";
            fi)"; 
        fi)"; 
    fi
}

export PS1=\\[$IBlack\\]$Time12h\\[$Color_Off\\]' \u@\h $(print_git_info)'\\[$Color_Off\\]'\W] $ '

EFFECTIVE_DISTRIBUTION="Unhandled"
if grep -qE "(Microsoft|WSL)" /proc/version &> /dev/null ; then
    echo "WSL"
elif [ "$(uname)" == "Darwin" ]; then
    EFFECTIVE_DISTRIBUTION="OSX"
elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
    EFFECTIVE_DISTRIBUTION="Unexpected Linux environment"
elif [ "$(expr substr $(uname -s) 1 10)" == "MINGW32_NT" ]; then
    EFFECTIVE_DISTRIBUTION="Unexpected Win32 environment"
elif [ "$(expr substr $(uname -s) 1 10)" == "MINGW64_NT" ] || [ "$(expr substr $(uname -s) 1 7)" == "MSYS_NT" ]; then
    EFFECTIVE_DISTRIBUTION="Windows"
fi

# echo $EFFECTIVE_DISTRIBUTION
# Variables
case $EFFECTIVE_DISTRIBUTION in
    OSX)
        # curl -o ~/.git-prompt.sh \
        #    https://raw.githubusercontent.com/git/git/master/contrib/completion/git-prompt.sh
        source ~/.git-prompt.sh

        if [ -f `brew --prefix`/etc/bash_completion.d/git-completion.bash ]; then
            . `brew --prefix`/etc/bash_completion.d/git-completion.bash
            . `brew --prefix`/etc/bash_completion.d/git-prompt.sh
        fi

        export PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin
        export JAVA_HOME=`/usr/libexec/java_home`

        export PATH=$JAVA_HOME/bin:$PATH

        # android / gradle / buck setup
        export ANDROID_HOME=/Users/$USER/Library/Android/sdk
        export ANDROID_SDK=$ANDROID_HOME
        export ANDROID_SDK_ROOT=$ANDROID_SDK
        export ANDROID_NDK=$ANDROID_SDK/ndk-bundle
        export ANDROID_NDK_HOME=$ANDROID_NDK
        unset ANDROID_NDK_REPOSITORY

        export PATH=${PATH}:$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools:$ANDROID_NDK

        # appengine setup
        export APPENGINE_HOME=~/Downloads/appengine-java-sdk-1.9.54
        export PATH=$PATH:$APPENGINE_HOME/bin/
        ;;
    Windows)

        export JAVA_HOME=/c/Program\ Files/Java/jdk1.8.0_161/bin/
        export PATH=$JAVA_HOME/bin:$PATH
        export PATH=/c/Program\ Files\ \(x86\)/Vim/vim81/:$PATH
        ;;
esac


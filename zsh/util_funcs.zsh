#! /bin/zsh

#pragma once
PRAGMA_FILE_NAME="PRAGMA_${"${(%):-%1N}"//\./_}"
[ -n "${(P)PRAGMA_FILE_NAME}" ] && unset PRAGMA_FILE_NAME && return;
declare $PRAGMA_FILE_NAME=0
unset PRAGMA_FILE_NAME

alias myip='curl http://ipecho.net/plain; echo'

# kill_port_proc <port>
function kill_port_proc() {
    readonly port=${1:?"The port must be specified."}

    lsof -i tcp:"$port" | grep LISTEN | awk '{print $2}'
}

# update_java_home <version>
function __update_java_home() {
    readonly jver=${1:?"Version must be specified"}
    if (( ${+JAVA_HOME} )); then
        path[$path[(i)$JAVA_HOME/bin]]=()
    fi
    export JAVA_HOME=$(/usr/libexec/java_home -v $jver)
    path=($JAVA_HOME/bin $path)
}

if command -v /usr/libexec/java_home &> /dev/null; then
    __update_java_home 18
    alias chjava='__update_java_home'
fi

function make_python_venv() {
    python3 -m venv ./.venv
    cd .
}

function wintitle() {
    if [ -z "$1" ]; then
        echo "Missing window title"
    else
        echo -ne "\e]0;$1\a"
    fi
}

function list_colors() {
    echo "echoti colors - $(echoti colors)"
    echo "COLORTERM - $COLORTERM"

	for color in {000..015}; do
		print -nP "%F{$color}$color %f"
	done
	printf "\n"

	for color in {016..255}; do
		print -nP "%F{$color}$color %f"
		if [ $(($((color-16))%6)) -eq 5 ]; then
			printf "\n"
		fi
	done
}

function clear_pragmas() {
    # Undoes the pragma once guards in my source files.
    unset -m "PRAGMA_*"
}
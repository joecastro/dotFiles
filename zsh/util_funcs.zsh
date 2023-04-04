#! /bin/zsh

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

function wintitle() {
    if [ -z "$1" ]; then
        echo "Missing window title"
    else
        echo -ne "\e]0;$1\a"
    fi
}

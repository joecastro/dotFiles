#! /bin/bash

#pragma once

alias myip='curl http://ipecho.net/plain; echo'

# kill_port_proc <port>
function kill_port_proc() {
    readonly port=${1:?"The port must be specified."}

    lsof -i tcp:"$port" | grep LISTEN | awk '{print $2}'
}

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

# https://unix.stackexchange.com/questions/481285/linux-how-to-get-window-title-with-just-shell-script
function get_title() { (
    set -e
    ss=$(stty -g)
    trap 'exit 11' INT QUIT TERM
    trap 'stty "$ss"' EXIT
    e=$(printf '\033')
    st=$(printf '\234')
    t=
    stty -echo -icanon min 0 time "${2:-2}"
    printf %s "${1:-\033[21t}" > "$(tty)"
    while c=$(dd bs=1 count=1 2>/dev/null) && [ "$c" ]; do
        t="$t$c"
        case "$t" in
        $e*$e\\ | $e*$st)
            t=${t%"$e"\\}
            t=${t%"$st"}
            printf '%s\n' "${t#"$e"\][lL]}"
            exit 0
            ;;
        $e*) ;;
        *)
            break
            ;;
        esac
    done
    printf %s "$t"
    exit 1
); }

function list_colors() {
    local COLUMN_WIDTH=${1:-6}
    echo "echoti colors - $(echoti colors)"
    echo "COLORTERM - $COLORTERM"

    for color in {000..015}; do
        print -nP "%F{$color}$color %f"
    done
    printf "\n"

    for x in {0..0}; do # {0..8}
        for i in {30..37}; do
            for a in {40..47}; do
                print -nP "\e[$x;$i;$a""m\\\e[$x;$i;$a""m\e[0;37;40m "
            done
            printf "\033[0m\n"
        done
    done
    printf "\n"

    for color in {016..255}; do
        print -nP "%F{$color}$color %f"
        if [ $(($((color - 16)) % "${COLUMN_WIDTH}")) -eq $((COLUMN_WIDTH-1)) ]; then
            printf "\n"
        fi
    done
}

function clear_pragmas() {
    # Undoes the pragma once guards in my source files.
    unset -m "PRAGMA_*"
}

alias source_dotfiles='clear_pragmas; source ~/.zshenv; source ~/.zprofile; source ~/.zshrc'

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
    cd .; cd -
}

function wintitle() {
    if [ -z "$1" ]; then
        echo "Missing window title"
        return 1
    fi

    echo -ne "\e]0;${1}\a"
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

    # Normal colors
    for color in {0..7}; do
        printf "\e[38;5;%sm %s" "${color}" "${color}"
    done

    printf "\e[0m ||"

    # Bright colors
    for color in {8..15}; do
        printf "\e[38;5;%sm %s" "${color}" "${color}"
    done

    printf "\n"

    if [[ "$1" == "--short" ]]; then
        return
    fi

    for x in {0..0}; do # {0..8}
        for i in {30..37}; do
            for a in {40..47}; do
                printf "\e[%s;%s;%sm\\\e[%s;%s;%sm\e[0m " "${x}" "${i}" "${a}" "${x}" "${i}" "${a}"
            done
            printf "\n"
        done
    done
    printf "\n"

    local column_index=0
    local background_loop_color=16
    for color in {016..255}; do
        printf "\e[38;5;%sm %s" "${color}" "${color}"
        column_index=$((column_index + 1))
        if [ "$column_index" -eq "$COLUMN_WIDTH" ]; then
            printf "  \e[38;5;15m"
            while [ "$background_loop_color" -le "$color" ]; do
                # Colored background, white text, color value
                printf "\e[48;5;%sm   " "${background_loop_color}"
                background_loop_color=$((background_loop_color + 1))
            done

            printf "\e[0m\n"
            column_index=0
        fi
    done

    # Reset the color of the terminal
    printf "\e[0m\n"
}

if __is_shell_zsh; then
    function clear_pragmas() {
        # Undoes the pragma once guards in my source files.
        unset -m "PRAGMA_*"
    }

    alias source_dotfiles='clear_pragmas; source ~/.zshenv; source ~/.zprofile; source ~/.zshrc'
elif __is_shell_bash; then
    alias source_dotfiles='echo "Maybe later..."'
fi

if __is_shell_zsh; then
    # Linter is not happy with ZSH syntax in a bash script.
    function debug_color_env() {
        local color_var=${1:-"LS_COLORS"}
        # shellcheck disable=SC2034 disable=SC2296
        color_var=${(P)color_var}
        # shellcheck disable=SC2206 disable=SC2296
        local parts=(${(s/:/)color_var})
        # shellcheck disable=SC2128
        for ls_color in $parts; do
            echo -ne "\e[${ls_color##*=}m${ls_color%%=*}\e[0m "
        done
        echo ""
    }
else
    function debug_color_env() {
        local color_var=${1:-"LS_COLORS"}
        local color_value
        local parts

        # Read the value of the color variable
        color_value=$(eval echo \$"$color_var")

        # Split the color variable into parts
        IFS=':' read -r -a parts <<< "$color_value"

        # Iterate over the parts and print them
        for ls_color in "${parts[@]}"; do
            echo -ne "\e[${ls_color##*=}m${ls_color%%=*}\e[0m "
        done
        echo ""
    }
fi
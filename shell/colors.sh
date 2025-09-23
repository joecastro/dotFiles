#!/bin/bash

#pragma once
#pragma validate-dotfiles

#pragma requires platform.sh

# Named colors
export PINK_FLAMINGO='#FF5FFF'
export ORANGE='#FFA500'

if __is_shell_zsh; then
    autoload -U colors && colors

    function colorize() {
        local mode="prompt"
        if [[ "$1" == "--plain" ]]; then
            mode="plain"
            shift
        fi

        local text="$1"
        shift
        local fg_input="${1:-white}"
        shift || true

        local bg_input=""
        local style=""

        while (($#)); do
            case "$1" in
                bold|bright|normal)
                    style="$1"
                    ;;
                *)
                    if [[ -z "$bg_input" ]]; then
                        bg_input="$1"
                    fi
                    ;;
            esac
            shift
        done

        local fg_effect=""
        local color_token="${fg_input:-white}"
        if [[ ${color_token} == \#* ]]; then
            fg_effect="%F{${color_token}}"
        else
            fg_effect="${fg[$color_token]:-${fg[white]}}"
        fi

        local start_effect="${fg_effect}"
        case "$style" in
            bold)
                if [[ ${color_token} == \#* ]]; then
                    start_effect="%F{${color_token}}%B"
                else
                    start_effect="${fg_bold[$color_token]:-${fg[$color_token]:-${fg[white]}}}"
                fi
                ;;
            bright)
                if [[ ${color_token} == \#* ]]; then
                    start_effect="%F{${color_token}}"
                else
                    start_effect="${fg_bright[$color_token]:-${fg[$color_token]:-${fg[white]}}}"
                fi
                ;;
            normal|"")
                start_effect="${fg_effect}"
                ;;
            *)
                start_effect="${fg_effect}"
                ;;
        esac

        if [[ -n "$bg_input" ]]; then
            local bg_effect=""
            if [[ ${bg_input} == \#* ]]; then
                bg_effect="%K{${bg_input}}"
            else
                bg_effect="${bg[$bg_input]}"
            fi
            if [[ -n "$bg_effect" ]]; then
                start_effect+="${bg_effect}"
            fi
        fi

        local reset_effect="$reset_color"

        case "$mode" in
            plain)
                printf '%s%s%s' "$start_effect" "$text" "$reset_effect"
                ;;
            prompt)
                if [[ -z "$start_effect" && -z "$reset_effect" ]]; then
                    printf '%s' "$text"
                else
                    printf '%%{%s%%}%s%%{%s%%}' "$start_effect" "$text" "$reset_effect"
                fi
                ;;
        esac
    }

    return 0
fi

export RESET='\[\e[0m\]'

COLOR_ANSI_BLACK='\[\e[30m\]'
COLOR_ANSI_RED='\[\e[31m\]'
COLOR_ANSI_GREEN='\[\e[32m\]'
COLOR_ANSI_YELLOW='\[\e[33m\]'
COLOR_ANSI_BLUE='\[\e[34m\]'
COLOR_ANSI_MAGENTA='\[\e[35m\]'
COLOR_ANSI_CYAN='\[\e[36m\]'
COLOR_ANSI_WHITE='\[\e[37m\]'
COLOR_ANSI_BBLACK='\[\e[90m\]'
COLOR_ANSI_BRED='\[\e[91m\]'
COLOR_ANSI_BGREEN='\[\e[92m\]'
COLOR_ANSI_BYELLOW='\[\e[93m\]'
COLOR_ANSI_BBLUE='\[\e[94m\]'
COLOR_ANSI_BMAGENTA='\[\e[95m\]'
COLOR_ANSI_BCYAN='\[\e[96m\]'
COLOR_ANSI_BWHITE='\[\e[97m\]'

BG_COLOR_ANSI_BLACK='\[\e[40m\]'
BG_COLOR_ANSI_RED='\[\e[41m\]'
BG_COLOR_ANSI_GREEN='\[\e[42m\]'
BG_COLOR_ANSI_YELLOW='\[\e[43m\]'
BG_COLOR_ANSI_BLUE='\[\e[44m\]'
BG_COLOR_ANSI_MAGENTA='\[\e[45m\]'
BG_COLOR_ANSI_CYAN='\[\e[46m\]'
BG_COLOR_ANSI_WHITE='\[\e[47m\]'
BG_COLOR_ANSI_BBLACK='\[\e[100m\]'
BG_COLOR_ANSI_BRED='\[\e[101m\]'
BG_COLOR_ANSI_BGREEN='\[\e[102m\]'
BG_COLOR_ANSI_BYELLOW='\[\e[103m\]'
BG_COLOR_ANSI_BBLUE='\[\e[104m\]'
BG_COLOR_ANSI_BMAGENTA='\[\e[105m\]'
BG_COLOR_ANSI_BCYAN='\[\e[106m\]'
BG_COLOR_ANSI_BWHITE='\[\e[107m\]'

if __is_shell_old_bash; then

    export COLOR_ANSI='\[\e[37m\]'
    export BG_COLOR_ANSI='\[\e[40m\]'

    function is_valid_ansicolor() {
        case "$1" in
            white|black|red|green|yellow|blue|magenta|cyan) return 0 ;;
            bwhite|bblack|bred|bgreen|byellow|bblue|bmagenta|bcyan) return 0 ;;
            *) return 1 ;;
        esac
    }

else

# Named colors (basic ANSI 16)
declare -A COLOR_ANSI=(
    [black]="$COLOR_ANSI_BLACK"
    [red]="$COLOR_ANSI_RED"
    [green]="$COLOR_ANSI_GREEN"
    [yellow]="$COLOR_ANSI_YELLOW"
    [blue]="$COLOR_ANSI_BLUE"
    [magenta]="$COLOR_ANSI_MAGENTA"
    [cyan]="$COLOR_ANSI_CYAN"
    [white]="$COLOR_ANSI_WHITE"
    [bblack]="$COLOR_ANSI_BBLACK"
    [bred]="$COLOR_ANSI_BRED"
    [bgreen]="$COLOR_ANSI_BGREEN"
    [byellow]="$COLOR_ANSI_BYELLOW"
    [bblue]="$COLOR_ANSI_BBLUE"
    [bmagenta]="$COLOR_ANSI_BMAGENTA"
    [bcyan]="$COLOR_ANSI_BCYAN"
    [bwhite]="$COLOR_ANSI_BWHITE"
)

declare -A BG_COLOR_ANSI=(
    [black]="$BG_COLOR_ANSI_BLACK"
    [red]="$BG_COLOR_ANSI_RED"
    [green]="$BG_COLOR_ANSI_GREEN"
    [yellow]="$BG_COLOR_ANSI_YELLOW"
    [blue]="$BG_COLOR_ANSI_BLUE"
    [magenta]="$BG_COLOR_ANSI_MAGENTA"
    [cyan]="$BG_COLOR_ANSI_CYAN"
    [white]="$BG_COLOR_ANSI_WHITE"
    [bblack]="$BG_COLOR_ANSI_BBLACK"
    [bred]="$BG_COLOR_ANSI_BRED"
    [bgreen]="$BG_COLOR_ANSI_BGREEN"
    [byellow]="$BG_COLOR_ANSI_BYELLOW"
    [bblue]="$BG_COLOR_ANSI_BBLUE"
    [bmagenta]="$BG_COLOR_ANSI_BMAGENTA"
    [bcyan]="$BG_COLOR_ANSI_BCYAN"
    [bwhite]="$BG_COLOR_ANSI_BWHITE"
)

function is_valid_ansicolor() {
    local color="$1"
    [[ -n "${COLOR_ANSI[$color]}" ]]
}

fi

# Function for 256-color foreground: fg256 COLOR_CODE
function fg256() {
    printf '\[\e[38;5;%sm\]' "$1"
}

# Function for 256-color background: bg256 COLOR_CODE
function bg256() {
    printf '\[\e[48;5;%sm\]' "$1"
}

function is_valid_rgb() {
    local hex=${1#\#}  # strip leading # if present
    [[ "$hex" =~ ^[0-9A-Fa-f]{6}$ ]]
}

function fg_rgb() {
    local hex=${1#\#}  # strip leading # if present
    local r=$((16#${hex:0:2}))
    local g=$((16#${hex:2:2}))
    local b=$((16#${hex:4:2}))
    printf '\[\e[38;2;%s;%s;%sm\]' "$r" "$g" "$b"
}

# RGB background with hex: bg_rgb 112233
function bg_rgb() {
    local hex=${1#\#}
    local r=$((16#${hex:0:2}))
    local g=$((16#${hex:2:2}))
    local b=$((16#${hex:4:2}))
    printf '\[\e[48;2;%s;%s;%sm\]' "$r" "$g" "$b"
}

function fg_color() {
    local color="$1"
    if is_valid_rgb "$color"; then
        fg_rgb "$color"
    elif is_valid_ansicolor "$color"; then
        local varname="COLOR_ANSI_${color^^}"
        printf "%s" "${!varname}"
    else
        printf "%s" "${COLOR_ANSI_WHITE}"  # Default to white if invalid
    fi
}

function bg_color() {
    local color="$1"
    if is_valid_rgb "$color"; then
        bg_rgb "$color"
    elif is_valid_ansicolor "$color"; then
        local varname="BG_COLOR_ANSI_${color^^}"
        printf "%s" "${!varname}"
    else
            printf "%s" "${BG_COLOR_ANSI_BLACK}"  # Default to black if invalid
    fi
}

function __strip_prompt_wrappers() {
    local seq="$1"
    seq="${seq//\\[}"
    seq="${seq//\\]}"
    printf '%s' "${seq}"
}

function __normalize_ansicolor_name() {
    local style="$1"
    local color="$2"
    if [[ "$style" == "bright" ]] && is_valid_ansicolor "$color"; then
        if [[ "$color" != b* ]]; then
            printf '%s' "b${color}"
            return
        fi
    fi
    printf '%s' "${color}"
}

function colorize() {
    local mode="prompt"
    if [[ "$1" == "--plain" ]]; then
        mode="plain"
        shift
    fi

    local text="$1"
    shift
    local fg_input="${1:-white}"
    shift || true

    local bg_input=""
    local style=""

    while (($#)); do
        case "$1" in
            bold|bright|normal)
                style="$1"
                ;;
            *)
                if [[ -z "$bg_input" ]]; then
                    bg_input="$1"
                fi
                ;;
        esac
        shift
    done

    local normalized_color
    normalized_color="$( __normalize_ansicolor_name "$style" "$fg_input" )"

    local fg_seq
    fg_seq="$(fg_color "${normalized_color}")"
    fg_seq="$(__strip_prompt_wrappers "${fg_seq}")"

    local bg_seq=""
    if [[ -n "$bg_input" ]]; then
        bg_seq="$(bg_color "${bg_input}")"
        bg_seq="$(__strip_prompt_wrappers "${bg_seq}")"
    fi

    local bold_seq=""
    if [[ "$style" == "bold" ]]; then
        bold_seq='\e[1m'
    fi

    local start_codes="${bold_seq}${fg_seq}${bg_seq}"
    local reset_seq
    reset_seq="$(__strip_prompt_wrappers "${RESET}")"

    local start_effect reset_effect
    printf -v start_effect '%b' "${start_codes}"
    printf -v reset_effect '%b' "${reset_seq}"

    case "$mode" in
        plain)
            printf '%s%s%s' "${start_effect}" "${text}" "${reset_effect}"
            ;;
        prompt)
            if __is_shell_zsh; then
                if [[ -z "${start_effect}" && -z "${reset_effect}" ]]; then
                    printf '%s' "${text}"
                else
                    printf '%%{%s%%}%s%%{%s%%}' "${start_effect}" "${text}" "${reset_effect}"
                fi
            else
                if [[ -z "${start_effect}" && -z "${reset_effect}" ]]; then
                    printf '%s' "${text}"
                else
                    if [[ -n "${start_effect}" ]]; then
                        printf '%s' $'\001'"${start_effect}"$'\002'
                    fi
                    printf '%s' "${text}"
                    if [[ -n "${reset_effect}" ]]; then
                        printf '%s' $'\001'"${reset_effect}"$'\002'
                    fi
                fi
            fi
            ;;
    esac
}

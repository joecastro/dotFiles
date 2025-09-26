#! /usr/bin/env bash

#pragma once

#pragma requires debug.sh
#pragma requires env_funcs.sh

_dotTrace "Configuring iTerm2 shell integration"

if ! __is_iterm2_terminal; then
    _dotTrace "Skipping iTerm2 integration: not inside iTerm2"
    return 0
fi

if __is_shell_zsh; then
    # shellcheck disable=SC1091
    [[ -f "${DOTFILES_CONFIG_ROOT}/iterm2_shell_integration.zsh" ]] && source "${DOTFILES_CONFIG_ROOT}/iterm2_shell_integration.zsh"
elif __is_shell_bash; then
    shopt -u extdebug
    # shellcheck disable=SC1091
    [[ -f "${DOTFILES_CONFIG_ROOT}/iterm2_shell_integration.bash" ]] && source "${DOTFILES_CONFIG_ROOT}/iterm2_shell_integration.bash"
else
    echo "Unknown shell for iTerm2 integration"
    return 1
fi

if __is_shell_bash; then
    if declare -p precmd_functions &>/dev/null; then
        precmd_functions+=("__iterm_badge_nodeenv")
    else
        __cute_shell_header_add_warning "bash-preexec not loaded"
    fi
elif __is_shell_zsh; then
    if typeset -p precmd_functions &>/dev/null; then
        precmd_functions+=(__iterm_badge_nodeenv)
    else
        precmd_functions=(__iterm_badge_nodeenv)
    fi
fi

declare -a ITERM_COLOR_KEYS=( \
    "fg" \
    "bg" \
    "bold" \
    "link" \
    "selbg" \
    "selfg" \
    "curbg" \
    "curfg" \
    "underline" \
    "tab" \
    "black" \
    "red" \
    "green" \
    "yellow" \
    "blue" \
    "magenta" \
    "cyan" \
    "white" \
    "br_black" \
    "br_red" \
    "br_green" \
    "br_yellow" \
    "br_blue" \
    "br_magenta" \
    "br_cyan" \
    "br_white" \
)

# https://iterm2.com/documentation-escape-codes.html
function iterm_set_color() {
    local color_key=$1
    local color_value=$2

    # shellcheck disable=SC2199,SC2076
    if [[ ! "${ITERM_COLOR_KEYS[@]}" =~ "${color_key}" ]]; then
        echo "Invalid color key: ${color_key}"
        return 1
    fi

    printf '\033]1337;SetColors=%s=%s\007' "${color_key}" "${color_value}"
}

function iterm_get_attention() {
    printf "\033]" && printf "1337;RequestAttention=fireworks" && printf "\a"
}

function iterm_set_badge_text() {
    local badge_text="$1"
    printf "\033]1337;SetBadgeFormat=%s\007" "$(echo -n "${badge_text}" | base64)"
}

function __iterm_badge_nodeenv() {
    _dotTrace_enter "$@"

    if ! __is_in_node_project; then
        iterm_set_badge_text ""
        _dotTrace "Not in a Node.js project"
        _dotTrace_exit 0
        return
    fi

    if [[ -z "$APP_ENV" ]]; then
        iterm_set_badge_text ""
        _dotTrace "APP_ENV is not set"
        _dotTrace_exit 0
        return
    fi

    local badge_emoji="${EMOJI_ICON_MAP[X]}"
    case "$APP_ENV" in
        production) badge_emoji="${EMOJI_ICON_MAP[ALARM]}" ;;
        staging)    badge_emoji="${EMOJI_ICON_MAP[TEST_TUBE]}" ;;
        dev)        badge_emoji="${EMOJI_ICON_MAP[TOOL]}" ;;
        *)          badge_emoji="${EMOJI_ICON_MAP[X]}" ;;
    esac
    _dotTrace "Setting badge to: $badge_emoji APP_ENV=$APP_ENV"
    iterm_set_badge_text "$badge_emoji APP_ENV=$APP_ENV"
    _dotTrace_exit 0
}

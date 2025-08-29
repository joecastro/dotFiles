#! /bin/bash

#pragma once

#pragma requires platform.sh
#pragma requires cache.sh
#pragma requires icons.sh

_prompt_executing=""
function __konsole_integration_precmd() {
    _dotTrace_enter
    _dotTrace ""
    local ret="$?"
    if [[ "$_prompt_executing" != "0" ]]; then
        _PROMPT_SAVE_PS1="$PS1"
        _PROMPT_SAVE_PS2="$PS2"
        # shellcheck disable=SC2025
        PS1=$'%{\e]133;P;k=i\a%}'$PS1$'%{\e]133;B\a\e]122;> \a%}'
        PS2=$'%{\e]133;P;k=s\a%}'$PS2$'%{\e]133;B\a%}'
    fi
    if [[ "$_prompt_executing" != "" ]]; then
        echo -ne "\e]133;D;$ret;aid=$$\a"
    fi
    echo -ne "\e]133;A;cl=m;aid=$$\a"
    _prompt_executing=0
    _dotTrace_exit
}

function __konsole_integration_preexec() {
    _dotTrace_enter
    _dotTrace ""
    PS1="$_PROMPT_SAVE_PS1"
    PS2="$_PROMPT_SAVE_PS2"
    echo -ne "\e]133;C;\a"
    _prompt_executing=1
    _dotTrace_exit
}

function toggle_konsole_semantic_integration() {
    _dotTrace_enter

    function is_konsole_semantic_integration_active() {
        echo "${preexec_functions}" | grep -q __konsole_integration_preexec
    }

    function add_konsole_semantic_integration() {
        if ! is_konsole_semantic_integration_active; then
            preexec_functions+=("__konsole_integration_preexec")
            precmd_functions+=("__konsole_integration_precmd")
        fi
    }

    function remove_konsole_semantic_integration() {
        if is_konsole_semantic_integration_active; then
            preexec_functions=("${preexec_functions:#__konsole_integration_preexec}")
            precmd_functions=("${precmd_functions:#__konsole_integration_precmd}")
        fi
    }

    local do_enable_integration
    if [[ "$1" == "0" ]]; then
        _dotTrace "Removing Konsole semantic integration because of explicit argument"
        do_enable_integration=1
    elif [[ "$1" == "1" ]]; then
        _dotTrace "Adding Konsole semantic integration because of explicit argument"
        do_enable_integration=0
    else
        _dotTrace "Toggling Konsole semantic integration - current state: $(is_konsole_semantic_integration_active)"
        if is_konsole_semantic_integration_active; then
            do_enable_integration=1
        else
            do_enable_integration=0
        fi
    fi

    if [[ ${do_enable_integration} -eq 1 ]]; then
        _dotTrace "Removing Konsole semantic integration"
        remove_konsole_semantic_integration
    else
        _dotTrace "Adding Konsole semantic integration"
        add_konsole_semantic_integration
    fi
    _dotTrace_exit
}

function __update_konsole_profile() {
    _dotTrace_enter
    local active_dynamic_prompt_style
    active_dynamic_prompt_style=$(__cache_get "ACTIVE_DYNAMIC_PROMPT_STYLE")

    local arg=""
    if [[ "$active_dynamic_prompt_style" == "Repo" ]]; then
        arg="Colors=Android Colors"
    else
        arg="Colors=$(hostname) Colors"
    fi
    if [[ $(__cache_get "KONSOLE_PROFILE") == "${arg}" ]]; then
        _dotTrace "already set"
        _dotTrace_exit
        return
    fi

    _dotTrace "setting konsole profile"
    echo -ne "\e]50;${arg}\a"
    __cache_put "KONSOLE_PROFILE" "${arg}" 30000
    _dotTrace_exit
}

function __do_konsole_shell_integration() {
    _dotTrace_enter
    source "${DOTFILES_CONFIG_ROOT}/konsole_color_funcs.sh"

    if __is_shell_zsh; then
        toggle_konsole_semantic_integration 1

        # precmd_functions+=(__update_konsole_profile)
    fi
    _dotTrace_exit
}

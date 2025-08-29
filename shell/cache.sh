#! /bin/bash

#pragma once

#pragma requires platform.sh

if __is_shell_old_bash; then
    function __cache_available() { return 1; }
    function __cache_put() { return 1; }
    function __cache_get_expiration() { return 1; }
    function __cache_get() { return 1; }
    function __cache_clear() { return 1; }

    return 1
fi

declare -A Z_CACHE=()

function __cache_available() { return 0; }

function __cache_put() {
    local key="$1" value="$2" expiration_time="${3:-0}"
    Z_CACHE[${key}]="${value}"
    if [[ ${expiration_time} -gt 0 ]]; then
        Z_CACHE[${key}_expiration]="$(( $(date +%s) + expiration_time ))"
    else
        Z_CACHE[${key}_expiration]=0
    fi
}

function __cache_get_expiration() {
    local key="$1" expiration_value
    expiration_value="${Z_CACHE[${key}_expiration]}"
    if [[ -n "${expiration_value}" ]]; then
        echo -n "${expiration_value}"
        return 0
    fi
    return 1
}

function __cache_get() {
    local key="$1" cache_expiration
    if ! cache_expiration=$(__cache_get_expiration "${key}"); then return 1; fi
    if [[ "${cache_expiration}" -gt 0 ]] && [[ "${cache_expiration}" -lt "$(date +%s)" ]]; then return 1; fi
    if [[ -n "${Z_CACHE[${key}]}" ]]; then echo -n "${Z_CACHE[${key}]}"; return 0; fi
    return 1
}

function __cache_clear() {
    if [[ -n "$1" ]]; then Z_CACHE[${1}_expiration]=1; else Z_CACHE=(); fi
}

if __is_shell_zsh; then
# Prevent bash from attempting to interpret invalid zsh syntax.
# shellcheck disable=SC1091
source /dev/stdin <<'EOF'
    function __cache_print() {
        local expires_soon_threshold=1800
        local current_time
        current_time="$(date +%s)"
        local expiration_value
        local suffix
        for key in "${(@k)Z_CACHE}"; do
            if expiration_value=$(__cache_get_expiration "${key}"); then
                if [[ "${expiration_value}" -eq 0 ]]; then
                    suffix=""
                elif [[ "${expiration_value}" -lt "${current_time}" ]]; then
                    suffix=" (expired)"
                else
                    local remaining_time=$((expiration_value - current_time))
                    local remaining_minutes=$((remaining_time / 60))
                    suffix=" (expires in ${remaining_minutes} minutes)"
                fi
                echo "${key}=\"${Z_CACHE[$key]}\"${suffix}"
            fi
        done
    }

    function __cache_save() {
        local cache_file="$1"
        local key
        local value
        for key value in "${(@kv)Z_CACHE}"; do
            echo "${key}=${value}"
        done > "${cache_file}"
    }

    function __cache_load() {
        local cache_file="$1"
        local key
        local value
        while read -r key value; do
            Z_CACHE["${key}"]="${value}"
        done < "${cache_file}"
    }
EOF
else
    function __cache_print() { return 0; }
fi

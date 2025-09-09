#! /bin/bash

# Stack implementation (portable bash/zsh): newline-delimited string

# Declare a new stack (unconditionally)
function _stack_declare() {
    local name=$1
    eval "$name=''"
}

# Declare stack only if not already defined
function _stack_safe_declare() {
    local name=$1
    if ! eval "[[ \${$name+set} ]]" 2>/dev/null; then
        eval "$name=''"
    fi
}

# Push a value onto the stack
function _stack_push() {
    local name=$1
    local value=$2
    local stack
    eval 'stack="$'"$name"'"'
    if [[ -z "$stack" ]]; then
        stack="$value"
    else
        stack="${stack}"$'\n'"$value"
    fi
    eval "$name=\"\$stack\""
}

# Pop the top value from the stack and print it
function _stack_pop() {
    local name=$1
    local stack top rest
    eval 'stack="$'"$name"'"'
    [ -z "$stack" ] && return 1

    top="${stack##*$'\n'}"
    rest="${stack%$'\n'*}"
    [ "$top" = "$stack" ] && rest=''

    eval "$name=\"\$rest\""
}

# Peek at the top value
function _stack_top() {
    local name=$1
    local stack
    eval 'stack="$'"$name"'"'
    [ -z "$stack" ] && return 1
    printf '%s\n' "${stack##*$'\n'}"
}

# Get number of elements in the stack
function _stack_size() {
    local name=$1
    local stack
    eval 'stack="$'"$name"'"'
    if [ -z "$stack" ]; then
        echo 0
        return
    fi
    local -i n=0
    while IFS= read -r _; do
        ((n++))
    done <<< "$stack"
    printf '%d\n' "$n"
}

# Check if the stack is empty (returns 0 if empty)
function _stack_is_empty() {
    local name=$1
    local stack
    eval 'stack="$'"$name"'"'
    [ -z "$stack" ]
}

# Clear the stack
function _stack_clear() {
    local name=$1
    eval "$name=''"
}

# Print stack elements joined by a given separator
function _stack_print() {
    local name=$1
    local sep=$2
    local stack
    local first=1
    eval 'stack="$'"$name"'"'
    [ -z "$stack" ] && return

    while IFS= read -r line; do
        if [ $first -eq 1 ]; then
            printf '%s' "$line"
            first=0
        else
            printf '%s%s' "$sep" "$line"
        fi
    done <<< "$stack"
    echo
}

# Time helpers

# Prints a high-resolution seconds timestamp as a float-like string.
function __time_now() {
    if [[ -n "${EPOCHREALTIME:-}" ]]; then
        printf '%s' "${EPOCHREALTIME}"
        return 0
    fi

    # Fallback: date; precision depends on platform (may be seconds)
    if date +%s.%N 2>/dev/null | grep -q '\.'; then
        date +%s.%N
        return 0
    fi

    date +%s.000 2>/dev/null
}

# Prints end-start in seconds with millisecond precision.
# Use __time_now if end is omitted.
function __time_delta() {
    local start="$1"
    local end="${2:-}"
    if [[ -z "$end" ]]; then
        end="$(__time_now)"
    fi
    awk -v n="$end" -v s="$start" 'BEGIN { printf "%.3f", (n - s) }'
}

# Format an epoch seconds value (float-like) as HH:MM:SS.mmm
function __time_format() {
    if [[ -z "$1" ]]; then
        date +%T.%3N
        return 0
    fi

    local epoch_val="$1"
    local sec_part="${epoch_val%.*}"
    local frac_part="${epoch_val#*.}"
    local msec="000"
    if [[ -n "$frac_part" && "$frac_part" != "$epoch_val" ]]; then
        msec="$(printf '%03d' "${frac_part:0:3}")"
    fi
    local hms
    if date -r "$sec_part" +%T > /dev/null 2>&1; then
        hms="$(date -r "$sec_part" +%T)"
    elif date -d "@$sec_part" +%T > /dev/null 2>&1; then
        hms="$(date -d "@$sec_part" +%T)"
    else
        hms="$(date +%T)"
    fi
    printf '%s.%s' "$hms" "$msec"
}

# Trace helpers

function __dotTrace_print() {
    local indent="$1"
    local trace_type="$2"
    local timestamp=""
    local content="$4"

    if [[ -n "${TRACE_DOTFILES_TIMING}" ]]; then
        timestamp="$(__time_format "$3"): "
    fi

    printf '%s%s%s %s\n' "$timestamp" "${indent}" "${trace_type}" "${content}" >&2
}

function __dotTrace_flushPending() {
    # Usage: __dotTrace_flushPending [exit_status]
    # Modes:
    # - TRACE_ENTER: flush a pending enter line (no args)
    # - TRACE_FUNCTION: print a function summary (with exit_status arg)
    local -i status_val=0
    local mode="TRACE_ENTER"
    if (( $# > 0 )); then
        mode="TRACE_FUNCTION"
        status_val="${1}"
    fi

    if [[ -z "${TRACE_DOTFILES_PENDING_LABEL:-}" ]]; then
        return 1
    fi

    # If this is an enter flush then the current indent is too deep by one level
    local indent_prefix="${TRACE_DOTFILES_ACTIVE_INDENT}"
    if [[ "${mode}" == "TRACE_ENTER" ]]; then
        indent_prefix="${TRACE_DOTFILES_ACTIVE_INDENT%  }"
    fi

    local status_suffix=""
    if [[ "${mode}" == "TRACE_FUNCTION" ]]; then
        local formatted_duration="$(__time_delta "${TRACE_DOTFILES_PENDING_START}")"
        status_suffix=", status: ${status_val}, duration: ${formatted_duration}s"
    fi

    __dotTrace_print "${indent_prefix}" "${mode}" "${TRACE_DOTFILES_PENDING_START}" "${TRACE_DOTFILES_PENDING_LABEL}${status_suffix}"

    unset TRACE_DOTFILES_PENDING_LABEL
    unset TRACE_DOTFILES_PENDING_START
    return 0
}

function __dotTrace_incrementIndent() {
    TRACE_DOTFILES_ACTIVE_INDENT="${TRACE_DOTFILES_ACTIVE_INDENT:-}  "
}

function __dotTrace_decrementIndent() {
    TRACE_DOTFILES_ACTIVE_INDENT="${TRACE_DOTFILES_ACTIVE_INDENT%  }"
}

function _dotTrace() {
    if [[ -n "${TRACE_DOTFILES}" ]]; then
        # If there's a pending ENTER for this frame, flush it now
        __dotTrace_flushPending
        __dotTrace_print "${TRACE_DOTFILES_ACTIVE_INDENT}" "TRACE" "$(__time_now)" "$*"
    fi
}

function _dotTrace_enter() {
    if [[ -n "${TRACE_DOTFILES}" ]]; then
        _stack_safe_declare TRACE_DOTFILES_STACK

        # Flush any pending enter for the parent frame before nesting
        __dotTrace_flushPending

        local func_name=""
        # If indent is zero augment this line with the caller's caller
        local extra_label=""
        if [[ -n "${ZSH_VERSION}" ]]; then
            # In zsh, $funcstack[1] is the current function; the caller is [2]
            # shellcheck disable=SC2154
            func_name="${funcstack[2]:-<toplevel>}"
            if [[ -z "${TRACE_DOTFILES_ACTIVE_INDENT}" ]] && [[ -n "${funcstack[3]}" ]]; then
                extra_label=" caller: ${funcstack[3]}"
            fi
        else
            func_name="${FUNCNAME[1]}"
            if [[ -z "${TRACE_DOTFILES_ACTIVE_INDENT}" ]] && [[ -n "${FUNCNAME[2]}" ]]; then
                extra_label=" caller: ${FUNCNAME[2]}"
            fi
        fi

        _stack_push TRACE_DOTFILES_STACK "$func_name"
        __dotTrace_incrementIndent

        # Defer the enter line; print it on first inner activity
        TRACE_DOTFILES_PENDING_LABEL="${func_name}($*)$extra_label"
        TRACE_DOTFILES_PENDING_START="$(__time_now)"
    fi
}

function _dotTrace_exit() {
    # Capture caller's last exit code immediately
    local -i exit_status=${1:-$?}
    if [[ -n "${TRACE_DOTFILES}" ]] ; then
        # Restore indent to the entry level for this frame
        __dotTrace_decrementIndent

        # Try to print the single-line function summary; fall back to EXIT
        if ! __dotTrace_flushPending "${exit_status}"; then
            local func_name
            func_name=$(_stack_top TRACE_DOTFILES_STACK)
            __dotTrace_print "${TRACE_DOTFILES_ACTIVE_INDENT}" "TRACE_EXIT" "$(__time_now)" "${func_name} status=${exit_status}"
        fi
        _stack_pop TRACE_DOTFILES_STACK
    fi
    return ${exit_status}
}

function toggle_trace_dotfiles() {
    if [[ -n "${TRACE_DOTFILES}" ]]; then
        unset TRACE_DOTFILES
    else
        export TRACE_DOTFILES=1
        if [[ -n "$1" ]]; then
            TRACE_DOTFILES_TIMING=1
        fi
    fi
}

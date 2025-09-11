#! /bin/bash

#pragma once
#pragma requires stack.sh

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
    # Build milliseconds via string padding/truncation to avoid integer parsing.
    if [[ "$epoch_val" == *.* ]]; then
        msec="${frac_part}000"
        msec="${msec:0:3}"
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

# Returns an identifier for the current shell context (separates subshells).
function __dotTrace_shell_pid() {
    if [[ -n ${BASH_VERSION:-} ]]; then
        if [[ -n ${BASHPID:-} ]]; then
            printf '%s' "${BASHPID}"
        else
            printf '%s:%s:%s' "$$" "${BASH_SUBSHELL:-0}" "${SHLVL:-0}"
        fi
        return 0
    fi
    # zsh: include subshell depth and SHLVL for stable context separation
    printf '%s:%s:%s' "$$" "${ZSH_SUBSHELL:-0}" "${SHLVL:-0}"
}

# Returns 0 if running inside a subshell context.
function __dotTrace_is_subshell() {
    if [[ -n ${ZSH_VERSION:-} ]]; then
        (( ZSH_SUBSHELL > 0 ))
        return $?
    elif [[ -n ${BASH_VERSION:-} ]]; then
        if [[ -n ${BASHPID:-} ]]; then
            [[ "$$" != "${BASHPID}" ]]
            return $?
        fi
        # Fallback: treat any BASH_SUBSHELL > 0 as subshell (older bash)
        (( ${BASH_SUBSHELL:-0} > 0 ))
        return $?
    fi
    return 1
}

# Returns a stable context anchor for the root interactive shell.
function __dotTrace_root_ctx_id() {
    printf '%s:%s' "$$" "${SHLVL:-0}"
}

# Returns numeric subshell depth (0 for top-level shell).
function __dotTrace_subshell_depth() {
    if [[ -n ${ZSH_VERSION:-} ]]; then
        printf '%d' "${ZSH_SUBSHELL:-0}"
        return 0
    elif [[ -n ${BASH_VERSION:-} ]]; then
        # In older bash, BASH_SUBSHELL still increments for ( ... ) and $() even if BASHPID is missing
        printf '%d' "${BASH_SUBSHELL:-0}"
        return 0
    fi
    printf '%d' 0
}

# Colorize a seconds string by threshold; returns colored numeric string.
function __dotTrace_colorize_duration() {
    local sec="$1"
    # Normalize empty/invalid input
    if [[ -z "$sec" ]]; then
        printf '%s' "0.000"
        return 0
    fi
    # Decide color by numeric comparison via awk
    awk -v s="$sec" 'BEGIN { if (s > 0.100) exit 100; else if (s > 0.050) exit 50; else exit 0 }'
    local rc=$?
    local color=""
    if (( rc == 100 )); then
        color="31" # red
    elif (( rc == 50 )); then
        color="33" # yellow
    fi
    if [[ -n "$color" ]]; then
        printf '\e[%sm%s\e[0m' "$color" "$sec"
    else
        printf '%s' "$sec"
    fi
}

function __dotTrace_print() {
    local indent="$1"
    local trace_type="$2"
    local ts_arg="$3"
    local timestamp=""
    local content="$4"

    # Compute the printable timestamp
    if [[ -z "${DOTFILES_INIT_EPOCHREALTIME_END}" ]]; then
        # If the INIT check hasn't completed yet, I actually want to see what's
        # causing a slow startup.
        if [[ -z "${DOTFILES_INIT_EPOCHREALTIME_START}" ]]; then
            timestamp="-0.000"
        else
            timestamp="$(__time_delta "${DOTFILES_INIT_EPOCHREALTIME_START}")"
        fi
    else
        timestamp="$(__time_format "$ts_arg")"
    fi

    # Compute and update the inter-trace gap baseline per context

    # Compute and update the inter-trace gap
    local now_ts
    now_ts="$(__time_now)"
    local gap_suffix=""
    local ctx_pid
    ctx_pid="$(__dotTrace_shell_pid)"
    if [[ -n "${TRACE_DOTFILES_LAST_TS_PID}" && "${TRACE_DOTFILES_LAST_TS_PID}" != "${ctx_pid}" ]]; then
        # New subshell (or different shell context): reset gap baseline
        unset TRACE_DOTFILES_LAST_TS
    fi
    if [[ -n "${TRACE_DOTFILES_LAST_TS}" ]]; then
        local gap_raw
        gap_raw="$(__time_delta "${TRACE_DOTFILES_LAST_TS}" "$now_ts")"
        if [[ "$trace_type" == "TRACE" || "$trace_type" == "TRACE_ENTER" ]]; then
            local gap_colored
            gap_colored="$(__dotTrace_colorize_duration "$gap_raw")"
            gap_suffix=" gap: ${gap_colored}s"
        fi
    fi
    TRACE_DOTFILES_LAST_TS="$now_ts"
    TRACE_DOTFILES_LAST_TS_PID="$ctx_pid"

    local type_label="$trace_type"
    # Surround TRACE type with parens per subshell depth (relative to baseline).
    local depth
    depth="$(__dotTrace_subshell_depth)"
    local anchor_id
    anchor_id="$(__dotTrace_root_ctx_id)"
    if [[ -n "${TRACE_DOTFILES_BASE_DEPTH_ANCHOR}" && "${TRACE_DOTFILES_BASE_DEPTH_ANCHOR}" != "${anchor_id}" ]]; then
        unset TRACE_DOTFILES_BASE_SUBSHELL_DEPTH
        unset TRACE_DOTFILES_BASE_SHLVL
    fi
    if [[ -z "${TRACE_DOTFILES_BASE_SUBSHELL_DEPTH}" ]]; then
        TRACE_DOTFILES_BASE_SUBSHELL_DEPTH="${depth}"
        TRACE_DOTFILES_BASE_DEPTH_ANCHOR="${anchor_id}"
        TRACE_DOTFILES_BASE_SHLVL="${SHLVL:-0}"
    fi
    local rel_depth=$(( depth - ${TRACE_DOTFILES_BASE_SUBSHELL_DEPTH:-0} ))
    # In bash, some nesting shows via SHLVL; include that as a fallback signal
    local curr_shlvl=${SHLVL:-0}
    local base_shlvl=${TRACE_DOTFILES_BASE_SHLVL:-0}
    local shlvl_rel=$(( curr_shlvl - base_shlvl ))
    if (( shlvl_rel > rel_depth )); then
        rel_depth=$shlvl_rel
    fi
    if (( rel_depth < 0 )); then rel_depth=0; fi
    if (( rel_depth > 0 )); then
        local pfx="" sfx=""
        local i
        for (( i=0; i<rel_depth; i++ )); do
            pfx+="("
            sfx+=")"
        done
        type_label="${pfx}${type_label}${sfx}"
    fi

    # Depth limiting disabled

    # Verbose depth/context annotation disabled

    printf '%s: %s%s %s%s\n' "$timestamp" "${indent}" "${type_label}" "${content}" "${gap_suffix}" >&2
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
        local formatted_duration colored_duration
        formatted_duration="$(__time_delta "${TRACE_DOTFILES_PENDING_START}")"
        colored_duration="$(__dotTrace_colorize_duration "$formatted_duration")"
        status_suffix=", status: ${status_val}, duration: ${colored_duration}s"
    fi

    # For top-level TRACE_ENTER, align subshell baseline to current depth so rel=0
    if [[ "${mode}" == "TRACE_ENTER" && -z "${indent_prefix}" ]]; then
        local __anchor_id __depth
        __anchor_id="$(__dotTrace_root_ctx_id)"
        __depth="$(__dotTrace_subshell_depth)"
        TRACE_DOTFILES_BASE_SUBSHELL_DEPTH="${__depth}"
        TRACE_DOTFILES_BASE_DEPTH_ANCHOR="${__anchor_id}"
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
        _stack_safe_declare TRACE_DOTFILES_START_STACK

        # Flush any pending enter for the parent frame before nesting
        __dotTrace_flushPending

        # Reset gap and baseline at top-level for this root context
        local __ctx_pid __now_ts __depth __base_depth __rel_depth __anchor_id
        __ctx_pid="$(__dotTrace_shell_pid)"
        __now_ts="$(__time_now)"
        __depth="$(__dotTrace_subshell_depth)"
        __anchor_id="$(__dotTrace_root_ctx_id)"
        __base_depth="${TRACE_DOTFILES_BASE_SUBSHELL_DEPTH:-}"
        if [[ -z "$__base_depth" || "${TRACE_DOTFILES_BASE_DEPTH_ANCHOR}" != "$__anchor_id" ]]; then
            TRACE_DOTFILES_BASE_SUBSHELL_DEPTH="$__depth"
            TRACE_DOTFILES_BASE_DEPTH_ANCHOR="$__anchor_id"
            __base_depth="$__depth"
        fi
        # If this is the root frame for a new sequence, force baseline to current depth
        if _stack_is_empty TRACE_DOTFILES_STACK; then
            TRACE_DOTFILES_BASE_SUBSHELL_DEPTH="$__depth"
            TRACE_DOTFILES_BASE_DEPTH_ANCHOR="$__anchor_id"
            __base_depth="$__depth"
        fi
        __rel_depth=$(( __depth - ${__base_depth:-0} ))
        if (( __rel_depth <= 0 )); then
            TRACE_DOTFILES_LAST_TS="$__now_ts"
            TRACE_DOTFILES_LAST_TS_PID="$__ctx_pid"
        fi

        local func_name=""
        # If this is the root frame, append caller (or <toplevel>)
        local extra_label=""
        local -i is_root_frame=0
        if _stack_is_empty TRACE_DOTFILES_STACK; then
            is_root_frame=1
        fi
        if [[ -n "${ZSH_VERSION}" ]]; then
            # In zsh, $funcstack[1] is the current function; the caller is [2]
            # shellcheck disable=SC2154
            func_name="${funcstack[2]:-<toplevel>}"
            if (( is_root_frame )); then
                local caller_label="${funcstack[3]:-<toplevel>}"
                extra_label=" caller: ${caller_label}"
            fi
        else
            func_name="${FUNCNAME[1]}"
            if (( is_root_frame )); then
                local caller_label="${FUNCNAME[2]:-<toplevel>}"
                extra_label=" caller: ${caller_label}"
            fi
        fi

        _stack_push TRACE_DOTFILES_STACK "$func_name"
        __dotTrace_incrementIndent

        # Defer the enter line; print on first inner activity
        local now
        now="$(__time_now)"
        # Avoid stray spaces when there are no args
        local arg_str=""
        if (( $# > 0 )); then
            arg_str="$*"
        fi
        TRACE_DOTFILES_PENDING_LABEL="${func_name}(${arg_str})$extra_label"
        TRACE_DOTFILES_PENDING_START="$now"
        _stack_push TRACE_DOTFILES_START_STACK "$now"
    fi
}

function _dotTrace_exit() {
    # Capture caller's last exit code immediately
    local -i exit_status=${1:-$?}
    if [[ -n "${TRACE_DOTFILES}" ]] ; then
        # Restore indent to the entry level for this frame
        __dotTrace_decrementIndent

        # Grab the start time for this frame (if any) to compute total duration
        local frame_start=""
        if ! _stack_is_empty TRACE_DOTFILES_START_STACK; then
            frame_start=$(_stack_top TRACE_DOTFILES_START_STACK)
        fi

        # Try to print the single-line function summary; fall back to EXIT
        if ! __dotTrace_flushPending "${exit_status}"; then
            local func_name
            func_name=$(_stack_top TRACE_DOTFILES_STACK)
            local duration_suffix=""
            if [[ -n "$frame_start" ]]; then
                local raw_dur="$(__time_delta "$frame_start")"
                local colored_dur="$(__dotTrace_colorize_duration "$raw_dur")"
                duration_suffix=", duration: ${colored_dur}s"
            fi
            __dotTrace_print "${TRACE_DOTFILES_ACTIVE_INDENT}" "TRACE_EXIT" "$(__time_now)" "${func_name}, status: ${exit_status}${duration_suffix}"
        fi
        _stack_pop TRACE_DOTFILES_STACK
        if ! _stack_is_empty TRACE_DOTFILES_START_STACK; then
            _stack_pop TRACE_DOTFILES_START_STACK >/dev/null
        fi
    fi
    return ${exit_status}
}

function toggle_trace_dotfiles() {
    if [[ -n "${TRACE_DOTFILES}" ]]; then
        unset TRACE_DOTFILES
        unset TRACE_DOTFILES_LAST_TS
        unset TRACE_DOTFILES_LAST_TS_PID
        unset TRACE_DOTFILES_BASE_SUBSHELL_DEPTH
        unset TRACE_DOTFILES_BASE_DEPTH_ANCHOR
        unset TRACE_DOTFILES_BASE_SHLVL
    else
        export TRACE_DOTFILES=1
        unset TRACE_DOTFILES_LAST_TS
        unset TRACE_DOTFILES_LAST_TS_PID
        unset TRACE_DOTFILES_BASE_SUBSHELL_DEPTH
        unset TRACE_DOTFILES_BASE_DEPTH_ANCHOR
        unset TRACE_DOTFILES_BASE_SHLVL
    fi
}

_dotTrace "Completed loading debug.sh"

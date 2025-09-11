#! /usr/bin/env bash

#pragma once

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

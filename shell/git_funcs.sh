#! /bin/bash

#pragma once

#pragma requires debug.sh
#pragma requires icons.sh
#pragma requires platform.sh
#pragma requires completion/git-prompt.sh

function __git_is_in_repo() {
    # Success if anywhere inside a Git repository (worktree or .git dir)
    git rev-parse --git-dir > /dev/null 2>&1
}

function __git_is_in_dotgit_dir() {
    [[ "$(git rev-parse --is-inside-git-dir 2>/dev/null)" == "true" ]]
}

function __git_is_detached_head() {
    git status 2> /dev/null | grep "HEAD detached" > /dev/null 2>&1
}

function __git_is_head_on_branch() {
    matching_branch=$(git show-ref --head | grep "$(__git_print_commit_sha)" | grep -o 'refs/remotes/[^ ]*' | head -n 1)
    [[ -n "$matching_branch" ]]
}

function __git_is_nothing_to_commit() {
    git status 2> /dev/null | grep "nothing to commit" > /dev/null 2>&1
}

function __git_is_in_worktree() {
    # git rev-parse --is-inside-work-tree | grep "true" > /dev/null 2>&1
    local root_worktree active_worktree

    root_worktree=$(git worktree list | head -n1 | awk '{print $1;}')
    active_worktree=$(git worktree list | grep "$(git rev-parse --show-toplevel)" | head -n1 | awk '{print $1;}')

    [[ "${root_worktree}" != "${active_worktree}" ]]
}

function __git_compare_upstream_changes() {
    # Fetch remote changes (use --quiet to suppress output)
    # git fetch --quiet

    local upstream
    upstream=$(git rev-parse --abbrev-ref --symbolic-full-name "@{u}" 2>/dev/null)
    if [[ -z "$upstream" ]]; then
        return 1
    fi

    local -i ahead=0 behind=0
    read -r ahead behind < <(git rev-list --left-right --count "$upstream"...HEAD 2>/dev/null | awk '{print $2, $1}')

    local -i result=0
    if (( ahead > 0 )); then
        result=$((result + 2))
    fi
    if (( behind > 0 )); then
        result=$((result + 4))
    fi
    return $result
}

function __git_has_unpushed_changes() {
    __git_compare_upstream_changes
    local -i result=$?
    return $(( (result & 2) == 0 ))
}

function __git_has_remote_changes() {
    __git_compare_upstream_changes
    local -i result=$?
    return $(( (result & 4) == 0 ))
}

function __git_is_on_default_branch() {
    local default_branch
    default_branch=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|^refs/remotes/origin/||')
    if [[ -z "${default_branch}" ]]; then
        return 1
    fi

    local current_branch
    current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
    [[ "${current_branch}" == "${default_branch}" ]]
}

function __git_print_commit_sha() {
    if ! __git_is_in_repo; then
        return 1
    fi

    git rev-parse --short HEAD
}

function __git_print_branch_name() {
    if ! __git_is_in_repo; then
        return 1
    fi

    local branch_name
    if ! branch_name=$(git symbolic-ref --short HEAD 2> /dev/null); then
        printf 'HEAD'
        return 1
    fi

    printf '%s' "${branch_name}"
}

function __print_git_branch() {
    local -i colorize=0
    if [[ "$1" == "--no-color" ]]; then
        colorize=1
    fi

    if ! __git_is_in_repo; then
        return 1
    fi
    if __git_is_in_dotgit_dir; then
        printf '%s' "${ICON_MAP[COD_TOOLS]} "
        return 0
    fi

    local branch_display=""
    if __git_is_detached_head; then
        branch_display+="${ICON_MAP[GIT_COMMIT]}"
        #branch_display+="$(__git_print_commit_sha)"
    else
        branch_display+="${ICON_MAP[GIT_BRANCH]}"
        #branch_display+="$(__git_print_branch_name)"
    fi
    branch_display+="$(__git_ps1 "%s")"

    if ! __git_is_nothing_to_commit; then
        branch_display+="*"
    fi

    if (( colorize == 0 )); then
        local color_hint
        color_hint=$(__git_branch_color_hint)
        branch_display=$(__echo_colored "${color_hint}" "${branch_display}")
    fi

    printf '%s' "${branch_display}"
}

function __print_git_branch_icon() {
    if ! __git_is_in_repo; then
        return 1
    fi
    if __git_is_in_dotgit_dir; then
        printf '%s' "${ICON_MAP[COD_TOOLS]}"
        return 0
    fi

    if ! __git_is_detached_head; then
        printf '%s' "${ICON_MAP[GIT_BRANCH]}"
        return 0
    fi

    if __git_is_head_on_branch; then
        printf '%s' "${ICON_MAP[GIT_BRANCH]}"
    else
        printf '%s' "${ICON_MAP[GIT_COMMIT]}"
    fi

    return 0
}

function __print_git_worktree() {
    if ! __git_is_in_repo; then
        return 1
    fi

    if ! __git_is_in_worktree; then
        return 1
    fi

    local root_worktree active_worktree submodule_worktree
    submodule_worktree=$(git rev-parse --show-superproject-working-tree)
    if [[ "${submodule_worktree}" != "" ]]; then
        printf '%s' "${ICON_MAP[LEGO]}${submodule_worktree##*/}"
        return 0
    fi

    root_worktree=$(git worktree list | head -n1 | awk '{print $1;}')
    active_worktree=$(git worktree list | grep "$(git rev-parse --show-toplevel)" | head -n1 | awk '{print $1;}')

    printf '%s' "${ICON_MAP[LEGO]}${root_worktree##*/}:${active_worktree##*/}"
}

function __print_git_pwd() {
    _dotTrace_enter "$@"
    local working_pwd=""

    if ! __git_is_in_repo; then
        _dotTrace "Not at all in a git repo"
        _dotTrace_exit 1
        return
    fi

    __git_is_on_default_branch
    local -i on_default_branch_status=$?
    # Normalize to boolean: 1 when on default branch, else 0
    local -i is_on_default_branch=$(( on_default_branch_status == 0 ))

    local color_hint
    local -i has_remote has_unpushed
    color_hint=$(__git_branch_color_hint)
    __git_has_remote_changes; has_remote=$(( $? == 0 ))
    __git_has_unpushed_changes; has_unpushed=$(( $? == 0 ))

    if (( has_remote && has_unpushed )); then
        _dotTrace "both remote and unpushed changes detected"
        is_on_default_branch=0
        working_pwd+="${ICON_MAP[ARROW_UPDOWN_THICK]}"
    elif (( has_remote )); then
        _dotTrace "remote changes detected"
        is_on_default_branch=0
        working_pwd+="${ICON_MAP[ARROW_DOWN_THICK]}"
    elif (( has_unpushed )); then
        _dotTrace "unpushed changes detected"
        is_on_default_branch=0
        working_pwd+="${ICON_MAP[ARROW_UP_THICK]}"
    fi

    working_pwd+="$(__print_git_branch_icon)"

    if (( is_on_default_branch )); then
        _dotTrace "on default branch - omitting branch name"
    else
        _dotTrace "not on default branch - using __git_ps1 for branch display"
        working_pwd+="$(__git_ps1 "%s")"
    fi

    if ! __git_is_nothing_to_commit; then
        _dotTrace "uncommitted changes detected"
        working_pwd+="*"
    fi

    working_pwd=$(__echo_colored "${color_hint}" "${working_pwd}")

    working_pwd+=" ${ICON_MAP[COD_PINNED]}"

    _dotTrace "branch prefix before anchored path: ${working_pwd}"

    local anchored_path
    if __git_is_in_dotgit_dir; then
        anchored_path=".git${PWD##*.git}"
    else
        # If we're in a git repo then show the current directory relative to the root of that repo.
        anchored_path="$(printf '%s' "$(git rev-parse --show-toplevel | xargs basename)/$(git rev-parse --show-prefix)")"
        anchored_path="${anchored_path%/}"
        anchored_path="$(__print_abbreviated_path "${anchored_path}" 0)"
    fi

    printf '%s' "${working_pwd}${anchored_path}"
    _dotTrace_exit
}

function __git_branch_color_hint() {
    if __git_is_nothing_to_commit; then
        printf 'green'
    elif __git_is_detached_head; then
        printf 'red'
    else
        printf 'yellow'
    fi
}

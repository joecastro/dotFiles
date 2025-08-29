#! /bin/bash

#pragma once

#pragma requires icons.sh
#pragma requires platform.sh
#pragma requires completion/git-prompt.sh

function __is_in_git_repo() {
    local ret_for_git_dir=0
    if [[ "$1" == "--git-dir-ok" ]]; then
        ret_for_git_dir=1
    fi

    if error_message=$(git branch 2>&1); then
        if git rev-parse --is-inside-git-dir | grep "true" > /dev/null 2>&1; then
            return ${ret_for_git_dir}
        fi
        return 0
    fi

    if [[ "${error_message}" == *"ot a git repository"* ]]; then
        return 2
    fi

    return 1
}

function __git_is_in_git_dir() {
    __is_in_git_repo --git-dir-ok
    [[ "$?" == "1" ]]
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

    local ahead behind
    read -r ahead behind < <(git rev-list --left-right --count "$upstream"...HEAD 2>/dev/null | awk '{print $2, $1}')

    local result=0
    if [[ "$ahead" -gt 0 ]]; then
        result=$((result + 2))
    fi
    if [[ "$behind" -gt 0 ]]; then
        result=$((result + 4))
    fi
    return $result
}

function __git_has_unpushed_changes() {
    __git_compare_upstream_changes
    local result=$?
    return $(( (result & 2) == 0 ))
}

function __git_has_remote_changes() {
    __git_compare_upstream_changes
    local result=$?
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
    if ! __is_in_git_repo; then
        echo -n ""
        return 1
    fi

    git rev-parse --short HEAD
}

function __git_print_branch_name() {
    if ! __is_in_git_repo; then
        echo -n ""
        return 1
    fi

    local branch_name
    if ! branch_name=$(git symbolic-ref --short HEAD 2> /dev/null); then
        echo -n "HEAD"
        return 1
    fi

    echo -n "${branch_name}"
}

function __print_git_branch() {
    local colorize=0
    if [[ "$1" == "--no-color" ]]; then
        colorize=1
    fi

    __is_in_git_repo --git-dir-ok
    local git_repo_result=$?
    if [[ ${git_repo_result} == 2 ]]; then
        echo -n ""
        return 1
    elif [[ ${git_repo_result} == 1 ]]; then
        echo -n "${ICON_MAP[COD_TOOLS]} "
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

    if [[ ${colorize} -eq 0 ]]; then
        local color_hint
        color_hint=$(__git_branch_color_hint)
        branch_display=$(__echo_colored "${color_hint}" "${branch_display}")
    fi

    echo -ne "${branch_display}"
}

function __print_git_branch_icon() {
    __is_in_git_repo --git-dir-ok
    local git_repo_result=$?
    if [[ $git_repo_result == 2 ]]; then
        echo -n ""
        return 1
    fi

    if [[ $git_repo_result == 1 ]]; then
        echo -n "${ICON_MAP[COD_TOOLS]}"
        return 0
    fi

    if ! __git_is_detached_head; then
        echo -n "${ICON_MAP[GIT_BRANCH]}"
        return 0
    fi

    if __git_is_head_on_branch; then
        echo -n "${ICON_MAP[GIT_BRANCH]}"
    else
        echo -n "${ICON_MAP[GIT_COMMIT]}"
    fi

    return 0
}

function __print_git_worktree() {
    if ! __is_in_git_repo; then
        echo -n ""
        return 1
    fi

    if ! __git_is_in_worktree; then
        echo -n ""
        return 1
    fi

    local root_worktree active_worktree submodule_worktree
    submodule_worktree=$(git rev-parse --show-superproject-working-tree)
    if [[ "${submodule_worktree}" != "" ]]; then
        echo -n "${ICON_MAP[LEGO]}${submodule_worktree##*/}"
        return 0
    fi

    root_worktree=$(git worktree list | head -n1 | awk '{print $1;}')
    active_worktree=$(git worktree list | grep "$(git rev-parse --show-toplevel)" | head -n1 | awk '{print $1;}')

    echo -n "${ICON_MAP[LEGO]}${root_worktree##*/}:${active_worktree##*/}"
}

function __print_git_pwd() {
    _dotTrace_enter
    local working_pwd=""

    __is_in_git_repo --git-dir-ok
    local git_repo_result=$?
    if [[ $git_repo_result == 2 ]]; then
        _dotTrace "Not at all in a git repo"
        echo -ne ""
        _dotTrace_exit
        return 1
    fi

    __git_is_on_default_branch
    local is_branch_shorthand_eligible=$?

    local color_hint has_remote_changes has_unpushed_changes
    color_hint=$(__git_branch_color_hint)
    has_remote_changes=$(__git_has_remote_changes; echo $?)
    has_unpushed_changes=$(__git_has_unpushed_changes; echo $?)

    if [[ $has_remote_changes -eq 0 && $has_unpushed_changes -eq 0 ]]; then
        _dotTrace "both remote and unpushed changes detected"
        is_branch_shorthand_eligible=1
        working_pwd+="${ICON_MAP[ARROW_UPDOWN_THICK]}"
    elif [[ $has_remote_changes -eq 0 ]]; then
        _dotTrace "remote changes detected"
        is_branch_shorthand_eligible=1
        working_pwd+="${ICON_MAP[ARROW_DOWN_THICK]}"
    elif [[ $has_unpushed_changes -eq 0 ]]; then
        _dotTrace "unpushed changes detected"
        is_branch_shorthand_eligible=1
        working_pwd+="${ICON_MAP[ARROW_UP_THICK]}"
    fi

    working_pwd+="$(__print_git_branch_icon)"

    if [[ ${is_branch_shorthand_eligible} == 0 ]]; then
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
    if [[ $git_repo_result == 1 ]]; then
        anchored_path=".git${PWD##*.git}"
    else
        # If we're in a git repo then show the current directory relative to the root of that repo.
        # These commands wind up spitting out an extra slash, so backspace to remove it on the console.
        anchored_path="$(echo -ne "$(git rev-parse --show-toplevel | xargs basename)/$(git rev-parse --show-prefix)")"
        anchored_path="${anchored_path%/}"
        anchored_path="$(__print_abbreviated_path "${anchored_path}" 0)"
    fi

    echo -ne "${working_pwd}${anchored_path}"
    _dotTrace_exit
}

function __git_branch_color_hint() {
    if __git_is_nothing_to_commit; then
        echo -ne "green"
    elif __git_is_detached_head; then
        echo -ne "red"
    else
        echo -ne "yellow"
    fi
}

#! /bin/bash

#pragma once

function repo_find() {
    if __is_in_repo; then
        echo "${CWD_REPO_ROOT}"
        return 0
    fi

    if [[ -n "${ANDROID_REPO_ROOT}" ]]; then
        echo "${ANDROID_REPO_ROOT}"
        return 0
    fi

    local repo_root
    repo_root=$(find . -maxdepth 4 -type d -name '.repo' -print -quit | sed 's#/\.repo$##' | head -n1)
    if [[ -z "${repo_root}" ]]; then
        echo "error: Unable to find repo root tree."
        return 1;
    fi
    echo "${repo_root}"
}

alias repoGo='pushd "$(repo_find)"'
alias repo_root='repoGo'

function repo_manifest_branch() {
    if ! __is_in_repo; then
        return 1
    fi
    echo -n "${CWD_REPO_MANIFEST_BRANCH}"
}

function repo_default_remote() {
    if ! __is_in_repo; then
        return 1
    fi
    echo -n "${CWD_REPO_DEFAULT_REMOTE}"
}

function repo_current_project() {
    if ! __is_in_repo; then
        return 1
    fi

    local current_project
    if ! current_project="$(repo list . 2>/dev/null)"; then
        return 1
    fi

    echo -n "${current_project%% :*}"
}

function repo_current_project_branch() {
    local current_project
    current_project=$(repo branch . 2>/dev/null) || return $?
    if [[ -z "${current_project}" ]]; then
        return 1
    fi

    current_project="${current_project#\*p }"
    current_project="${current_project#\*P }"
    current_project="${current_project#\*}"
    current_project="${current_project%%|*}"
    current_project="${current_project//[[:space:]]/}"

    echo -n "${current_project}"
}

function repo_current_project_branch_status() {
    local current_project
    current_project=$(repo branch . 2>/dev/null) || return $?
    if [[ -z "${current_project}" ]]; then
        return 1
    fi
    if [[ "${current_project}" == \*p* ]]; then
        __echo_colored "yellow" "${ICON_MAP[ARROW_UP_THICK]}"
    fi
    if [[ "${current_project}" == \*P* ]]; then
        __echo_colored "green" "${ICON_MAP[ARROW_UP_THICK]}"
    fi
}

function repo_current_project_upstream() {
    local git_remote
    local manifest_revision

    git_remote=$(git remote show)
    manifest_revision=
    manifest_revision=$(repo info . | grep -i "Manifest revision" | sed 's/^Manifest revision: //')

    echo -n "${git_remote}/${manifest_revision}"
}

function repo_format() {
    git diff HEAD^ --name-only | xargs -t "${ANDROID_BUILD_TOP}"/external/ktfmt/ktfmt.py
    git diff HEAD^ --name-only | xargs -t google-java-format -i --aosp
}

function repo_clean() {
    if ! __is_in_repo; then
        echo "error: Not in Android repo tree"
        return 1
    fi

    repo list -p | while read -r repo_path; do
        pushd "${CWD_REPO_ROOT}/${repo_path}" > /dev/null || return 1
        upstream_branch="$(repo_current_project_upstream)"
        git checkout "${upstream_branch}" || return 1
        git reset --hard "${upstream_branch}" || return 1
        git clean -xfd || return 1
        popd > /dev/null || return 1
    done
}

function repo_pushd() {
    if ! __is_in_repo; then
        echo "error: Not in Android repo tree"
        return 1
    fi

    if [ $# -lt 1 ]; then
        echo "Missing sub-project"
        return 1
    fi

    local found_projects
    local found_projects_filtered

    found_projects=$(repo list -p | grep -i "$1")
    found_projects_filtered=$(echo "${found_projects}" | grep -vi "prebuilt")
    if [[ $(echo "$found_projects_filtered" | wc -l) -gt 1 ]]; then
        echo "Multiple projects found. Please provide a more specific name."
        # shellcheck disable=SC2001
        found_projects="$(echo "$found_projects" | sed "s;$1;\\\e[1m&\\\e[0m;g")"
        echo -e "${found_projects}"
        return 1
    fi
    found_projects=$found_projects_filtered
    if [[ -n "${found_projects}" ]]; then
        pushd "${CWD_REPO_ROOT}/${found_projects}" || return 1
        return 0
    fi

    echo "Unknown project"
    return 1
}

function repo_sync_yesterday() {
    local maybe_days_ago=$1
    local date_str='yesterday'

    if ! __is_in_repo; then
        echo "error: Not in Android repo tree"

        return 1
    fi

    if [[ -n "${maybe_days_ago}" ]]; then
        if (( maybe_days_ago < 0 )); then
            maybe_days_ago=$(( -maybe_days_ago ))
        fi
        date_str="${maybe_days_ago} days ago"
    fi

    local date_arg
    date_arg="$(date -d "${date_str}" +'%Y-%m-%d %H:%M:%S')" || return 1

    echo "Syncing from ${date_str} (${date_arg})"

    repo_sync_at "${date_arg}"
}

function repo_sync_at() {
    local last_commit_sha
    local upstream_branch

    if ! __is_in_repo; then
        echo "error: Not in Android repo tree"
        return 1
    fi

    repo list -p | while read -r repo_path; do
        pushd "${CWD_REPO_ROOT}/${repo_path}" > /dev/null || return 1
        upstream_branch=$(repo_current_project_upstream)
        last_commit_sha=$(git rev-list -n 1 --before="$1" "${upstream_branch}")
        git checkout "${last_commit_sha}"
        popd > /dev/null || return 1
    done
}

function refresh_build_env() {
    if ! __is_in_repo; then
        echo "error: Not in Android repo tree"
        return 1
    fi

    pushd "${CWD_REPO_ROOT}" || return 1

    # shellcheck source=/dev/null
    source ./build/envsetup.sh

    if command -v pontis > /dev/null && pontis status 2> /dev/null; then
        pontis set-adb -binary="${PWD}/out/host/linux-x86/bin/adb" 1> /dev/null
    fi

    popd || return 1

    return 0
}

if [ -n "${ANDROID_HOME}" ]; then
    # https://developer.android.com/tools/variables#envar
    export ANDROID_SDK="${ANDROID_HOME}"
    export ANDROID_SDK_ROOT="${ANDROID_HOME}"

    PATH="${PATH}:${ANDROID_HOME}/cmdline-tools/latest/bin"
    PATH="${PATH}:${ANDROID_HOME}/tools"
    PATH="${PATH}:${ANDROID_HOME}/tools/bin"
    PATH="${PATH}:${ANDROID_HOME}/platform-tools"
fi

# shortcuts for common commands - These should be replicated into the asimo extension.

function asimo_flash() {
    if ! __is_in_repo; then
        echo "error: Not in Android repo tree"
        return 1
    fi

    pushd "${CWD_REPO_ROOT}" || return 1
    ./vendor/google/tools/flashall
    popd || return 1
}

function asimo_build() {
    if ! __is_in_repo; then
        echo "error: Not in Android repo tree"
        return 1
    fi

    pushd "${CWD_REPO_ROOT}" || return 1
    m -j8
    popd || return 1
}

function asimo_sync() {
    if ! __is_in_repo; then
        echo "error: Not in Android repo tree"
        return 1
    fi

    pushd "${CWD_REPO_ROOT}" || return 1
    repo sync -j8
    popd || return 1
}


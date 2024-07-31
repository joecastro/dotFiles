#! /bin/bash

#pragma once

function repo_find() {
    if __is_in_repo; then
        repo --show-toplevel
    elif [[ -n ${ANDROID_REPO_ROOT} ]]; then
        echo "${ANDROID_REPO_ROOT}"
    else
        find . -type d -name '.repo' -print -quit | sed 's#/\.repo$##'
    fi
}

alias repoGo='pushd "$(repo_find)"'
alias repo_root='repoGo'

function repo_print_manifest_branch() {
    if ! __is_in_repo; then
        return 1
    fi

    local manifest_branch
    if (( ${+ANDROID_REPO_ROOT} )) && [[ "${PWD}" == "${ANDROID_REPO_ROOT}" || "${PWD}" == "${ANDROID_REPO_ROOT}"/* ]]; then
        manifest_branch=$ANDROID_REPO_BRANCH
    else
        manifest_branch=$(repo info --outer-manifest -l -q "platform/no-project" 2>/dev/null | grep -i "Manifest branch" | sed 's/^Manifest branch: //')
    fi

    echo -n "${manifest_branch}"
}

function repo_print_current_project() {
    if ! __is_in_repo; then
        return 1
    fi

    local current_project
    if ! current_project="$(repo list . 2>/dev/null)"; then
        return 1
    fi

    __print_abbreviated_path "${current_project%% :*}"
}

function repo_upstream_branch() {
    local upstream_branch
    upstream_branch=$(repo info -o --outer-manifest -l | grep -i "Manifest branch" | sed 's/^Manifest branch: //')
    echo "goog/${upstream_branch}"
}

function repo_current_project_branch() {
    local current_project
    current_project=$(repo branch .) || return $?
    echo "${current_project%%|*}" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
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

    local upstream_branch
    upstream_branch="${repo_upstream_branch}"
    repo forall -vc "git checkout ${upstream_branch} && git reset --hard ${upstream_branch} &&  git clean -xfd"
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

    repo list -p | while read -r line; do
        if [[ "${line##*/}" == "$1" ]]; then
            pushd "$(repo_find)"/"${line}" || return 1
            return 0
        fi
    done

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
    local repo_upstream_branch
    local repo_root_dir

    if ! __is_in_repo; then
        echo "error: Not in Android repo tree"
        return 1
    fi

    repo_root_dir="$(repo_find)"
    repo_upstream_branch="$(repo_upstream_branch)"
    repo list -p | while read -r repo_path; do
        pushd "${repo_root_dir}/${repo_path}" > /dev/null || return 1
        last_commit_sha=$(git rev-list -n 1 --before="$1" "${repo_upstream_branch}")
        git checkout "${last_commit_sha}"
        popd > /dev/null || return 1
    done
}

function refresh_build_env() {
    if ! __is_in_repo; then
        echo "error: Not in Android repo tree"
        return 1
    fi

    repo_root
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
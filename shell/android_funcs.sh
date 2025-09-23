#! /bin/bash

#pragma once

#pragma requires debug.sh
#pragma requires colors.sh

function repo_find() {
    _dotTrace_enter "$@"
    if __is_in_repo; then
        echo "${CWD_REPO_ROOT}"
        _dotTrace_exit 0
        return
    fi

    if [[ -n "${ANDROID_REPO_ROOT}" ]]; then
        echo "${ANDROID_REPO_ROOT}"
        _dotTrace_exit 0
        return
    fi

    local repo_root
    repo_root=$(find . -maxdepth 4 -type d -name '.repo' -print -quit | sed 's#/\.repo$##' | head -n1)
    if [[ -z "${repo_root}" ]]; then
        echo "error: Unable to find repo root tree."
        _dotTrace_exit 1
        return
    fi
    echo "${repo_root}"
    _dotTrace_exit 0
}

alias repoGo='pushd "$(repo_find)"'
alias repo_root='repoGo'

function repo_manifest_branch() {
    _dotTrace_enter "$@"
    if ! __is_in_repo; then
        _dotTrace_exit 1
        return
    fi
    printf '%s' "${CWD_REPO_MANIFEST_BRANCH}"
    _dotTrace_exit 0
}

function repo_default_remote() {
    _dotTrace_enter "$@"
    if ! __is_in_repo; then
        _dotTrace_exit 1
        return
    fi
    printf '%s' "${CWD_REPO_DEFAULT_REMOTE}"
    _dotTrace_exit 0
}

function repo_current_project() {
    _dotTrace_enter "$@"
    if ! __is_in_repo; then
        _dotTrace_exit 1
        return
    fi

    local current_project
    if ! current_project="$(repo list . 2>/dev/null)"; then
        _dotTrace_exit 1
        return
    fi

    printf '%s' "${current_project%% :*}"
    _dotTrace_exit 0
}

function repo_current_project_branch() {
    _dotTrace_enter "$@"
    local current_project
    current_project=$(repo branch . 2>/dev/null) || { _dotTrace_exit "$?"; return "$?"; }
    if [[ -z "${current_project}" ]]; then
        _dotTrace_exit 1
        return
    fi

    current_project="${current_project#\*p }"
    current_project="${current_project#\*P }"
    current_project="${current_project#\*}"
    current_project="${current_project%%|*}"
    current_project="${current_project//[[:space:]]/}"

    printf '%s' "${current_project}"
    _dotTrace_exit 0
}

function repo_current_project_branch_status() {
    _dotTrace_enter "$@"
    local current_project
    current_project=$(repo branch . 2>/dev/null) || { _dotTrace_exit "$?"; return "$?"; }
    if [[ -z "${current_project}" ]]; then
        _dotTrace_exit 1
        return
    fi
    if [[ "${current_project}" == \*p* ]]; then
        colorize "${ICON_MAP[ARROW_UP_THICK]}" yellow
    fi
    if [[ "${current_project}" == \*P* ]]; then
        colorize "${ICON_MAP[ARROW_UP_THICK]}" green
    fi
    _dotTrace_exit 0
}

function repo_current_project_upstream() {
    _dotTrace_enter "$@"
    local git_remote
    local manifest_revision

    git_remote=$(git remote show)
    manifest_revision=
    manifest_revision=$(repo info . | grep -i "Manifest revision" | sed 's/^Manifest revision: //')

    printf '%s' "${git_remote}/${manifest_revision}"
    _dotTrace_exit 0
}

function repo_format() {
    git diff HEAD^ --name-only | xargs -t "${ANDROID_BUILD_TOP}"/external/ktfmt/ktfmt.py
    git diff HEAD^ --name-only | xargs -t google-java-format -i --aosp
}

function repo_clean() {
    _dotTrace_enter "$@"
    if ! __is_in_repo; then
        echo "error: Not in Android repo tree"
        _dotTrace_exit 1
        return
    fi

    repo list -p | while read -r repo_path; do
        pushd "${CWD_REPO_ROOT}/${repo_path}" > /dev/null || { _dotTrace "pushd failed for ${repo_path}"; _dotTrace_exit 1; return 1; }
        upstream_branch="$(repo_current_project_upstream)"
        git checkout "${upstream_branch}" || { _dotTrace_exit 1; return 1; }
        git reset --hard "${upstream_branch}" || { _dotTrace_exit 1; return 1; }
        git clean -xfd || { _dotTrace_exit 1; return 1; }
        popd > /dev/null || { _dotTrace_exit 1; return 1; }
    done
    _dotTrace_exit 0
}

function repo_pushd() {
    _dotTrace_enter "$@"
    if ! __is_in_repo; then
        echo "error: Not in Android repo tree"
        _dotTrace_exit 1
        return
    fi

    if [ $# -lt 1 ]; then
        echo "Missing sub-project"
        _dotTrace_exit 1
        return
    fi

    local found_projects
    local found_projects_filtered

    found_projects=$(repo list -p | grep -i "$1")
    found_projects_filtered=$(echo "${found_projects}" | grep -vi "prebuilt")
    if (( $(echo "$found_projects_filtered" | wc -l) > 1 )); then
        echo "Multiple projects found. Please provide a more specific name."
        # shellcheck disable=SC2001
        found_projects="$(echo "$found_projects" | sed "s;$1;\\\e[1m&\\\e[0m;g")"
        printf '%b\n' "${found_projects}"
        _dotTrace_exit 1
        return
    fi
    found_projects=$found_projects_filtered
    if [[ -n "${found_projects}" ]]; then
        pushd "${CWD_REPO_ROOT}/${found_projects}" || { _dotTrace_exit 1; return 1; }
        _dotTrace_exit 0
        return
    fi

    echo "Unknown project"
    _dotTrace_exit 1
    return
}

function repo_sync_yesterday() {
    _dotTrace_enter "$@"
    local maybe_days_ago=$1
    local date_str='yesterday'

    if ! __is_in_repo; then
        echo "error: Not in Android repo tree"

        _dotTrace_exit 1
        return
    fi

    if [[ -n "${maybe_days_ago}" ]]; then
        if (( maybe_days_ago < 0 )); then
            maybe_days_ago=$(( -maybe_days_ago ))
        fi
        date_str="${maybe_days_ago} days ago"
    fi

    local date_arg
    date_arg="$(date -d "${date_str}" +'%Y-%m-%d %H:%M:%S')" || { _dotTrace_exit 1; return 1; }

    echo "Syncing from ${date_str} (${date_arg})"

    repo_sync_at "${date_arg}"
    _dotTrace_exit "$?"
}

function repo_sync_at() {
    _dotTrace_enter "$@"
    local last_commit_sha
    local upstream_branch

    if ! __is_in_repo; then
        echo "error: Not in Android repo tree"
        _dotTrace_exit 1
        return
    fi

    repo list -p | while read -r repo_path; do
        pushd "${CWD_REPO_ROOT}/${repo_path}" > /dev/null || return 1
        upstream_branch=$(repo_current_project_upstream)
        last_commit_sha=$(git rev-list -n 1 --before="$1" "${upstream_branch}")
        git checkout "${last_commit_sha}"
        popd > /dev/null || return 1
    done
    _dotTrace_exit 0
}

function refresh_build_env() {
    _dotTrace_enter "$@"
    if ! __is_in_repo; then
        echo "error: Not in Android repo tree"
        _dotTrace_exit 1
        return
    fi

    pushd "${CWD_REPO_ROOT}" || { _dotTrace_exit 1; return 1; }

    # shellcheck source=/dev/null
    source ./build/envsetup.sh

    if command -v pontis > /dev/null && pontis status 2> /dev/null; then
        pontis set-adb -binary="${PWD}/out/host/linux-x86/bin/adb" 1> /dev/null
    fi

    popd || { _dotTrace_exit 1; return 1; }

    _dotTrace_exit 0
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
    _dotTrace_enter "$@"
    if ! __is_in_repo; then
        echo "error: Not in Android repo tree"
        _dotTrace_exit 1
        return
    fi

    pushd "${CWD_REPO_ROOT}" || { _dotTrace_exit 1; return 1; }
    ./vendor/google/tools/flashall
    local rc=$?
    popd || { _dotTrace_exit 1; return 1; }
    _dotTrace_exit "$rc"
}

function asimo_build() {
    _dotTrace_enter "$@"
    if ! __is_in_repo; then
        echo "error: Not in Android repo tree"
        _dotTrace_exit 1
        return
    fi

    pushd "${CWD_REPO_ROOT}" || { _dotTrace_exit 1; return 1; }
    m -j8
    local rc=$?
    popd || { _dotTrace_exit 1; return 1; }
    _dotTrace_exit "$rc"
}

function asimo_sync() {
    _dotTrace_enter "$@"
    if ! __is_in_repo; then
        echo "error: Not in Android repo tree"
        _dotTrace_exit 1
        return
    fi

    pushd "${CWD_REPO_ROOT}" || { _dotTrace_exit 1; return 1; }
    repo sync -j8
    local rc=$?
    popd || { _dotTrace_exit 1; return 1; }
    _dotTrace_exit "$rc"
}

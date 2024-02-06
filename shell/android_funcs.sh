#! /bin/bash

#pragma once

function repo_find() {
    if __is_in_repo; then
        repo --show-toplevel
    elif (( ${+ANDROID_REPO_ROOT} )); then
        echo "${ANDROID_REPO_ROOT}"
    else
        find . -type d -name '.repo' -print -quit | sed 's#/\.repo$##'
    fi
}

alias repoGo='pushd "$(repo_find)"; cd .'
alias repo_root='repoGo'

function repo_format() {
    git diff HEAD^ --name-only | xargs -t "${ANDROID_BUILD_TOP}"/external/ktfmt/ktfmt.py
    git diff HEAD^ --name-only | xargs -t google-java-format -i --aosp
}

function repo_clean() {
    if ! __is_in_repo -v; then
        return 1
    fi

    REPO_UPSTREAM_BRANCH=goog/$(repo info -o --outer-manifest -l | grep -i "Manifest branch" | sed 's/^Manifest branch: //')
    repo forall -vc "git checkout $REPO_UPSTREAM_BRANCH && git reset --hard $REPO_UPSTREAM_BRANCH &&  git clean -xfd"
}

if [[ "$ACTIVE_SHELL" == *"zsh" ]]; then
    function repo_pushd() {
        if ! __is_in_repo -v; then
            return 1
        fi

        if [ $# -lt 1 ]; then
            #shellcheck disable=SC2154
            echo "${funcstack[1]} Missing sub-project"
            return 1
        fi

        IFS=$'\n' read -r -d '' -A MOUNT_PATHS < <( repo info --outer-manifest -l | grep "Mount path.*$1$" | sed 's/^Mount path: //' )
        for MOUNT_PATH in "${MOUNT_PATHS[@]}"; do
            if [[ "${MOUNT_PATH##*/}" == "$1" ]]; then
                pushd "${MOUNT_PATH}" || return 1
                break
            fi
        done

        if [[ "$MOUNT_PATH" == "$PWD" ]]; then
            return 0
        fi

        echo "Unknown project"
        return 1
    }
else
    function repo_pushd() {
        if ! __is_in_repo -v; then
            return 1
        fi

        if [ $# -lt 1 ]; then
            echo "Missing sub-project"
            return 1
        fi

        IFS=$'\n' read -r -d '' -a MOUNT_PATHS < <( repo info --outer-manifest -l | grep "Mount path.*$1$" | sed 's/^Mount path: //' )
        for MOUNT_PATH in "${MOUNT_PATHS[@]}"; do
            if [[ "${MOUNT_PATH##*/}" == "$1" ]]; then
                pushd "${MOUNT_PATH}" || return 1
                break
            fi
        done

        if [[ "$MOUNT_PATH" == "$PWD" ]]; then
            return 0
        fi

        echo "Unknown project"
        return 1
    }
fi

function refresh_build_env() {
    if ! __is_in_repo -v; then
        return 1
    fi

    repo_root
    # shellcheck source=/dev/null
    source ./build/envsetup.sh

    if command -v pontis > /dev/null && pontis status 2> /dev/null; then
        pontis set-adb -binary="$PWD/out/host/linux-x86/bin/adb" 1> /dev/null
    fi

    popd || return 1

    return 0
}

alias whats_for_lunch='echo "$TARGET_PRODUCT-$TARGET_BUILD_VARIANT"'
alias lunch_pixel7='lunch aosp_panther-trunk_staging-userdebug'
alias lunch_pixel7pro='lunch aosp_cheetah-trunk_staging-userdebug'
alias lunch_pixelfold='lunch aosp-felix-userdebug'
alias lunch_cuttlefish='lunch aosp_cf_x86_64_phone-eng'

if (( ${+ANDROID_HOME} )); then
    # https://developer.android.com/tools/variables#envar
    export ANDROID_SDK=${ANDROID_HOME}
    export ANDROID_SDK_ROOT=${ANDROID_HOME}

    PATH="${PATH}:${ANDROID_HOME}/cmdline-tools/latest/bin"
    PATH="${PATH}:${ANDROID_HOME}/tools"
    PATH="${PATH}:${ANDROID_HOME}/tools/bin"
    PATH="${PATH}:${ANDROID_HOME}/platform-tools"
fi
#! /bin/bash

function repo_find() {
    if __is_in_repo; then
        echo $(repo --show-toplevel)
    elif (( ${+ANDROID_REPO_ROOT} )); then
        echo ${ANDROID_REPO_ROOT}
    else
        echo "$(find . -type d -name '.repo' -print -quit | sed 's#/\.repo$##')"
    fi
}

function repo_root() {
    pushd $(repo_find)
}

function repo_format() {
    git diff HEAD^ --name-only | xargs -t ${ANDROID_BUILD_TOP}/external/ktfmt/ktfmt.py
    git diff HEAD^ --name-only | xargs -t google-java-format -i --aosp
}

function repo_clean() {
    if ! __is_in_repo -v; then
        return 1
    fi

    REPO_UPSTREAM_BRANCH=goog/$(repo info -o --outer-manifest -l | grep -i "Manifest branch" | sed 's/^Manifest branch: //')
    repo forall -vc "git checkout $REPO_UPSTREAM_BRANCH && git reset --hard $REPO_UPSTREAM_BRANCH &&  git clean -xfd"
}

function repo_pushd() {
    if ! __is_in_repo -v; then
        return 1
    fi

    if [ $# -lt 1 ]; then
        echo "$funcstack[1] Missing sub-project"
        return 1
    fi

    MOUNT_PATHS=($(repo info --outer-manifest -l | grep "Mount path.*$1$" | sed 's/^Mount path: //'))
    for MOUNT_PATH in "${MOUNT_PATHS[@]}"; do
        if [[ "${MOUNT_PATH##*/}" == "$1" ]]; then
            pushd $MOUNT_PATH
            break
        fi
    done

    if [[ "$MOUNT_PATH" == "$PWD" ]]; then
        return 0
    fi

    echo "Unknown project"
    return 1
}

function refresh_build_env() {
    if ! __is_in_repo -v; then
        return 1
    fi

    repo_root
    source ./build/envsetup.sh

    if command -v pontis > /dev/null && pontis status 2> /dev/null; then
        pontis set-adb -binary="$PWD/out/host/linux-x86/bin/adb" 1> /dev/null
    fi

    popd

    return 0
}

alias whats_for_lunch='echo "$TARGET_PRODUCT-$TARGET_BUILD_VARIANT"'
alias lunch_pixel7='lunch aosp_panther-trunk_staging-userdebug'
alias lunch_pixel7pro='lunch aosp_cheetah-trunk_staging-userdebug'
alias lunch_pixelfold='lunch aosp-felix-userdebug'
alias lunch_cuttlefish='lunch aosp_cf_x86_64_phone-eng'

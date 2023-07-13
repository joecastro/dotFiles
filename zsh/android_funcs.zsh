#! /bin/zsh

#! /bin/zsh

function repo_find() {
    if __is_in_repo; then
        echo $(repo --show-toplevel)
    else
        echo "$(find . -type d -name '.repo' | sed 's#/\.repo$##')"
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
    popd

    return 0
}


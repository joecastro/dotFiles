#! /bin/zsh

function refresh_build_env() {
    if ! __is_in_repo -v; then
        return 1
    fi

    repo_root
    source ./build/envsetup.sh
    popd

    return 0
}

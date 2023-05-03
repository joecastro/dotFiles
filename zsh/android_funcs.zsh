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

function interactive_invoke_gcert() {
    if ! command -v gcertstatus &> /dev/null; then
        return 0
    fi

    # gcertstatus 2>&1 | grep "WARNING" > /dev/null
    gcertstatus --check_loas2 --nocheck_ssh --check_remaining=2h --quiet
    if [[ "$?" != "0" ]]; then
        echo ">> gcert has expired. Invoking gcert flow."
        gcert
    fi
}

#!/bin/bash

function bootstrap_env() {
    local WORK_DIR=0
    WORK_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

    # These should always be safe to clean.
    echo ">> Cleaning up environment"
    rm "$WORK_DIR/.DS_Store" 2> /dev/null
    rm -rf "$WORK_DIR/out" 2> /dev/null
    rm -rf "$WORK_DIR/.venv" 2> /dev/null

    if [[ "$1" == "--clean" ]]; then
        exit 0
    fi

    pushd "$WORK_DIR" || exit 1
    echo ">> Initializing Python virtual environment"

    python3 -m venv "$WORK_DIR"/.venv
    # shellcheck source=/dev/null
    source "$WORK_DIR"/.venv/bin/activate

    pip3 install -q --upgrade pip
    pip3 install -q -r "$WORK_DIR"/requirements.txt

    deactivate

    popd || exit 1

    echo ">> Launching workspace"
    code "$WORK_DIR"/dotFiles.code-workspace

    return 0
}

bootstrap_env "$@"

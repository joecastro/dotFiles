#!/bin/bash

function bootstrap_env() {
    local WORK_DIR=0
    WORK_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

    # These should always be safe to clean.
    printf '>> Cleaning up environment\n'
    rm "$WORK_DIR/.DS_Store" 2> /dev/null
    rm -rf "$WORK_DIR/out" 2> /dev/null
    rm -rf "$WORK_DIR/.venv" 2> /dev/null
    # xargs will strip the whitespace that's printed to stdout

    if [[ -d "${WORK_DIR}/.vscode" ]]; then
        DOTCODE_FOLDER_NON_LINK_FILE_COUNT=$(find "${WORK_DIR}/.vscode" -not -type l -not -type d | wc -l | xargs)
        if [[ "${DOTCODE_FOLDER_NON_LINK_FILE_COUNT}" != "0" ]]; then
            printf '%s\n' "It seems like there are files that are directly added to the virtual folder. Not proceeding."
            find "${WORK_DIR}" -not -type l -not -type d
            return 1
        fi
        rm -rf "${WORK_DIR}/.vscode" 2> /dev/null
    fi

    if [[ "$1" == "--clean" ]]; then
        exit 0
    fi

    pushd "$WORK_DIR" || exit 1
    printf '>> Initializing Python virtual environment\n'

    mkdir "${WORK_DIR}"/.vscode
    ln -s "${WORK_DIR}"/vscode/dotFiles_launch.json "${WORK_DIR}"/.vscode/launch.json
    ln -s "${WORK_DIR}"/vscode/dotFiles_settings.json "${WORK_DIR}"/.vscode/settings.json
    ln -s "${WORK_DIR}"/vscode/dotFiles_extensions.json "${WORK_DIR}"/.vscode/extensions.json

    python3 -m venv "$WORK_DIR"/.venv
    # shellcheck source=/dev/null
    source "$WORK_DIR"/.venv/bin/activate

    pip3 install -q --upgrade pip
    pip3 install -q -r "$WORK_DIR"/requirements.txt

    deactivate

    popd || exit 1

    printf '>> Launching workspace\n'
    code "$WORK_DIR"

    return 0
}

bootstrap_env "$@"

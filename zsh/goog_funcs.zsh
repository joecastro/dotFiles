#! /bin/zsh

# This isn't on every workstation
test -e "/etc/bash_completion.d/g4d" && source "/etc/bash_completion.d/g4d"

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

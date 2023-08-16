#!/bin/zsh

#pragma once
PRAGMA_FILE_NAME="PRAGMA_${"${(%):-%1N}"//\./_}"
[ -n "${(P)PRAGMA_FILE_NAME}" ] && unset PRAGMA_FILE_NAME && return;
declare $PRAGMA_FILE_NAME=0
unset PRAGMA_FILE_NAME

function battery_charge {
    echo -n $(python3 ./zsh/batcharge.py)
}

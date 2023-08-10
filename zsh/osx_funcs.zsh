#!/bin/zsh

function battery_charge {
    echo -n $(python3 ./zsh/batcharge.py)
}

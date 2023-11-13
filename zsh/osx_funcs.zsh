#!/bin/zsh

#pragma once

function battery_charge {
    echo -n $(python3 ./zsh/batcharge.py)
}

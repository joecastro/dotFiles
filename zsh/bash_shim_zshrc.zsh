#! /bin/zsh

# pragma-once

# This could be limited to interactive shells if desired.
# `if echo $- | grep -q 'i'; then`
# Or, this could be limited to verifying extra qualities about the bash executable like a minimum version.

SHELL=/bin/bash exec /bin/bash $@
#!/bin/bash

sudo apt-get update

# /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
# eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

sudo apt install -y \
    build-essential \
    gcc \
    make \
    vim \
    exa \
    python3 \
    python3.11-venv \
    python-is-python3 \
    python3-dev \
    python3.11-venv \
    gpg \
    jsonnet

sudo apt-get install -y \
    repo

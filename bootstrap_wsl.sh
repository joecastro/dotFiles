#!/bin/zsh

sudo apt-get update

# /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
# eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

sudo apt install -y \
    build-essential \
    vim \
    exa \
    python3 \
    python-is-python3 \
    gpg \
    jsonnet

# brew install gcc

sudo apt-get install -y \
    repo

if (( ${+ANDROID_REPO_BRANCH} )); then
    mkdir -p $ANDROID_REPO_ROOT
    cd $ANDROID_REPO_ROOT
    repo init -u https://android.googlesource.com/platform/manifest
    repo init -u https://android.googlesource.com/platform/manifest -b $ANDROID_REPO_BRANCH
fi

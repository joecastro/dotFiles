#!/bin/zsh

sudo apt-get update

sudo apt install -y \
    vim \
    exa \
    python3 \
    python-is-python3 \
    gpg

sudo apt-get install repo

if (( ${+ANDROID_ROOT_BRANCH} )); then
    mkdir -p $ANDROID_ROOT_PATH
    cd $ANDROID_ROOT_PATH
    repo init -u https://android.googlesource.com/platform/manifest
    repo init -u https://android.googlesource.com/platform/manifest -b $ANDROID_ROOT_BRANCH
fi

#!/bin/bash

which hostnamectl && hostnamectl

if [[ "amd64" != "$(dpkg --print-architecture)" ]]; then
	echo "This script doesn't currently handle ARM"
	exit 1
fi

# Only do this if we're on bullseye...
# cat /etc/apt/sources.list.d/cros.list
deb https://storage.googleapis.com/cros-packages/115 bookworm main
deb https://deb.debian.org/debian bookworm-backports main

# cat /etc/apt/sources.list
deb https://deb.debian.org/debian bookworm main
deb https://deb.debian.org/debian bookworm-updates main
deb https://deb.debian.org/debian-security/ bookworm-security main

sudo apt update
sudo apt dist-upgrade

sudo apt install -y \
    zsh \
    wget \
    git \
    jsonnet \
    python3-dev \
    python3.11-venv

wget https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-x64
dpkg -i *.deb



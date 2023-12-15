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
    exa \
    apt-utils \
    vim-gtk3 \
    jsonnet \
    python3-dev \
    python3.11-venv

mkdir -p ~/.fonts
pushd ~/.fonts || return 1
wget https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/JetBrainsMono/Ligatures/Regular/JetBrainsMonoNerdFontMono-Regular.ttf
wget https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/JetBrainsMono/Ligatures/Bold/JetBrainsMonoNerdFont-Bold.ttf
wget https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/JetBrainsMono/Ligatures/BoldItalic/JetBrainsMonoNerdFont-BoldItalic.ttf
wget https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/CascadiaCode/Regular/CaskaydiaCoveNerdFontMono-Regular.ttf
wget https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/CascadiaCode/Regular/CaskaydiaCoveNerdFontMono-Italic.ttf
wget https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/CascadiaCode/Bold/CaskaydiaCoveNerdFontMono-Bold.ttf
wget https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/CascadiaCode/Bold/CaskaydiaCoveNerdFontPropo-BoldItalic.ttf

popd || return 1

wget https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-x64
dpkg -i *.deb

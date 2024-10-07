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
    eza \
    apt-utils \
    vim-gtk3 \
    jsonnet \
    python3-dev \
    python3.11-venv

function install_fonts() {
    mkdir -p "$HOME/Downloads"
    mkdir -p "$HOME/.local/share/fonts"

    local font_families=("JetBrainsMono" "CascadiaCode" "Hack" "Inconsolata" "FiraCode" "UbuntuSans")
    local nf_version
    nf_version=$(wget -q -O - "https://api.github.com/repos/ryanoasis/nerd-fonts/releases/latest" | grep "\"name\"" | head -n 1 | cut -d '"' -f 4)

    for font_family in "${font_families[@]}"; do
        local font_url="https://github.com/ryanoasis/nerd-fonts/releases/download/${nf_version}/${font_family}.zip"
        wget -O "$HOME/Downloads/${font_family}.zip" "${font_url}"
        unzip -f -o -d "$HOME/.local/share/fonts" "$HOME/Downloads/${font_family}.zip" "*.ttf"
        rm "$HOME/Downloads/${font_family}.zip"
    done

    fc-cache -f -v
}

install_fonts

wget "https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-x64"
dpkg -i ./*.deb

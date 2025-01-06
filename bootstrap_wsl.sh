#!/bin/bash

sudo apt update

# /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
# eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

sudo apt install -y \
    build-essential \
    wget \
    curl \
    rsync \
    gcc \
    make \
    vim \
    python3 \
    python3.11-venv \
    python-is-python3 \
    python3-dev \
    python3.11-venv \
    gpg

mkdir -p ~/source

git clone https://github.com/google/jsonnet.git ~/source/jsonnet
pushd ~/source/jsonnet

make
sudo ln -s $PWD/jsonnet /usr/bin/jsonnet

popd

sudo apt install -y \
    repo

sudo mkdir -p /etc/apt/keyrings
wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list
sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list

sudo apt update

sudo apt install -y \
    eza

sudo apt install -y \
    zsh

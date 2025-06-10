#! /bin/bash

sudo add-apt-repository ppa:kubuntu-ppa/beta && sudo apt full-upgrade -y

sudo apt install -y \
    eza \
    jsonnet \
    wget \
    curl \
    python-is-python3 \
    zsh \
    libgtk-4-dev \
    libadwaita-1-dev \
    git \
    blueprint-compiler \
    gettext \
    libxml2-utils


sudo snap install zig --classic --beta
sudo snap install code --classic

git clone https://github.com/ghostty-org/ghostty

function update_fonts() {
    mkdir -p ~/.local/share/fonts
    pushd ~/.local/share/fonts || return 1
    wget https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/JetBrainsMono/Ligatures/Regular/JetBrainsMonoNerdFontMono-Regular.ttf
    wget https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/JetBrainsMono/Ligatures/Bold/JetBrainsMonoNerdFont-Bold.ttf
    wget https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/JetBrainsMono/Ligatures/BoldItalic/JetBrainsMonoNerdFont-BoldItalic.ttf
    wget https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/CascadiaCode/Regular/CaskaydiaCoveNerdFontMono-Regular.ttf
    wget https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/CascadiaCode/Regular/CaskaydiaCoveNerdFontMono-Italic.ttf
    wget https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/CascadiaCode/Bold/CaskaydiaCoveNerdFontMono-Bold.ttf
    wget https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/CascadiaCode/Bold/CaskaydiaCoveNerdFontPropo-BoldItalic.ttf
    fc-cache -f -v

    popd || return 1
}
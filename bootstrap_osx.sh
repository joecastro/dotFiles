#!/bin/sh

echo ">> Being explicit about using zsh..."
chsh -s /bin/zsh

# https://brew.sh
if command -v brew > /dev/null; then
    echo " >> Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

brew update

# Consider whether to add Bartender.
brew install --cask \
    iterm2 \
    visual-studio-code \
    intellij-idea-ce \
    android-studio \
    sublime-merge \
    lastpass \
    istat-menus \
    spotify \
    grandperspective \
    google-chrome \
    docker \
    microsoft-office

# brew install --cask microsoft-edge
# brew install --cask adobe-creative-cloud
# brew install --cask dotnet-sdk

brew install \
    zsh \
    wget \
    exa \
    lastpass-cli \
    java \
    macvim \
    git \
    go \
    node \
    gradle \
    flock \
    python@3

brew install \
    docker \
    docker-machine \
    docker-compose

#brew install --cask unity-hub
brew tap homebrew/cask-fonts
brew install font-inconsolata
brew install font-cascadia-code
brew install font-caskaydia-cove-nerd-font

brew tap gdubw/gng
brew install gng

cd ~ || exit


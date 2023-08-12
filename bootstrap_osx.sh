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
brew install --cask iterm2
brew install --cask visual-studio-code
brew install --cask intellij-idea-ce
brew install --cask android-studio
brew install --cask sublime-merge
brew install --cask lastpass
brew install --cask istat-menus
brew install --cask spotify
brew install --cask grandperspective
brew install --cask microsoft-edge
brew install --cask google-chrome
brew install --cask docker
brew install --cask microsoft-office

# brew install --cask slack

# brew install --cask adobe-creative-cloud
# brew install --cask dotnet-sdk

brew install lastpass-cli

brew install zsh
brew install wget
brew install exa

Brew install java
brew install macvim git go node gdub python@3
brew install docker docker-machine docker-compose

#brew install --cask unity-hub
brew tap homebrew/cask-fonts
brew install font-inconsolata
brew install font-cascadia-code
brew install font-caskaydia-cove-nerd-font

cd ~ || exit


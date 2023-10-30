#!/bin/bash

function install_android_sdk() {
    if [[ -z "$ANDROID_SDK" ]]; then
        echo "ANDROID_SDK environment variable not set. This file can be sourced and then the function 'install_android_sdk' can be called"
        return 1
    fi

    mkdir -p "$ANDROID_SDK"/cmdline-tools/latest || return 1

    # Download Android SDK
    # https://developer.android.com/studio#command-tools
    local COMMANDLINETOOLSZIP_FILENAME="commandlinetools-linux-10406996_latest.zip"
    local COMMANDLINETOOLSZIP_URL="https://dl.google.com/android/repository/""$COMMANDLINETOOLSZIP_FILENAME"

    wget $COMMANDLINETOOLSZIP_URL

    unzip ./"$COMMANDLINETOOLSZIP_FILENAME" -d "$ANDROID_SDK"

    mv "$ANDROID_SDK"/cmdline-tools/NOTICE.txt "$ANDROID_SDK"/cmdline-tools/latest/
    mv "$ANDROID_SDK"/cmdline-tools/source.properties "$ANDROID_SDK"/cmdline-tools/latest/
    mv "$ANDROID_SDK"/cmdline-tools/lib "$ANDROID_SDK"/cmdline-tools/latest/
    mv "$ANDROID_SDK"/cmdline-tools/bin "$ANDROID_SDK"/cmdline-tools/latest/

    yes | "$ANDROID_SDK"/cmdline-tools/latest/bin/sdkmanager --licenses
    "$ANDROID_SDK"/cmdline-tools/latest/bin/sdkmanager "platform-tools" "platforms;android-34"

    rm ./"$COMMANDLINETOOLSZIP_FILENAME"
}

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

install_android_sdk
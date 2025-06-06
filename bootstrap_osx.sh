#!/bin/bash

function install_android_sdk() {
    if [[ -z "$ANDROID_HOME" ]]; then
        echo "ANDROID_HOME environment variable not set. This file can be sourced and then the function 'install_ANDROID_HOME' can be called"
        return 1
    fi

    mkdir -p "$ANDROID_HOME"/cmdline-tools/latest || return 1

    # Download Android SDK
    # https://developer.android.com/studio#command-tools
    local COMMANDLINETOOLSZIP_FILENAME="commandlinetools-linux-10406996_latest.zip"
    local COMMANDLINETOOLSZIP_URL="https://dl.google.com/android/repository/""$COMMANDLINETOOLSZIP_FILENAME"

    wget $COMMANDLINETOOLSZIP_URL

    unzip ./"$COMMANDLINETOOLSZIP_FILENAME" -d "$ANDROID_HOME"

    mv "$ANDROID_HOME"/cmdline-tools/NOTICE.txt "$ANDROID_HOME"/cmdline-tools/latest/
    mv "$ANDROID_HOME"/cmdline-tools/source.properties "$ANDROID_HOME"/cmdline-tools/latest/
    mv "$ANDROID_HOME"/cmdline-tools/lib "$ANDROID_HOME"/cmdline-tools/latest/
    mv "$ANDROID_HOME"/cmdline-tools/bin "$ANDROID_HOME"/cmdline-tools/latest/

    yes | "$ANDROID_HOME"/cmdline-tools/latest/bin/sdkmanager --licenses
    "$ANDROID_HOME"/cmdline-tools/latest/bin/sdkmanager "platform-tools" "platforms;android-34"

    rm ./"$COMMANDLINETOOLSZIP_FILENAME"
}

# https://brew.sh
if ! command -v brew; then
    echo " >> Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

eval "$(/opt/homebrew/bin/brew shellenv)"

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
    bash \
    coreutils \
    wget \
    eza \
    jsonnet \
    macvim \
    git \
    go \
    node \
    gradle \
    openjdk \
    flock \
    tmux \
    python@3

brew install openjdk@21
# Instructions from that keg...
sudo ln -sfn /opt/homebrew/opt/openjdk@21/libexec/openjdk.jdk /Library/Java/JavaVirtualMachines/openjdk-21.jdk

brew install \
    docker \
    docker-machine \
    docker-compose

#brew install --cask unity-hub
brew install --cask \
    font-inconsolata \
    font-inconsolata-nerd-font \
    font-cascadia-code \
    font-caskaydia-cove-nerd-font \
    font-jetbrains-mono \
    font-jetbrains-mono-nerd-font

brew tap gdubw/gng
brew install gng

# https://github.com/Genymobile/scrcpy
brew install \
    sdl2 \
    ffmpeg \
    libusb \
    pkg-config \
    meson

cd ~ || exit

install_android_sdk
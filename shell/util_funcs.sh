#! /bin/bash

#pragma once
#pragma requires debug.sh

if ! declare -f __is_shell_zsh &>/dev/null; then
    function __is_shell_zsh() {
        [[ -n "$ZSH_VERSION" ]]
    }
fi

alias myip='curl http://ipecho.net/plain; echo'

# kill_port_proc <port>
function kill_port_proc() {
    readonly port=${1:?"The port must be specified."}

    lsof -i tcp:"$port" | grep LISTEN | awk '{print $2}'
}

function make_python_venv() {
    _dotTrace_enter "$@"
    python3 -m venv ./.venv
    local rc=$?
    if (( rc != 0 )); then
        _dotTrace_exit "$rc"
        return "$rc"
    fi
    cd .; cd -
    _dotTrace_exit 0
}

function wintitle() {
    if [ -z "$1" ]; then
        echo "Missing window title"
        return 1
    fi

    printf '\e]0;%s\a' "$1"
}

# https://unix.stackexchange.com/questions/481285/linux-how-to-get-window-title-with-just-shell-script
function get_title() { (
    set -e
    ss=$(stty -g)
    trap 'exit 11' INT QUIT TERM
    trap 'stty "$ss"' EXIT
    e=$(printf '\033')
    st=$(printf '\234')
    t=
    stty -echo -icanon min 0 time "${2:-2}"
    printf %s "${1:-\033[21t}" > "$(tty)"
    while c=$(dd bs=1 count=1 2>/dev/null) && [ "$c" ]; do
        t="$t$c"
        case "$t" in
        $e*$e\\ | $e*$st)
            t=${t%"$e"\\}
            t=${t%"$st"}
            printf '%s\n' "${t#"$e"\][lL]}"
            exit 0
            ;;
        $e*) ;;
        *)
            break
            ;;
        esac
    done
    printf %s "$t"
    exit 1
); }

function list_colors() {
    local COLUMN_WIDTH=${1:-6}

    if command -v echoti &>/dev/null; then
        echo "echoti colors - $(echoti colors)"
    fi

    echo "COLORTERM - $COLORTERM"

    # Normal colors
    for color in {0..7}; do
        printf "\e[38;5;%sm %s" "${color}" "${color}"
    done

    printf "\e[0m ||"

    # Bright colors
    for color in {8..15}; do
        printf "\e[38;5;%sm %s" "${color}" "${color}"
    done

    printf "\n"

    if [[ "$1" == "--short" ]]; then
        return
    fi

    for x in {0..0}; do # {0..8}
        for i in {30..37}; do
            for a in {40..47}; do
                printf "\e[%s;%s;%sm\\\e[%s;%s;%sm\e[0m " "${x}" "${i}" "${a}" "${x}" "${i}" "${a}"
            done
            printf "\n"
        done
    done
    printf "\n"

    local column_index=0
    local background_loop_color=16
    for color in {016..255}; do
        printf "\e[38;5;%sm %s" "${color}" "${color}"
        column_index=$((column_index + 1))
        if [ "$column_index" -eq "$COLUMN_WIDTH" ]; then
            printf "  \e[38;5;15m"
            while [ "$background_loop_color" -le "$color" ]; do
                # Colored background, white text, color value
                printf "\e[48;5;%sm   " "${background_loop_color}"
                background_loop_color=$((background_loop_color + 1))
            done

            printf "\e[0m\n"
            column_index=0
        fi
    done

    # Reset the color of the terminal
    printf "\e[0m\n"
}

if __is_shell_zsh; then
    # Linter is not happy with ZSH syntax in a bash script.
    function debug_color_env() {
        local color_var=${1:-"LS_COLORS"}
        # shellcheck disable=SC2034 disable=SC2296
        local color_value=${(P)color_var}
        # shellcheck disable=SC2206 disable=SC2296
        local parts=(${(s/:/)color_value})
        # shellcheck disable=SC2128
        for ls_color in $parts; do
            printf '\e[%sm%s\e[0m ' "${ls_color##*=}" "${ls_color%%=*}"
        done
        echo ""
    }
else
    function debug_color_env() {
        local color_var=${1:-"LS_COLORS"}
        local color_value
        local parts

        # Read the value of the color variable
        color_value=$(eval echo \$"$color_var")

        # Split the color variable into parts
        IFS=':' read -r -a parts <<< "$color_value"

        # Iterate over the parts and print them
        for ls_color in "${parts[@]}"; do
            printf '\e[%sm%s\e[0m ' "${ls_color##*=}" "${ls_color%%=*}"
        done
        echo ""
    }
fi

function bootstrap_fonts() {
    local download_dir="$HOME/Downloads"
    local font_dir="$HOME/.local/share/fonts"
    # __is_on_macos
    if [[ "$(uname -s)" == "Darwin" ]]; then
        font_dir="$HOME/Library/Fonts"
    fi
    echo "Creating font directory: $font_dir"
    # Ensure the Downloads and fonts directories exist
    mkdir -p "$download_dir"
    mkdir -p "$font_dir"

    local font_families=( \
        "JetBrainsMono" \
        "CascadiaCode" \
        "Hack" \
        "Inconsolata" \
        "FiraCode" \
        "UbuntuSans" \
    )

    local nf_version
    nf_version=$(wget -q -O - "https://api.github.com/repos/ryanoasis/nerd-fonts/releases/latest" | grep "\"name\"" | head -n 1 | cut -d '"' -f 4)
    echo "Resolved nerd-fonts version: ${nf_version}"

    for font_family in "${font_families[@]}"; do
        local font_url="https://github.com/ryanoasis/nerd-fonts/releases/download/${nf_version}/${font_family}.zip"
        echo "Downloading ${font_family} from ${font_url}"
        wget -O "$download_dir/${font_family}.zip" "${font_url}"
        unzip -f -o -d "$font_dir" "$download_dir/${font_family}.zip" "*.ttf"
        rm "$download_dir/${font_family}.zip"
    done

    if command -v fc-cache &> /dev/null; then
        echo "Updating font cache..."
        fc-cache -f -v
    fi
}

function bootstrap_apt_packages() {
    sudo apt update

    echo "Installing core apt packages"
    sudo apt install -y \
        build-essential \
        wget \
        curl \
        rsync \
        gcc \
        make \
        jq \
        nodejs \
        vim \
        vim-gtk3 \
        python3 \
        python3.11-venv \
        python-is-python3 \
        python3-dev \
        python3.11-venv \
        gpg \
        zsh \
        git \
        jsonnet \
        libgtk-4-dev \
        libadwaita-1-dev \
        blueprint-compiler \
        gettext \
        libxml2-utils \
        default-jdk

    if command -v snap &> /dev/null; then
        echo "Installing snap packages"
        sudo snap install zig --classic --beta
        sudo snap install code --classic
        sudo snap install spotify
    fi

    # TODO: Initialize node and nvm
    #curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.0/install.sh | bash
    echo "Installing Google Chrome .deb"
    wget -O ~/Downloads/google-chrome.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
    sudo dpkg -i ~/Downloads/google-chrome.deb || sudo apt install -f -y
    rm ~/Downloads/google-chrome.deb

    mkdir -p ~/source

    echo "Cloning jsonnet and ghostty sources"
    git clone https://github.com/google/jsonnet.git ~/source/jsonnet
    pushd ~/source/jsonnet

    make
    sudo ln -s "$PWD/jsonnet" /usr/bin/jsonnet

    git clone https://github.com/ghostty-org/ghostty ~/source/ghostty

    popd

    sudo apt install -y \
        repo

    sudo mkdir -p /etc/apt/keyrings
    wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
    echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list
    sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list

    sudo apt update

    echo "Installing eza apt package"
    sudo apt install -y \
        eza
}

function bootstrap_brew_packages() {
    # https://brew.sh
    if ! command -v brew; then
        echo " >> Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi

    eval "$(/opt/homebrew/bin/brew shellenv)"

    echo " >> Updating Homebrew"
    brew update

    # Consider whether to add Bartender.
    echo " >> Installing Homebrew casks"
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
        microsoft-office

    # brew install --cask microsoft-edge
    # brew install --cask adobe-creative-cloud
    # brew install --cask dotnet-sdk

    echo " >> Installing Homebrew packages"
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
        imagemagick \
        ghc \
        python@3

    echo "Linking openjdk@21"
    brew install openjdk@21
    # Instructions from that keg...
    sudo ln -sfn /opt/homebrew/opt/openjdk@21/libexec/openjdk.jdk /Library/Java/JavaVirtualMachines/openjdk-21.jdk

    echo "Installing Docker tooling"
    brew install --cask \
        docker
    brew install \
        docker-machine \
        docker-compose

    echo "Installing gng"
    brew tap gdubw/gng
    brew install gng

    # https://github.com/Genymobile/scrcpy
    echo "Installing scrcpy build deps"
    brew install \
        sdl2 \
        ffmpeg \
        libusb \
        pkg-config \
        meson

    cd ~ || exit
}

function bootstrap_android_sdk() {
    if [ -z "$ANDROID_HOME" ]; then
        export ANDROID_HOME="$HOME/Android/Sdk"
    fi
    mkdir -p "$ANDROID_HOME/cmdline-tools/latest" || return 1

    # Download Android SDK
    # https://developer.android.com/studio#command-tools
    local COMMANDLINETOOLSZIP_FILENAME="commandlinetools-linux-10406996_latest.zip"
    local COMMANDLINETOOLSZIP_URL="https://dl.google.com/android/repository/${COMMANDLINETOOLSZIP_FILENAME}"

    echo "Downloading Android commandline tools: ${COMMANDLINETOOLSZIP_FILENAME}"
    wget "$COMMANDLINETOOLSZIP_URL"

    unzip "./${COMMANDLINETOOLSZIP_FILENAME}" -d "$ANDROID_HOME"

    mv "$ANDROID_HOME/cmdline-tools/NOTICE.txt" "$ANDROID_HOME/cmdline-tools/latest/"
    mv "$ANDROID_HOME/cmdline-tools/source.properties" "$ANDROID_HOME/cmdline-tools/latest/"
    mv "$ANDROID_HOME/cmdline-tools/lib" "$ANDROID_HOME/cmdline-tools/latest/"
    mv "$ANDROID_HOME/cmdline-tools/bin" "$ANDROID_HOME/cmdline-tools/latest/"

    echo "Accepting SDK licenses"
    yes | "$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager" --licenses
    echo "Installing platform-tools and android-34"
    "$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager" "platform-tools" "platforms;android-34"

    rm "./${COMMANDLINETOOLSZIP_FILENAME}"
}

function bootstrap_kde_plasma() {
    sudo apt update
    sudo apt upgrade

    sudo add-apt-repository ppa:kubuntu-ppa/backports -y
    sudo apt update
    sudo apt install plasma-desktop -y
}

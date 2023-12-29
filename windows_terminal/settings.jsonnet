local CopyCommand = {
    command:
    {
        action: "copy",
        singleLine: false
    },
    keys: "ctrl+c"
};
local PasteCommand = {
    command: "paste",
    keys: "ctrl+v"
};
local FindCommand = {
    command: "find",
    keys: "ctrl+shift+f"
};
local SplitPaneCommand = {
    command:
    {
        action: "splitPane",
        split: "auto",
        splitMode: "duplicate"
    },
    keys: "alt+shift+d"
};

local Font(face) = {
    face: face
};

local fonts = {
    CaskaydiaCoveMono: Font("CaskaydiaCove Nerd Font Mono"),
    LucidaConsole: Font("Lucida Console"),
};

local Theme(name, applicationTheme) = {
    name: name,
    tab: {
        background: null,
        showCloseButton: "always",
        unfocusedBackground: null
    },
    window: {
        applicationTheme: applicationTheme,
        useMica: false
    }
};

local ColorPack(black, blue, cyan, green, purple, red, white, yellow) = {
    black: black,
    blue: blue,
    cyan: cyan,
    green: green,
    purple: purple,
    red: red,
    white: white,
    yellow: yellow
};

local BrightColorPack(black, blue, cyan, green, purple, red, white, yellow) = {
    brightBlack: black,
    brightBlue: blue,
    brightCyan: cyan,
    brightGreen: green,
    brightPurple: purple,
    brightRed: red,
    brightWhite: white,
    brightYellow: yellow
};

local colorPacks = {
   Campbell:     ColorPack("#0C0C0C", "#0037DA", "#3A96DD", "#13A10E", "#881798", "#C50F1F", "#CCCCCC", "#C19C00"),
   OneHalfDark:  ColorPack("#282C34", "#61AFEF", "#56B6C2", "#98C379", "#C678DD", "#E06C75", "#DCDFE4", "#E5C07B"),
   OneHalfLight: ColorPack("#383A42", "#0184BC", "#0997B3", "#50A14F", "#A626A4", "#E45649", "#FAFAFA", "#C18301"),
   Solarized:    ColorPack("#002B36", "#268BD2", "#2AA198", "#859900", "#D33682", "#DC322F", "#EEE8D5", "#B58900"),
   Tango:        ColorPack("#000000", "#3465A4", "#06989A", "#4E9A06", "#75507B", "#CC0000", "#D3D7CF", "#C4A000"),
   Ubuntu:       ColorPack("#171421", "#0037DA", "#3A96DD", "#26A269", "#881798", "#C21A23", "#CCCCCC", "#A2734C"),
   Ubuntu2:      ColorPack("#2e3436", "#3465a4", "#06989a", "#4e9a06", "#75507b", "#cc0000", "#d3d7cf", "#c4a000"),
   Vintage:      ColorPack("#000000", "#000080", "#008080", "#008000", "#800080", "#800000", "#C0C0C0", "#808000"),
   Frost:        ColorPack("#3C5712", "#17b2ff", "#3C96A6", "#6AAE08", "#991070", "#8D0C0C", "#6E386E", "#991070"),
};

local brightColorPacks = {
    Campbell:     BrightColorPack("#767676", "#3B78FF", "#61D6D6", "#16C60C", "#B4009E", "#E74856", "#F2F2F2", "#F9F1A5"),
    OneHalfDark:  BrightColorPack("#5A6374", "#61AFEF", "#56B6C2", "#98C379", "#C678DD", "#E06C75", "#DCDFE4", "#E5C07B"),
    OneHalfLight: BrightColorPack("#4F525D", "#61AFEF", "#56B5C1", "#98C379", "#C577DD", "#DF6C75", "#FFFFFF", "#E4C07A"),
    Solarized:    BrightColorPack("#073642", "#839496", "#93A1A1", "#586E75", "#6C71C4", "#CB4B16", "#FDF6E3", "#657B83"),
    Tango:        BrightColorPack("#555753", "#729FCF", "#34E2E2", "#8AE234", "#AD7FA8", "#EF2929", "#EEEEEC", "#FCE94F"),
    Ubuntu:       BrightColorPack("#767676", "#08458F", "#2C9FB3", "#26A269", "#A347BA", "#C01C28", "#F2F2F2", "#A2734C"),
    Ubuntu2:      BrightColorPack("#555753", "#729fcf", "#34e2e2", "#8ae234", "#ad7fa8", "#ef2929", "#eeeeec", "#fce94f"),
    Vintage:      BrightColorPack("#808080", "#0000FF", "#00FFFF", "#00FF00", "#FF00FF", "#FF0000", "#FFFFFF", "#FFFF00"),
    Frost:        BrightColorPack("#749B36", "#27B2F6", "#13A8C0", "#89AF50", "#F2A20A", "#F49B36", "#741274", "#991070"),
};

local Scheme(name, colors, brightColors, background, foreground, cursorColor="#FFFFFF", selectionBackground="#FFFFFF") = {
    name: name,
    background: background,
    cursorColor: cursorColor,
    foreground: foreground,
    selectionBackground: selectionBackground,
} + colors + brightColors;

local schemes = {
    Campbell: Scheme("Campbell", colorPacks.Campbell, brightColorPacks.Campbell,                      colorPacks.Campbell.black, colorPacks.Campbell.white),
    CampbellPowershell: Scheme("Campbell Powershell", colorPacks.Campbell, brightColorPacks.Campbell, "#012456", colorPacks.Campbell.white),
    OneHalfDark: Scheme("One Half Dark", colorPacks.OneHalfDark, brightColorPacks.OneHalfDark,        "#282C34", colorPacks.OneHalfDark.white),
    OneHalfLight: Scheme("One Half Light", colorPacks.OneHalfLight, brightColorPacks.OneHalfLight,    colorPacks.OneHalfLight.white, colorPacks.OneHalfLight.black, brightColorPacks.OneHalfLight.brightBlack),
    SolarizedDark: Scheme("Solarized Dark", colorPacks.Solarized, brightColorPacks.Solarized,         colorPacks.Solarized.black, brightColorPacks.Solarized.brightBlue),
    SolarizedLight: Scheme("Solarized Light", colorPacks.Solarized, brightColorPacks.Solarized,       brightColorPacks.Solarized.brightWhite, brightColorPacks.Solarized.brightYellow, colorPacks.Solarized.black),
    TangoDark: Scheme("Tango Dark", colorPacks.Tango, brightColorPacks.Tango,                         colorPacks.Tango.black, colorPacks.Tango.white),
    TangoLight: Scheme("Tango Light", colorPacks.Tango, brightColorPacks.Tango,                       "#FFFFFF", $.TangoDark.brightBlack, colorPacks.Tango.black),
    Ubuntu: Scheme("Ubuntu", colorPacks.Ubuntu, brightColorPacks.Ubuntu,                              "#300A24", "#FFFFFF"),
    Ubuntu2: Scheme("Ubuntu2", colorPacks.Ubuntu2, brightColorPacks.Ubuntu2,                          "#300A24", "#eeeeec", "#bbbbbb", "#b5d5ff"),
    Vintage: Scheme("Vintage", colorPacks.Vintage, brightColorPacks.Vintage,                          colorPacks.Vintage.black, colorPacks.Vintage.white),
};

local ProfileBase(name, scheme, source, guid, hidden=false) = {
    name: name,
    [if source != null then "source"]: source,
    [if scheme != null then "colorScheme"]: scheme.name,
    guid: "{" + guid + "}",
    hidden: hidden
};

local profiles = {
    WindowsPowershell: ProfileBase("Windows PowerShell", schemes.CampbellPowershell, null, "61c54bbd-c2c6-5271-96e7-009a87ff44bf") + {
        backgroundImage: "%DOTFILES_SRC_DIR%\\wallpaper\\windows_bliss.jpg",
        backgroundImageOpacity: 0.4,
        commandline: "%SystemRoot%\\System32\\WindowsPowerShell\\v1.0\\powershell.exe",
    },
    CommandPrompt: ProfileBase("Command Prompt", schemes.Campbell, null, "0caa0dad-35be-5f56-a8ff-afceeeaa6101") + {
        backgroundImage: "%DOTFILES_SRC_DIR%\\wallpaper\\vista_flare.jpg",
        backgroundImageOpacity: 0.5,
        commandline: "%SystemRoot%\\System32\\cmd.exe",
        "experimental.retroTerminalEffect": true,
        font: fonts.LucidaConsole,
        padding: "20"
    },
    GitBash: ProfileBase("Git Bash", schemes.OneHalfDark, "Git", "2ece5bfe-50ed-5f3a-ab87-5cd4baafed2b"),
    Ubuntu: ProfileBase("Ubuntu", schemes.Ubuntu2, "Windows.Terminal.Wsl", "17bf3de4-5353-5709-bcf9-835bd952a95e") + {
        backgroundImage: "%DOTFILES_SRC_DIR%\\wallpaper\\ubuntu_purple.jpg",
        backgroundImageOpacity: 0.7,
        opacity: 70,
    },
    Powershell: ProfileBase("PowerShell", null, null, "127d4343-0ec3-4a82-8067-4fab94b1b073") + {
        "commandline": "\"C:\\Program Files\\PowerShell\\7\\pwsh.exe\"",
        "icon": "ms-appx:///ProfileIcons/pwsh.png",
        "startingDirectory": "%USERPROFILE%"
    },
    // ProfileBase("Azure Cloud Shell", "Windows.Terminal.Azure", "b453ae62-4e3d-5e58-b989-0a998ec441b8", true),
    // ProfileBase("Developer Command Prompt for VS 2022", "Windows.Terminal.VisualStudio", "ff435c96-5077-5aa1-861a-91b418a4bd05", true),
    // ProfileBase("Developer PowerShell for VS 2022", "Windows.Terminal.VisualStudio", "58245afd-7b94-5de9-b3d9-96a73060b542", true),
    // ProfileBase("PowerShell", "Windows.Terminal.PowershellCore", "574e775e-4f2a-5b96-ac1e-a2962a402336", true),
    // ProfileBase("Developer Command Prompt for VS 2019", "Windows.Terminal.VisualStudio", "7d941b33-ca36-5052-ba8b-d2b0447a9818", true),
    // ProfileBase("Developer PowerShell for VS 2019", "Windows.Terminal.VisualStudio", "9ce25c37-051a-565a-9192-bc8525c076e4", true),
    // ProfileBase("PowerShell 7", "Windows.Terminal.PowershellCore", "5fb123f1-af88-5b5c-8953-d14a8def1978", true),
};

{
    "$help": "https://aka.ms/terminal-documentation",
    "$schema": "https://aka.ms/terminal-profiles-schema",
    actions: [
        CopyCommand,
        { "keys": "ctrl+shift+up",   "command": { "action": "selectOutput", "direction": "prev" }, },
        PasteCommand,
        FindCommand,
        SplitPaneCommand,
        { "keys": "ctrl+shift+down", "command": { "action": "selectOutput", "direction": "next" }, },
        { "keys": "ctrl+up",   "command": { "action": "scrollToMark", "direction": "previous" }, },
        { "keys": "ctrl+alt+shift+down", "command": { "action": "selectCommand", "direction": "next" }, },
        { "keys": "ctrl+down", "command": { "action": "scrollToMark", "direction": "next" }, },
        { "keys": "ctrl+alt+shift+up",   "command": { "action": "selectCommand", "direction": "prev" }, },
    ],
    newTabMenu: [
        {
            type: "remainingProfiles"
        }
    ],
    copyFormatting: "none",
    copyOnSelect: false,
    defaultProfile: profiles.Ubuntu.guid,
    initialCols: 140,
    initialRows: 50,
    profiles: {
        defaults: {
            adjustIndistinguishableColors: "always",
            antialiasingMode: "cleartype",
            bellStyle: [
                "window",
                "taskbar",
            ],
            colorScheme: schemes.SolarizedDark.name,
            font: fonts.CaskaydiaCoveMono,
            opacity: 100,
            useAcrylic: true,
            useAtlasEngine: true,
            // https://devblogs.microsoft.com/commandline/shell-integration-in-the-windows-terminal/
            "experimental.showMarksOnScrollbar": true,
            "experimental.autoMarkPrompts": true,
        },
        list: [
            profiles.Ubuntu,
            profiles.Powershell,
            profiles.CommandPrompt,
            profiles.GitBash,
            profiles.WindowsPowershell,
        ],
    },
    schemes: std.objectValues(schemes),
    themes: []
}
local color_defs = import '../shell/color_definitions.libsonnet';

local Schemes = color_defs.Schemes;
local Colors = color_defs.Colors;
local ColorFromHex = color_defs.ColorFromHex;

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

local Scheme(name, scheme, background, foreground, cursorColor=Colors.White, selectionBackground=Colors.White) = {
    name: name,
    background: background.hexcolor,
    cursorColor: cursorColor.hexcolor,
    foreground: foreground.hexcolor,
    selectionBackground: selectionBackground.hexcolor,
} + scheme.color_pack + scheme.bright_color_pack;

local schemes = {
    Campbell: Scheme("Campbell", Schemes.Campbell,                      Schemes.Campbell.black, Schemes.Campbell.white),
    CampbellPowershell: Scheme("Campbell Powershell", Schemes.Campbell, ColorFromHex("#012456"), Schemes.Campbell.white),
    OneHalfDark: Scheme("One Half Dark", Schemes.OneHalfDark,           ColorFromHex("#282C34"), Schemes.OneHalfDark.white),
    OneHalfLight: Scheme("One Half Light", Schemes.OneHalfLight,        Schemes.OneHalfLight.white, Schemes.OneHalfLight.black, Schemes.OneHalfLight.bright_black),
    SolarizedDark: Scheme("Solarized Dark", Schemes.Solarized,          Schemes.Solarized.black, Schemes.Solarized.bright_blue),
    SolarizedLight: Scheme("Solarized Light", Schemes.Solarized,        Schemes.Solarized.bright_white, Schemes.Solarized.bright_yellow, Schemes.Solarized.black),
    TangoDark: Scheme("Tango Dark", Schemes.Tango,                      Schemes.Tango.black, Schemes.Tango.white),
    TangoLight: Scheme("Tango Light", Schemes.Tango,                    Colors.White, Schemes.Tango.bright_black, Schemes.Tango.black),
    Ubuntu: Scheme("Ubuntu", Schemes.Ubuntu,                            ColorFromHex("#300A24"), Colors.White),
    Ubuntu2: Scheme("Ubuntu2", Schemes.Ubuntu2,                         ColorFromHex("#300A24"), ColorFromHex("#eeeeec"), ColorFromHex("#bbbbbb"), ColorFromHex("#b5d5ff")),
    Vintage: Scheme("Vintage", Schemes.Vintage,                         Schemes.Vintage.black, Schemes.Vintage.white),
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
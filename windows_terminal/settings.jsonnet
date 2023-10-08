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

local SettingsRoot = {
    "$help": "https://aka.ms/terminal-documentation",
    "$schema": "https://aka.ms/terminal-profiles-schema",
    actions: [
        CopyCommand,
        PasteCommand,
        FindCommand,
        SplitPaneCommand,
    ],
    newTabMenu: [
        {
            type: "remainingProfiles"
        }
    ],
};

local Font(face) = {
    face: face
};

local CaskaydiaCoveMonoFace = Font("CaskaydiaCove Nerd Font Mono");
local LucidaConsoleFace = Font("Lucida Console");

local Theme(name, applicationTheme) = {
    name: name,
    tab:
    {
        background: null,
        showCloseButton: "always",
        unfocusedBackground: null
    },
    window:
    {
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

local CampbellColorPack     = ColorPack("#0C0C0C", "#0037DA", "#3A96DD", "#13A10E", "#881798", "#C50F1F", "#CCCCCC", "#C19C00");
local OneHalfDarkColorPack  = ColorPack("#282C34", "#61AFEF", "#56B6C2", "#98C379", "#C678DD", "#E06C75", "#DCDFE4", "#E5C07B");
local OneHalfLightColorPack = ColorPack("#383A42", "#0184BC", "#0997B3", "#50A14F", "#A626A4", "#E45649", "#FAFAFA", "#C18301");
local SolarizedColorPack    = ColorPack("#002B36", "#268BD2", "#2AA198", "#859900", "#D33682", "#DC322F", "#EEE8D5", "#B58900");
local TangoColorPack        = ColorPack("#000000", "#3465A4", "#06989A", "#4E9A06", "#75507B", "#CC0000", "#D3D7CF", "#C4A000");
local UbuntuColorPack       = ColorPack("#171421", "#0037DA", "#3A96DD", "#26A269", "#881798", "#C21A23", "#CCCCCC", "#A2734C");
local VintageColorPack      = ColorPack("#000000", "#000080", "#008080", "#008000", "#800080", "#800000", "#C0C0C0", "#808000");
local FrostColorPack        = ColorPack("#3C5712", "#17b2ff", "#3C96A6", "#6AAE08", "#991070", "#8D0C0C", "#6E386E", "#991070");

local CampbellBrightColorPack     = BrightColorPack("#767676", "#3B78FF", "#61D6D6", "#16C60C", "#B4009E", "#E74856", "#F2F2F2", "#F9F1A5");
local OneHalfDarkBrightColorPack  = BrightColorPack("#5A6374", "#61AFEF", "#56B6C2", "#98C379", "#C678DD", "#E06C75", "#DCDFE4", "#E5C07B");
local OneHalfLightBrightColorPack = BrightColorPack("#4F525D", "#61AFEF", "#56B5C1", "#98C379", "#C577DD", "#DF6C75", "#FFFFFF", "#E4C07A",);
local SolarizedBrightColorPack    = BrightColorPack("#073642", "#839496", "#93A1A1", "#586E75", "#6C71C4", "#CB4B16", "#FDF6E3", "#657B83");
local TangoBrightColorPack        = BrightColorPack("#555753", "#729FCF", "#34E2E2", "#8AE234", "#AD7FA8", "#EF2929", "#EEEEEC", "#FCE94F");
local UbuntuBrightColorPack       = BrightColorPack("#767676", "#08458F", "#2C9FB3", "#26A269", "#A347BA", "#C01C28", "#F2F2F2", "#A2734C");
local VintageBrightColorPack      = BrightColorPack("#808080", "#0000FF", "#00FFFF", "#00FF00", "#FF00FF", "#FF0000", "#FFFFFF", "#FFFF00");
local FrostBrightColorPack        = BrightColorPack("#749B36", "#27B2F6", "#13A8C0", "#89AF50", "#F2A20A", "#F49B36", "#741274", "#991070");

local Scheme(name, colors, brightColors, background, foreground, cursorColor="#FFFFFF", selectionBackground="#FFFFFF") = {
    name: name,
    background: background,
    cursorColor: cursorColor,
    foreground: foreground,
    selectionBackground: selectionBackground,
} + colors + brightColors;

local Campbell = Scheme("Campbell", CampbellColorPack, CampbellBrightColorPack,                      CampbellColorPack.black, CampbellColorPack.white);
local CampbellPowershell = Scheme("Campbell Powershell", CampbellColorPack, CampbellBrightColorPack, "#012456", CampbellColorPack.white);
local OneHalfDark = Scheme("One Half Dark", OneHalfDarkColorPack, OneHalfDarkBrightColorPack,        "#282C34", OneHalfDarkColorPack.white);
local OneHalfLight = Scheme("One Half Light", OneHalfLightColorPack, OneHalfLightBrightColorPack,    OneHalfLightColorPack.white, OneHalfLightColorPack.black, OneHalfLightBrightColorPack.brightBlack);
local SolarizedDark = Scheme("Solarized Dark", SolarizedColorPack, SolarizedBrightColorPack,         SolarizedColorPack.black, SolarizedBrightColorPack.brightBlue);
local SolarizedLight = Scheme("Solarized Light", SolarizedColorPack, SolarizedBrightColorPack,       SolarizedBrightColorPack.brightWhite, SolarizedBrightColorPack.brightYellow, SolarizedColorPack.black);
local TangoDark =  Scheme("Tango Dark", TangoColorPack, TangoBrightColorPack,                        TangoColorPack.black, TangoColorPack.white);
local TangoLight = Scheme("Tango Light", TangoColorPack, TangoBrightColorPack,                       "#FFFFFF", TangoDark.brightBlack, TangoColorPack.black);
local Ubuntu = Scheme("Ubuntu-ColorScheme", UbuntuColorPack, UbuntuBrightColorPack,                  "#300A24", "#FFFFFF");
local Vintage = Scheme("Vintage", VintageColorPack, VintageBrightColorPack,                          VintageColorPack.black, VintageColorPack.white);

local schemes = [
    Campbell,
    CampbellPowershell,
    OneHalfDark,
    OneHalfLight,
    SolarizedDark,
    SolarizedLight,
    TangoDark,
    TangoLight,
    Ubuntu,
    Vintage,
];

local ProfileBase(name, scheme, source, guid, hidden=false) = {
    name: name,
    [if source != null then "source"]: source,
    colorScheme: scheme.name,
    guid: "{" + guid + "}",
    hidden: hidden
};

SettingsRoot + {
    copyFormatting: "none",
    copyOnSelect: false,
    defaultProfile: "{17bf3de4-5353-5709-bcf9-835bd952a95e}",
    profiles: {
        defaults:
        {
            adjustIndistinguishableColors: "always",
            antialiasingMode: "cleartype",
            bellStyle:
            [
                "taskbar",
                "window"
            ],
            colorScheme: SolarizedDark.name,
            font: CaskaydiaCoveMonoFace,
            opacity: 100,
            useAcrylic: true,
            useAtlasEngine: true
        },
        list:
        [
            ProfileBase("Windows PowerShell", CampbellPowershell, null, "61c54bbd-c2c6-5271-96e7-009a87ff44bf") + {
                backgroundImage: "%DOTFILES_SRC_DIR%\\wallpaper\\windows_bliss.jpg",
                backgroundImageOpacity: 0.4,
                commandline: "%SystemRoot%\\System32\\WindowsPowerShell\\v1.0\\powershell.exe",
            },
            ProfileBase("Command Prompt", Campbell, null, "0caa0dad-35be-5f56-a8ff-afceeeaa6101") + {
                backgroundImage: "%DOTFILES_SRC_DIR%\\wallpaper\\vista_flare.jpg",
                backgroundImageOpacity: 0.5,
                commandline: "%SystemRoot%\\System32\\cmd.exe",
                "experimental.retroTerminalEffect": true,
                font: LucidaConsoleFace,
                padding: "20"
            },
            ProfileBase("Git Bash", OneHalfDark, "Git", "2ece5bfe-50ed-5f3a-ab87-5cd4baafed2b"),
            ProfileBase("Ubuntu", Ubuntu, "Windows.Terminal.Wsl", "17bf3de4-5353-5709-bcf9-835bd952a95e") + {
                backgroundImage: "%DOTFILES_SRC_DIR%\\wallpaper\\ubuntu_purple.jpg",
                backgroundImageOpacity: 0.7,
                opacity: 70,
            },
            // ProfileBase("Azure Cloud Shell", "Windows.Terminal.Azure", "b453ae62-4e3d-5e58-b989-0a998ec441b8", true),
            // ProfileBase("Developer Command Prompt for VS 2022", "Windows.Terminal.VisualStudio", "ff435c96-5077-5aa1-861a-91b418a4bd05", true),
            // ProfileBase("Developer PowerShell for VS 2022", "Windows.Terminal.VisualStudio", "58245afd-7b94-5de9-b3d9-96a73060b542", true),
            // ProfileBase("PowerShell", "Windows.Terminal.PowershellCore", "574e775e-4f2a-5b96-ac1e-a2962a402336", true),
            // ProfileBase("Developer Command Prompt for VS 2019", "Windows.Terminal.VisualStudio", "7d941b33-ca36-5052-ba8b-d2b0447a9818", true),
            // ProfileBase("Developer PowerShell for VS 2019", "Windows.Terminal.VisualStudio", "9ce25c37-051a-565a-9192-bc8525c076e4", true),
            // ProfileBase("PowerShell 7", "Windows.Terminal.PowershellCore", "5fb123f1-af88-5b5c-8953-d14a8def1978", true),
        ]
    },
    schemes: schemes,
    themes: [
        Theme("legacyDark", "dark"),
        Theme("legacyLight", "light"),
        Theme("legacySystem", "system"),
    ]
}

local color_defs = import '../shell/color_definitions.libsonnet';
local wallpapers = import '../wallpaper/wallpapers.jsonnet';

local Color = color_defs.Color;
local KonsoleColor(color) = {
    Color: "%d,%d,%d" % [color.red255, color.green255, color.blue255],
};

local getBackground(extended_scheme) = {
    value: if extended_scheme != null && extended_scheme.background != null then extended_scheme.background else color_defs.Colors.Black
};
local getForeground(extended_scheme) = {
    value: if extended_scheme != null && extended_scheme.foreground != null then extended_scheme.foreground else color_defs.Colors.White
};
{
    KonsoleColorSchemeIni(name, scheme, extended_scheme, wallpaper_path): {
        name:: name,
        filename:: name + '.colorscheme',
        sections: {
            Color0: KonsoleColor(scheme.color0),
            Color0Faint: KonsoleColor(scheme.color0),
            Color0Intense: KonsoleColor(scheme.color0_bold),
            Color1: KonsoleColor(scheme.color1),
            Color1Faint: KonsoleColor(scheme.color1),
            Color1Intense: KonsoleColor(scheme.color1_bold),
            Color2: KonsoleColor(scheme.color2),
            Color2Faint: KonsoleColor(scheme.color2),
            Color2Intense: KonsoleColor(scheme.color2_bold),
            Color3: KonsoleColor(scheme.color3),
            Color3Faint: KonsoleColor(scheme.color3),
            Color3Intense: KonsoleColor(scheme.color3_bold),
            Color4: KonsoleColor(scheme.color4),
            Color4Faint: KonsoleColor(scheme.color4),
            Color4Intense: KonsoleColor(scheme.color4_bold),
            Color5: KonsoleColor(scheme.color5),
            Color5Faint: KonsoleColor(scheme.color5),
            Color5Intense: KonsoleColor(scheme.color5_bold),
            Color6: KonsoleColor(scheme.color6),
            Color6Faint: KonsoleColor(scheme.color6),
            Color6Intense: KonsoleColor(scheme.color6_bold),
            Color7: KonsoleColor(scheme.color7),
            Color7Faint: KonsoleColor(scheme.color7),
            Color7Intense: KonsoleColor(scheme.color7_bold),
            Background: KonsoleColor(getBackground(extended_scheme).value),
            BackgroundIntense: KonsoleColor(getBackground(extended_scheme).value),
            Foreground: KonsoleColor(getForeground(extended_scheme).value),
            ForegroundFaint: KonsoleColor(getForeground(extended_scheme).value),
            ForegroundIntense: KonsoleColor(getForeground(extended_scheme).value),
            General: {
                Anchor: "0.5,0.5",
                Blur: false,
                ColorRandomization: false,
                Description: name,
                FillStyle: "Crop",
                Opacity: 1,
                Wallpaper: wallpaper_path,
                WallpaperFlipType: "NoFlip",
                WallpaperOpacity: 0.4,
            },
        }
    },
    KonsoleProfileIni(profile_name, scheme_name): {
        name:: profile_name,
        filename:: profile_name + '.profile',
        sections: {
            Appearance: {
                ColorScheme: scheme_name,
                Font: 'CaskaydiaCove Nerd Font Mono,14,-1,5,50,0,0,0,0,0',
                UseFontLineChararacters: true,
            },
            'Cursor Options': {
                CursorShape: 1,
            },
            General: {
                AlternatingBackground: 1,
                DimWhenInactive: false,
                Icon: std.extVar('home') + '/.local/share/konsole/google_logo.svg',
                LocalTabTitleFormat: '%n: %w',
                Name: profile_name,
                Parent: 'FALLBACK/',
                StartInCurrentSessionDir: false,
            },
            Scrolling: {
                HistorySize: 10000,
            },
        },
    },
    KonsoleSshconfigIniEntry(group_name, host, profile): {
        group_name: group_name,
        host: host,
        key: group_name + '][' + host.hostname,
        value: {
            hostname: host.hostname,
            identifier: host.hostname,
            importedFromSshConfig: false,
            port: 22,
            profileName: profile,
            sshkey: '',
            useSshConfig: true,
            username: '',
        },
    },
    KonsoleSshconfigIni(entries): {
        "sections": {}
            + { [entry.key]: entry.value for entry in entries }
            + {
                "Global plugin config": {
                    manageProfile: true,
                },
            },
    },
    KonsolercIni(default_profile): {
        main: {
            "2050x1238 screen: Height": 550,
            "2050x1238 screen: Width": 1118,
            "2050x1238 screen: XPosition": 178,
            "2050x1238 screen: YPosition": 238,
            DUMMY0: "DUMMY0",
            MenuBar: "Disabled",
        },
        sections: {
            "Desktop Entry": {
                DefaultProfile: default_profile.filename,
            },
            General: {
                ConfigVersion: 1,
            },
            MainWindow: {
                "2050x1238 screen: Height": 550,
                "2050x1238 screen: Width": 1118,
                "2050x1238 screen: XPosition": 416,
                "2050x1238 screen: YPosition": 289,
                DUMMY0: "DUMMY0",
                RestorePositionForNextInstance: false,
                ToolBarsMovable: "Disabled",
            },
            "MainWindow][Toolbar sessionToolbar": {
                IconSize: 16,
            },
            "Toolbar sessionToolbar": {
                IconSize: 16,
            },
            UiSettings: {
                ColorScheme: "",
            }
        },
    }
}
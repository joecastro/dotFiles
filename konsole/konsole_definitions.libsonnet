local color_defs = import '../shell/color_definitions.libsonnet';

local KonsoleColor(color) = {
    Color: color.rgb255,
};
local getBackground(extended_scheme) = {
    value: if extended_scheme != null && extended_scheme.background != null then extended_scheme.background else color_defs.Colors.Black
};
local getForeground(extended_scheme) = {
    value: if extended_scheme != null && extended_scheme.foreground != null then extended_scheme.foreground else color_defs.Colors.White
};

{
    KonsoleColorSchemeIni(name, scheme, wallpaper_path): {
        name:: name,
        filename:: name + '.colorscheme',
        sections: {
            Background: KonsoleColor(getBackground(scheme.terminal_colors).value),
            BackgroundIntense: KonsoleColor(getBackground(scheme.terminal_colors).value),
            Foreground: KonsoleColor(getForeground(scheme.terminal_colors).value),
            ForegroundFaint: KonsoleColor(getForeground(scheme.terminal_colors).value),
            ForegroundIntense: KonsoleColor(getForeground(scheme.terminal_colors).value),
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
        } + std.foldl(
            function(acc, x) acc + x,
            [{
                ["Color" + std.toString(i)]: KonsoleColor(scheme["color" + std.toString(i)]),
                ["Color" + std.toString(i) + "Faint"]: KonsoleColor(scheme["color" + std.toString(i)]),
                ["Color" + std.toString(i) + "Intense"]: KonsoleColor(scheme["color" + std.toString(i) + "_bold"]),
            } for i in std.range(0, 7)],
            {})
    },
    KonsoleProfileIni(profile_name, icon_path, scheme_name, tab_color, command=null, directory=null): {
        name:: profile_name,
        filename:: profile_name + '.profile',
        sections: {
            Appearance: {
                ColorScheme: scheme_name,
                Font: 'Cascadia Code NF,12,-1,5,29,0,0,0,0,0,SemiLight',
                UseFontLineChararacters: true,
                [if tab_color != null then 'TabColor']: tab_color.rgb255,
            },
            'Cursor Options': {
                CursorShape: 1,
            },
            General: {
                [if command != null then 'Command']: command,
                [if directory != null then 'Directory']: directory,
                AlternatingBackground: 1,
                DimWhenInactive: false,
                Icon: icon_path,
                LocalTabTitleFormat: '%n: %w',
                RemoteTabTitleFormat: '%w (%H)',
                Name: profile_name,
                Parent: 'FALLBACK/',
                StartInCurrentSessionDir: false,
            },
            'Interaction Options': {
                AutoCopySelectedText: true,
                CopyTextAsHTML: false,
                TrimLeadingSpacesInSelectedText: true,
                TrimTrailingSpacesInSelectedText: true,
            },
            Scrolling: {
                HistorySize: 10000,
            },
        },
    },
    KonsoleProfileWithColorscheme(name, scheme, icon_path, wallpaper_path, command=null, directory=null): {
        colorscheme: $.KonsoleColorSchemeIni(name + ' Colors', scheme, wallpaper_path),
        profile: $.KonsoleProfileIni(name, icon_path, name + ' Colors', scheme.terminal_colors.background, command, directory),
    },
    KonsoleSshconfigIniEntry(group_name, host, profile): {
        group_name:: group_name,
        host:: host,
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
    KonsolercIni(default_profile_name): {
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
                DefaultProfile: default_profile_name + '.profile',
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
                ColorScheme: default_profile_name + ' Colors',
            }
        },
    },
    GenerateColorSchemesWithWallpaper(name_suffix, wallpaper_path): [
        $.KonsoleColorSchemeIni(o.key + name_suffix, o.value, wallpaper_path)
        for o in std.objectKeysValues(color_defs.Schemes)
    ],
}

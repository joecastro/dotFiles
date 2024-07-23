
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
    KonsoleColorScheme(name, scheme, extended_scheme, wallpaper): {
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
                FillStyle: "Stretch",
                Opacity: 1,
                Wallpaper: std.extVar('cwd') + '/' + wallpaper.local_path,
                WallpaperFlipType: "NoFlip",
                WallpaperOpacity: wallpaper.blend,
            },
        }
    }
}

local color_defs = import '../terminals/color_definitions.jsonnet';

local Color = color_defs.Color;
local gcloud_color_scheme = color_defs.Schemes.Solarized;
local ColorschemeColor(color) = {
    Color: "%d,%d,%d" % [color.red255, color.green255, color.blue255],
};

local BackgroundColor = Color(0.14, 0.15, 0.15);
local BackgroundIntenseColor = color_defs.Colors.Black;
local ForegroundColor = Color(0.99, 0.99, 0.99);
local ForegroundIntenseColor = color_defs.Colors.White;
std.manifestIni({
    sections: {
        Background: ColorschemeColor(BackgroundColor),
        BackgroundFaint: ColorschemeColor(BackgroundColor),
        BackgroundIntense: ColorschemeColor(BackgroundIntenseColor),
        Color0: ColorschemeColor(gcloud_color_scheme.color0),
        Color0Faint: ColorschemeColor(gcloud_color_scheme.color0),
        Color0Intense: ColorschemeColor(gcloud_color_scheme.color0_bold),
        Color1: ColorschemeColor(gcloud_color_scheme.color1),
        Color1Faint: ColorschemeColor(gcloud_color_scheme.color1),
        Color1Intense: ColorschemeColor(gcloud_color_scheme.color1_bold),
        Color2: ColorschemeColor(gcloud_color_scheme.color2),
        Color2Faint: ColorschemeColor(gcloud_color_scheme.color2),
        Color2Intense: ColorschemeColor(gcloud_color_scheme.color2_bold),
        Color3: ColorschemeColor(gcloud_color_scheme.color3),
        Color3Faint: ColorschemeColor(gcloud_color_scheme.color3),
        Color3Intense: ColorschemeColor(gcloud_color_scheme.color3_bold),
        Color4: ColorschemeColor(gcloud_color_scheme.color4),
        Color4Faint: ColorschemeColor(gcloud_color_scheme.color4),
        Color4Intense: ColorschemeColor(gcloud_color_scheme.color4_bold),
        Color5: ColorschemeColor(gcloud_color_scheme.color5),
        Color5Faint: ColorschemeColor(gcloud_color_scheme.color5),
        Color5Intense: ColorschemeColor(gcloud_color_scheme.color5_bold),
        Color6: ColorschemeColor(gcloud_color_scheme.color6),
        Color6Faint: ColorschemeColor(gcloud_color_scheme.color6),
        Color6Intense: ColorschemeColor(gcloud_color_scheme.color6_bold),
        Color7: ColorschemeColor(gcloud_color_scheme.color7),
        Color7Faint: ColorschemeColor(gcloud_color_scheme.color7),
        Color7Intense: ColorschemeColor(gcloud_color_scheme.color7_bold),
        Foreground: ColorschemeColor(ForegroundColor),
        ForegroundFaint: ColorschemeColor(ForegroundColor),
        ForegroundIntense: ColorschemeColor(ForegroundIntenseColor),
        General: {
            Anchor: "0.5,0.5",
            Blur: false,
            ColorRandomization: false,
            Description: "GCloud Scheme",
            FillStyle: "Stretch",
            Opacity: 1,
            Wallpaper: "/usr/local/google/home/joecastro/Pictures/konsole_gcloud_background.png",
            WallpaperFlipType: "NoFlip",
            WallpaperOpacity: 0.4,
        },
    }
})
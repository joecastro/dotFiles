//  jsonnet -S -m schemes MultiScheme.jsonnet -V cwd=$PWD
local konsole_schemes = import './KonsoleColorSchemes.libsonnet';
local color_defs = import '../shell/color_definitions.libsonnet';
local wallpapers = import '../wallpaper/wallpapers.jsonnet';

{
    'CampbellScheme.ini': std.manifestIni(konsole_schemes.KonsoleColorScheme("Campbell Scheme", color_defs.Schemes.Campbell, null, wallpapers.abstract_blue)),
    'UbuntuScheme.ini': std.manifestIni(konsole_schemes.KonsoleColorScheme("Ubuntu Scheme", color_defs.Schemes.Ubuntu, null, wallpapers.abstract_purple_blue)),
    'GCloudScheme.ini': std.manifestIni(konsole_schemes.KonsoleColorScheme("GCloud Scheme", color_defs.Schemes.GCloud, null, wallpapers.android_colorful)),
}

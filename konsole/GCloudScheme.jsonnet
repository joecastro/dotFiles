local konsole_schemes = import './KonsoleColorSchemes.libsonnet';
local color_defs = import '../shell/color_definitions.libsonnet';
local wallpapers = import '../wallpaper/wallpapers.jsonnet';

local konsoleScheme = konsole_schemes.KonsoleColorScheme("GCloud", color_defs.Schemes.GCloud, null, wallpapers.android_colorful);

std.manifestIni(konsoleScheme)
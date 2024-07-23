local konsole_schemes = import './KonsoleColorSchemes.libsonnet';
local color_defs = import '../shell/color_definitions.libsonnet';
local wallpapers = import '../wallpaper/wallpapers.jsonnet';

local konsoleScheme = konsole_schemes.KonsoleColorScheme("Campbell Scheme", color_defs.Schemes.Campbell, null, wallpapers.abstract_blue);

std.manifestIni(konsoleScheme)

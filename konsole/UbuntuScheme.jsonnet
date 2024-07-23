local konsole_schemes = import './KonsoleColorSchemes.libsonnet';
local color_defs = import '../shell/color_definitions.libsonnet';
local wallpapers = import '../wallpaper/wallpapers.jsonnet';

local konsoleScheme = konsole_schemes.KonsoleColorScheme("Ubuntu Scheme", color_defs.Schemes.Ubuntu, null, wallpapers.abstract_purple_blue);

std.manifestIni(konsoleScheme)

// jsonnet -S -m ~/.local/share/konsole MultiScheme.jsonnet -V cwd=$PWD
local konsole_schemes = import './KonsoleColorSchemes.libsonnet';
local color_defs = import '../shell/color_definitions.libsonnet';
local wallpapers = import '../wallpaper/wallpapers.jsonnet';

{
    [l.key + '.colorscheme']: std.manifestIni(konsole_schemes.KonsoleColorScheme(l.key, l.value, null, wallpapers.abstract_blue))
    for l in std.objectKeysValues(color_defs.Schemes)
}

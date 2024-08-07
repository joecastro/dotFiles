// jsonnet -S -m ~/.local/share/konsole MultiConfigs.jsonnet -V cwd=$PWD
local konsole_configs = import './KonsoleConfigs.libsonnet';
local color_defs = import '../shell/color_definitions.libsonnet';
local wallpapers = import '../wallpaper/wallpapers.jsonnet';

local kolor_schemes = [
    konsole_configs.KonsoleColorSchemeIni(l.key, l.value, wallpapers.abstract_blue.local_path)
    for l in std.objectKeysValues(color_defs.Schemes)
];

local outputs = [
    konsole_configs.KonsoleProfileIni('GLinux', null, 'Tango Dark', null),
    konsole_configs.KonsoleColorSchemeIni('Tango Dark', color_defs.Schemes['Tango Dark'], wallpapers.android_colorful.local_path),
] + kolor_schemes;

{ [o.filename]: std.manifestIni(o) for o in outputs }

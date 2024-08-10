// jsonnet -S -m ~/.local/share/konsole MultiConfigs.jsonnet -V cwd=$PWD
local konsole_configs = import './KonsoleConfigs.libsonnet';
local color_defs = import '../shell/color_definitions.libsonnet';
local wallpapers = import '../wallpaper/wallpapers.jsonnet';
local apply_configs = import '../apply_configs.jsonnet';

local host = apply_configs.host;

local glinux = konsole_configs.KonsoleProfileWithColorscheme(
    host.hostname,
    color_defs.Schemes['Tango Dark'],
    wallpapers.icons.tux.target_path(host),
    wallpapers.abstract_blue.target_path(host));

local quake = konsole_configs.KonsoleProfileWithColorscheme(
    'Quake',
    color_defs.Schemes['Red Sands'],
    wallpapers.icons.quake.target_path(host),
    wallpapers.quake.target_path(host));

local outputs =
    konsole_configs.GenerateColorSchemesWithWallpaper(
        '',
        wallpapers.android_colorful.target_path(null)) +
    std.objectValues(glinux) +
    std.objectValues(quake);

{ [o.filename]: std.manifestIni(o) for o in outputs }

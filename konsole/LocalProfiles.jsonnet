local konsole_configs = import './KonsoleConfigs.libsonnet';
local color_defs = import '../shell/color_definitions.libsonnet';
local wallpapers = import '../wallpaper/wallpapers.jsonnet';
local apply_configs = import '../apply_configs.jsonnet';

local host = apply_configs.host;

local glinux = konsole_configs.KonsoleProfileWithColorscheme(
    host.hostname,
    color_defs.Schemes['Tango Dark'],
    host.icon.target_path(host),
    host.primary_wallpaper.target_path(host));

local quake = konsole_configs.KonsoleProfileWithColorscheme(
    'Quake',
    color_defs.Schemes['Red Sands'],
    wallpapers.icons.quake.target_path(host),
    wallpapers.quake.target_path(host));

{ [o.filename]: std.manifestIni(o) for o in (std.objectValues(glinux) + std.objectValues(quake)) }

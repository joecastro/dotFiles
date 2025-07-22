// jsonnet -S -m ~/.local/share/konsole MultiConfigs.jsonnet -V cwd=$PWD
local konsole_configs = import './KonsoleConfigs.libsonnet';
local color_defs = import '../shell/color_definitions.libsonnet';
local wallpapers = import '../wallpaper/wallpapers.jsonnet';
local apply_configs = import '../apply_configs.jsonnet';

local host = apply_configs.host;

{ [o.filename]: std.manifestIni(o)
    for o in konsole_configs.GenerateColorSchemesWithWallpaper(
        '',
        host.primary_wallpaper.target_path(host)) }

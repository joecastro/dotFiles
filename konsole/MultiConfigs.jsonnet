// jsonnet -S -m ~/.local/share/konsole MultiConfigs.jsonnet -V cwd=$PWD
local konsole_configs = import './KonsoleConfigs.libsonnet';
local color_defs = import '../shell/color_definitions.libsonnet';
local wallpapers = import '../wallpaper/wallpapers.jsonnet';
local apply_configs_core = import '../apply_configs_core.jsonnet';

local glinux = konsole_configs.KonsoleProfileWithColorscheme(
    std.extVar('hostname'),
    color_defs.Schemes['Tango Dark'],
    std.extVar('home') + '/' + apply_configs_core.svg_paths.tux_simple,
    std.extVar('cwd') + '/' + wallpapers.abstract_blue.local_path);

local quake = konsole_configs.KonsoleProfileWithColorscheme(
    'Quake',
    color_defs.Schemes['Red Sands'],
    std.extVar('home') + '/' + apply_configs_core.svg_paths.quake,
    std.extVar('cwd') + '/' + wallpapers.quake.local_path);

local outputs =
    konsole_configs.GenerateColorSchemesWithWallpaper(
        '',
        std.extVar('cwd') + '/' + wallpapers.android_colorful.local_path) +
    std.objectValues(glinux) +
    std.objectValues(quake);

{ [o.filename]: std.manifestIni(o) for o in outputs }

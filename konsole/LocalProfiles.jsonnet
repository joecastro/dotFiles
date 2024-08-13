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

local android = konsole_configs.KonsoleProfileWithColorscheme(
    'Android',
    color_defs.Schemes['Solarized Dark'],
    wallpapers.icons.android.target_path(null),
    host.android_wallpaper.target_path(null),
    null,
    if std.objectHas(host.env_vars.properties, 'ANDROID_REPO_ROOT') then host.env_vars.properties.ANDROID_REPO_ROOT);

local localhost_only_profiles = [
    konsole_configs.KonsoleProfileWithColorscheme(
        'Bash',
        color_defs.Schemes.Gruvbox,
        wallpapers.icons.tux.target_path(null),
        wallpapers.abstract_pastel.target_path(null),
        '/usr/bin/bash'),
    konsole_configs.KonsoleProfileWithColorscheme(
        'Quake',
        color_defs.Schemes['Red Sands'],
        wallpapers.icons.quake.target_path(host),
        wallpapers.quake.target_path(host))
];

local profile_pairs = (if host.is_localhost then localhost_only_profiles else []) + [glinux, android];
local entries = std.flattenArrays([[o.profile, o.colorscheme] for o in profile_pairs]);

{ [o.filename]: std.manifestIni(o) for o in entries }

local konsole_configs = import './KonsoleConfigs.libsonnet';
local color_defs = import '../shell/color_definitions.libsonnet';
local wallpapers = import '../wallpaper/wallpapers.jsonnet';
local apply_configs = import '../apply_configs.jsonnet';

local host = apply_configs.host;

local bash_profile = konsole_configs.KonsoleProfileWithColorscheme(
    'Bash',
    color_defs.Schemes.Gruvbox,
    wallpapers.icons.tux.target_path(host),
    wallpapers.abstract_pastel.target_path(host),
    '/usr/bin/bash');

local zsh_profile = konsole_configs.KonsoleProfileWithColorscheme(
    'Zsh',
    color_defs.Schemes['Tango Dark'],
    host.icon.target_path(host),
    host.primary_wallpaper.target_path(host),
    '/usr/bin/zsh',);

local quake_profile = konsole_configs.KonsoleProfileWithColorscheme(
    'Quake',
    color_defs.Schemes['Red Sands'],
    wallpapers.icons.quake.target_path(host),
    wallpapers.quake.target_path(host));

local optional_android_profiles = if std.objectHas(host.env_vars.properties, 'ANDROID_REPO_ROOT') then
    [
        konsole_configs.KonsoleProfileWithColorscheme(
            'Android',
            color_defs.Schemes['Solarized Dark'],
            wallpapers.icons.android.target_path(host),
            host.android_wallpaper.target_path(host),
            null,
            host.env_vars.properties.ANDROID_REPO_ROOT)
    ] else [];

{
    [o.filename]: std.manifestIni(o) for o in std.flattenArrays(
        [[o.profile, o.colorscheme]
        for o in [
            bash_profile,
            zsh_profile,
            quake_profile,
        ] + optional_android_profiles
    ])
}

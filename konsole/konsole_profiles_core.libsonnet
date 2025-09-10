local konsole_configs = import './konsole_definitions.libsonnet';
local color_defs = import '../shell/color_definitions.libsonnet';
local wallpapers = import '../wallpaper/wallpaper.libsonnet';
local apply_configs = import '../apply_configs.jsonnet';

local host = apply_configs.host;

local localhost_profile = konsole_configs.KonsoleProfileWithColorscheme(
    host.hostname,
    color_defs.Schemes['Darkside'],
    host.icon.target_path(host),
    host.primary_wallpaper.target_path(host));

local bash_profile = konsole_configs.KonsoleProfileWithColorscheme(
    'Bash',
    color_defs.Schemes.Gruvbox,
    wallpapers.icons.bash.target_path(host),
    wallpapers.backgrounds.abstract_pastel.target_path(host),
    '/usr/bin/bash');

local zsh_profile = konsole_configs.KonsoleProfileWithColorscheme(
    'Zsh',
    color_defs.Schemes['Tango Dark'],
    wallpapers.icons.zsh.target_path(host),
    host.primary_wallpaper.target_path(host),
    '/usr/bin/zsh',);

local quake_profile = konsole_configs.KonsoleProfileWithColorscheme(
    'Quake',
    color_defs.Schemes['Red Sands'],
    wallpapers.icons.quake.target_path(host),
    wallpapers.backgrounds.quake.target_path(host));

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

[
    bash_profile,
    zsh_profile,
    quake_profile,
    localhost_profile,
] + optional_android_profiles

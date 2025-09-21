local color_defs = import './shell/color_definitions.libsonnet';
local apply_configs_core = import './apply_configs_core.jsonnet';
local wallpapers = import './wallpaper/wallpaper.libsonnet';

local ext_vars = apply_configs_core.ext_vars;

local localhost_hostname = if ext_vars.is_localhost then ext_vars.hostname else null;

local hostname_colors = {
    Silver: color_defs.Colors.Silver,
    Rocinante: color_defs.Colors.RoofTerracotta,
};

local localhost_color = if std.objectHas(hostname_colors, localhost_hostname)
    then hostname_colors[localhost_hostname]
    else color_defs.Colors.YellowSea;

local localhost = apply_configs_core.Host(
    null, // hostname
    null, // home
    wallpapers.icons.tux,
    localhost_color,
    wallpapers.backgrounds.abstract_blue,
    wallpapers.android_backgrounds.backpack
);

local docker_host = apply_configs_core.Host(
    'docker-host', // hostname
    '/home/docker', // home
    wallpapers.icons.bash,
    color_defs.Colors.CornflowerBlue,
    wallpapers.backgrounds.abstract_purple_blue,
    wallpapers.android_backgrounds.umbrella
) + {
    stage_only: true,
};

local hosts = [
    localhost,
    docker_host,
];

local active_host = if ext_vars.is_localhost then localhost
    else std.filter(function(h) h.hostname == ext_vars.hostname, hosts)[0];

{
    vim_pack_plugin_opt_repos: apply_configs_core.vim_pack_plugin_opt_repos,
    vim_pack_plugin_start_repos: apply_configs_core.vim_pack_plugin_start_repos,
    zsh_plugin_repos: apply_configs_core.zsh_plugin_repos,
    workspace_overrides: null,
    hosts: hosts,
    host:: active_host
}

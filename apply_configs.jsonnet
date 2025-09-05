local color_defs = import './shell/color_definitions.libsonnet';
local apply_configs_core = import './apply_configs_core.jsonnet';
local wallpapers = import './wallpaper/wallpaper.libsonnet';

local localhost_hostname = apply_configs_core.ext_vars.hostname;

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

{
    vim_pack_plugin_opt_repos: apply_configs_core.vim_pack_plugin_opt_repos,
    vim_pack_plugin_start_repos: apply_configs_core.vim_pack_plugin_start_repos,
    zsh_plugin_repos: apply_configs_core.zsh_plugin_repos,

    workspace_overrides: null,
    hosts: [
        localhost,
    ],
    host:: $.hosts[0],
}

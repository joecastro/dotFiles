local color_defs = import './shell/color_definitions.libsonnet';
local apply_configs_core = import './apply_configs_core.jsonnet';
local wallpapers = import './wallpaper/wallpapers.jsonnet';

{
    vim_pack_plugin_opt_repos: apply_configs_core.vim_pack_plugin_opt_repos,
    vim_pack_plugin_start_repos: apply_configs_core.vim_pack_plugin_start_repos,
    zsh_plugin_repos: apply_configs_core.zsh_plugin_repos,

    workspace_overrides: null,
    host:: apply_configs_core.Host(null, null, wallpapers.icons.tux, color_defs.Colors.YellowSea, wallpapers.abstract_blue, wallpapers.android_backpack),
    hosts: [
        $.host
    ],
}

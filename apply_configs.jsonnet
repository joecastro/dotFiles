local color_defs = import './shell/color_definitions.libsonnet';
local apply_configs_core = import './apply_configs_core.jsonnet';
{
    vim_pack_plugin_opt_repos: apply_configs_core.vim_pack_plugin_opt_repos,
    vim_pack_plugin_start_repos: apply_configs_core.vim_pack_plugin_start_repos,
    zsh_plugin_repos: apply_configs_core.zsh_plugin_repos,

    workspace_overrides: null,
    localhost:: {
        home: std.extVar('home'),
        hostname: std.extVar('hostname'),
        color: color_defs.Colors.YellowSea,
        jsonnet_maps: apply_configs_core.jsonnet_maps,
        jsonnet_multi_maps: apply_configs_core.jsonnet_multi_maps,
        config_dir: apply_configs_core.config_dir,
        file_maps: apply_configs_core.file_maps,
        directory_maps: apply_configs_core.directory_maps,
        curl_maps: apply_configs_core.curl_maps,
        macros: apply_configs_core.macros,
    },
    active_host:: $.localhost,
    hosts: [
        $.localhost
    ],
}

local apply_configs_core = import './apply_configs_core.jsonnet';
{
    vim_pack_plugin_opt_repos: apply_configs_core.vim_pack_plugin_opt_repos,
    vim_pack_plugin_start_repos: apply_configs_core.vim_pack_plugin_start_repos,
    zsh_plugin_repos: apply_configs_core.zsh_plugin_repos,

    config_root: std.extVar('home') + '/' + apply_configs_core.config_dir,
    workspace_overrides: null,
    hosts: [
        {
            hostname: 'localhost',
            jsonnet_maps: apply_configs_core.jsonnet_maps,
            file_maps: apply_configs_core.file_maps,
            macros: apply_configs_core.macros,
        }
    ],
}

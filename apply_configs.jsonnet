local apply_configs_core = import './apply_configs_core.jsonnet';
apply_configs_core + {
    file_maps:: null,
    jsonnet_maps:: null,
    macros:: null,
    workspace: apply_configs_core.workspace,
    hosts: [
        {
            hostname: std.extVar('hostname'),
            jsonnet_maps: apply_configs_core.jsonnet_maps,
            file_maps: apply_configs_core.file_maps,
            macros: apply_configs_core.macros,
        }
    ],
}
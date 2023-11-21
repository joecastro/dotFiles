local sh = import './manifestShellVars.libsonnet';
local apply_configs_core = import '../apply_configs_core.jsonnet';
sh.manifestShellVars({
    DOTFILES_SRC_HOME: std.extVar('cwd'),
    DOTFILES_CONFIG_ROOT: '$HOME/' + apply_configs_core.config_dir,
    ACTIVE_SHELL: "`ps -c -p $$ -o command | awk 'END{print}'`",
})

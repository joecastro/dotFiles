local zsh = import './manifestZshVars.libsonnet';
local apply_configs_core = import './apply_configs_core.jsonnet';
zsh.manifestZshVars({
    DOTFILES_SRC_HOME: std.extVar('cwd'),
    DOTFILES_CONFIG_ROOT: '$HOME/' + apply_configs_core.config_dir,
})

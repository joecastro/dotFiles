local sh = import './manifestShellVars.libsonnet';
local apply_configs_core = import '../apply_configs_core.jsonnet';
local root = {
    properties: {
        DOTFILES_SRC_HOME: std.extVar('cwd'),
        DOTFILES_CONFIG_ROOT: '$HOME/' + apply_configs_core.config_dir,
        ANDROID_HOME: if std.extVar('kernel') == 'darwin' then '~/Library/Android/sdk' else '$HOME/android_sdk',
    },
    directives: {
        ACTIVE_SHELL: "ps -c -p $$ -o command | awk 'END{print}'",
    },
    aliases: {
        dotGo: 'pushd $DOTFILES_SRC_HOME; cd .'
    }
};
sh.manifestShellVars(root)
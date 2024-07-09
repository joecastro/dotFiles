local sh = import './manifestShellVars.libsonnet';
local apply_configs_core = import '../apply_configs_core.jsonnet';
local root = {
    properties: {
        DOTFILES_SRC_HOME: std.extVar('cwd'),
        DOTFILES_CONFIG_ROOT: '$HOME/' + apply_configs_core.config_dir,
        ANDROID_HOME: if std.extVar('kernel') == 'darwin' then '~/Library/Android/sdk' else '$HOME/android_sdk',
        LS_COLORS: "di=1;36:ln=1;33:so=31:pi=37;41:ex=32:bd=34;46:cd=34;43:su=30;41:sg=30;46:tw=30;42:ow=30;43",
        LSCOLORS: "GxDxbxhbcxegedabagacad",
    },
    // directives: {
    //     ACTIVE_SHELL: "ps -c -p $$ -o command | awk 'END{print}'",
    // },
    aliases: {
        dotGo: 'pushd $DOTFILES_SRC_HOME; cd .'
    }
};
sh.manifestShellVars(root)
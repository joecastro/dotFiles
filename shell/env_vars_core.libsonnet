local apply_configs = import '../apply_configs.jsonnet';
{
    properties:: {
        # Note that Tmux supports hex colors, but only if they're encoded lowercase
        [if apply_configs.active_host.color != null then 'HOST_COLOR']: apply_configs.active_host.color.hexcolor,
        DOTFILES_CONFIG_ROOT: '$HOME/' + apply_configs.active_host.config_dir,
        ANDROID_HOME: if std.extVar('kernel') == 'darwin' && std.extVar('is_localhost') == 'true' then '~/Library/Android/sdk' else '$HOME/android_sdk',
        LSCOLORS: 'GxDxbxhbcxegedabagacad',
        LS_COLORS: 'di=1;36:ln=1;33:so=31:pi=37;41:ex=32:bd=34;46:cd=34;43:su=30;41:sg=30;46:tw=30;42:ow=30;43',
    },
    localhost_properties:: {
        DOTFILES_SRC_HOME: std.extVar('cwd'),
    },
    aliases:: {},
    localhost_aliases:: {
        dotGo: 'pushd $DOTFILES_SRC_HOME'
    },
    directives:: {},
    localhost_directives:: {},
}

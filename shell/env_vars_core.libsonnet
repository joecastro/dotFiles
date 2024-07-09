local apply_configs_core = import '../apply_configs_core.jsonnet';
{
    properties:: {
        # Note that Tmux supports hex colors, but only if they're encoded lowercase
        [if std.extVar('color') != 'default' then 'HOST_COLOR']: std.asciiLower(std.extVar('color')),
        DOTFILES_CONFIG_ROOT: '$HOME/' + apply_configs_core.config_dir,
        ANDROID_REPO_BRANCH: std.extVar('branch'),
        ANDROID_REPO_ROOT: '$HOME/$ANDROID_REPO_BRANCH',
        ANDROID_HOME: if std.extVar('kernel') == 'darwin' then '~/Library/Android/sdk' else '$HOME/android_sdk',
        LSCOLORS: 'GxDxbxhbcxegedabagacad',
        LS_COLORS: 'di=1;36:ln=1;33:so=31:pi=37;41:ex=32:bd=34;46:cd=34;43:su=30;41:sg=30;46:tw=30;42:ow=30;43',
    },
    localhost_properties:: {
        DOTFILES_SRC_HOME: std.extVar('cwd'),

    },
    aliases:: {},
    localhost_aliases:: {
        dotGo: 'pushd $DOTFILES_SRC_HOME; cd .'
    },
    directives:: {},
    localhost_directives:: {},
}

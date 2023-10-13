local zsh = import 'manifestZshVars.libsonnet';
zsh.manifestZshVars({
    DOTFILES_SRC_HOME: std.extVar('cwd'),
})

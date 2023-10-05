local apply_configs_core = import './apply_configs_core.jsonnet';
apply_configs_core + {
    file_maps:: null,
    jsonnet_maps:: null,
    hosts: [
        {
            'hostname': std.extVar('hostname'),
            'zshenv_sub': [
                "DOTFILES_SRC_HOME=" + std.extVar("cwd"),
                "alias dotGo='pushd $DOTFILES_SRC_HOME'",
                "",
                "ANDROID_REPO_BRANCH=main",
                "ANDROID_REPO_ROOT=" + std.extVar("home") + "/source/android"
            ],
            jsonnet_maps: apply_configs_core.jsonnet_maps,
            file_maps: apply_configs_core.file_maps,
        }
    ],
}
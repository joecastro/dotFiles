local apply_configs_core = import './apply_configs_core.jsonnet';
local file_maps_exclude_prefixes = ['bash/', 'konsole/', 'verify_fonts.py'];
local filter_file_maps = function(x) !std.any(std.map(function(exclude) std.startsWith(x[0], exclude), file_maps_exclude_prefixes));
apply_configs_core + {
    file_maps:: null,
    hosts: [
        {
            'hostname': std.extVar('hostname'),
            'zshenv_sub': [
                "DOTFILES_SRC_HOME=" + std.extVar("cwd"),
                "alias dotGo='pushd $DOTFILES_SRC_HOME'",
                "",
                "ANDROID_REPO_BRANCH=main",
                "ANDROID_REPO_PATH=" + std.extVar("home") + "/source/android"
            ],
            file_maps: std.filter(filter_file_maps, apply_configs_core.file_maps),
        }
    ],
}
// jsonnet -S -m ~/.local/share/konsole MultiConfigs.jsonnet -V cwd=$PWD
local konsole_defs = import './konsole_definitions.libsonnet';
local konsole_profiles_core = import './konsole_profiles_core.libsonnet';
local apply_configs = import '../apply_configs.jsonnet';

local host = apply_configs.host;

{
    [o.filename]: std.manifestIni(o)
        for o in konsole_defs.GenerateColorSchemesWithWallpaper(
            '',
            host.primary_wallpaper.target_path(host))
} + {
    [o.filename]: std.manifestIni(o)
        for o in std.flattenArrays([[o.profile, o.colorscheme] for o in konsole_profiles_core])
}

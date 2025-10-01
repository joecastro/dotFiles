local apply_configs_core = import '../apply_configs_core.jsonnet';
local iterm = import './iterm_core.libsonnet';
local color_defs = import '../shell/color_definitions.libsonnet';
local wallpaper = import '../wallpaper/wallpaper.libsonnet';

local ec2_hostname = apply_configs_core.ext_vars.ec2_workstation_hostname;

local guids = iterm.guids;

local hostname_triggers = [
    iterm.ItermProfileTrigger("^(\\w+)@([\\w.-]+)", "SetHostnameTrigger", "\\1@\\2", true)
];

local ec2_workstation_profile = if ec2_hostname != ''
    then iterm.ItermProfile("EC2 Workstation", color_defs.Colors.White, guids[0], wallpaper.backgrounds.abstract_orange) +
    {
        "Bound Hosts": [
            ec2_hostname,
        ],
        "Title Components": 256,
        Triggers: hostname_triggers,
    } else null;

{
    Profiles: [
        iterm.Profiles.HomebrewZsh,
        iterm.Profiles.HomebrewBash,
        iterm.Profiles.NativeOldBash,
        iterm.Profiles.GuakeWindow,
    ] + (if ec2_workstation_profile != null then [ec2_workstation_profile] else []),

    WindowArrangements: [],

    DefaultProfile: $.Profiles[0],

    CustomColorPresets: {
        [scheme.key]: iterm.ITermColorPreset(scheme.key, scheme.value, color_defs.Schemes.ITerm.terminal_colors)
        for scheme in std.objectKeysValues(color_defs.Schemes)
    },

    DefaultArrangement:: {
        Name:: "",
    }

}

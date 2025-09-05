local iterm = import './iterm_core.libsonnet';
local color_defs = import '../shell/color_definitions.libsonnet';

{
    Profiles: [
        iterm.Profiles.HomebrewZsh,
        iterm.Profiles.HomebrewBash,
        iterm.Profiles.GuakeWindow,
    ],

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
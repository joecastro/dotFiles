local iterm = import './iterm_core.libsonnet';
local color_defs = import '../terminals/color_definitions.libsonnet';

{
    Profiles: [
        iterm.Profiles.ZshTheHardWay,
        iterm.Profiles.BashTheOldWay,
        iterm.Profiles.HotkeyWindow,
    ],

    WindowArrangements: [],

    DefaultProfile: iterm.Profiles.ZshTheHardWay,

    CustomColorPresets: {
        [scheme.key]: iterm.ITermColorPreset(scheme.key, scheme.value, iterm.DefaultExtendedTerminalColors)
        for scheme in std.objectKeysValues(color_defs.Schemes)
    },

    DefaultArrangement:: {
        Name:: "",
    }

}
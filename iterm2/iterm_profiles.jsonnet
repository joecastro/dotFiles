local iterm = import './iterm_core.libsonnet';
{
    Profiles: [
        iterm.Profiles.ZshTheHardWay,
        iterm.Profiles.BashTheOldWay,
        iterm.Profiles.HotkeyWindow,
    ],

    WindowArrangements: [],

    DefaultProfile: iterm.Profiles.ZshTheHardWay,

    DefaultArrangement:: {
        Name:: "",
    }

}
local apply_configs_core = import '../apply_configs_core.jsonnet';
local iterm = import './iterm_core.libsonnet';
local color_defs = import '../shell/color_definitions.libsonnet';
local wallpaper = import '../wallpaper/wallpaper.libsonnet';

local ec2_hostname = apply_configs_core.ext_vars.ec2_workstation_hostname;
local home = apply_configs_core.ext_vars.home;

local guids = iterm.guids;

local ItermColor(color) = {
    "Red Component": std.toString(color.red),
    "Green Component": std.toString(color.green),
    "Blue Component": std.toString(color.blue),
};

local DolbyProfile(name, guid, directory, dimmer_color, accent_color, background=wallpaper.backgrounds.dolby) =
    iterm.ItermProfile(name, accent_color, guid, background, wallpaper.icons.dolby) + {
        "Bound Hosts": [
            directory,
            directory + "/*",
        ],
        "Background Color": ItermColor(dimmer_color),
        "Tab Color": ItermColor(accent_color),
        "Use Tab Color": true,
    };

local dolby_profiles = [
    DolbyProfile(
        "Dolby — Chassis",
        guids[1],
        home + "/source/Chassis",
        color_defs.ColorFromHex("#5a0638"),
        color_defs.ColorFromHex("#ff2d95"),
    ),
    DolbyProfile(
        "Dolby — Chassis2",
        guids[2],
        home + "/source/Chassis2",
        color_defs.ColorFromHex("#062d78"),
        color_defs.ColorFromHex("#2878ff"),
    ),
    DolbyProfile(
        "Dolby — Chassis3",
        guids[4],
        home + "/source/Chassis3",
        color_defs.ColorFromHex("#6b2800"),
        color_defs.ColorFromHex("#ff8a1f"),
    ),
    DolbyProfile(
        "Dolby — LQChassis",
        guids[3],
        home + "/source/LQChassis",
        color_defs.ColorFromHex("#075c46"),
        color_defs.ColorFromHex("#16d6a0"),
    ),
    DolbyProfile(
        "Dolby — Site Gallery",
        guids[5],
        home + "/source/site-gallery",
        color_defs.ColorFromHex("#3d174f"),
        color_defs.ColorFromHex("#c269e8"),
        wallpaper.backgrounds.dolby_landscape,
    ),
];

local hostname_triggers = [
    iterm.ItermProfileTrigger("^(\\w+)@([\\w.-]+)", "SetHostnameTrigger", "\\1@\\2", true)
];

local ec2_workstation_profile = if ec2_hostname != ''
    then iterm.ItermProfile("EC2 Workstation", color_defs.Colors.White, guids[0], wallpaper.backgrounds.abstract_orange, wallpaper.icons.tux) +
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
    ] + dolby_profiles + (if ec2_workstation_profile != null then [ec2_workstation_profile] else []),

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

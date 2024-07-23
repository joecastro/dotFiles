local color_defs = import '../shell/color_definitions.libsonnet';

// conf load /org/gnome/shell/extensions/dash-to-panel/ < ./dash_settings2.ini
local manifestDconfIni(ini) =
    local body_lines(body) =
        std.join([], [
            local value_or_values = body[k];
            if std.isArray(value_or_values) then
                ['%s=%s' % [k, value_or_values]]
            else if std.isBoolean(value_or_values) || std.isNumber(value_or_values) then
                ['%s=%s' % [k, value_or_values]]
            else if std.isString(value_or_values) then
                ["%s='%s'" % [k, std.toString(value_or_values)]]
            else
                ["%s=%s" % [k, std.toString(value_or_values)]]
        for k in std.objectFields(body)
    ]);

    local section_lines(sname, sbody) = ['[%s]' % [sname]] + body_lines(sbody),
        main_body = if std.objectHas(ini, 'main') then body_lines(ini.main) else [],
        all_sections = [section_lines(k, ini.sections[k])
            for k in std.objectFields(ini.sections)];
    std.join('\n', main_body + std.flattenArrays(all_sections) + ['']);

manifestDconfIni({
    'sections': {
        'org/gnome/desktop/peripherals/mouse': {
            'left-handed': true,
            'natural-scroll': false,
            'speed': 0.4
        },
        'org/gnome/desktop/interface': {
            'clock-show-date': true,
            'clock-show-seconds': false,
            'clock-show-weekday': false,
            'clock-format': '12h',
            'font-name': 'Noto Sans 14',
            'gtk-theme': 'Adwaita',
            'locate-pointer': true,
            'monospace-font-name': 'JetBrains Mono Nerd Font Mono 14',
            'text-scaling-factor': 1.0
        },
        'org/gnome/shell/extensions/dash-to-panel': {
            'animate-appicon-hover-animation-extent': {'RIPPLE': 4, 'PLANK': 4, 'SIMPLE': 1},
            'appicon-margin': 8,
            'appicon-padding': 4,
            'available-monitors': [0],
            'dot-position': 'BOTTOM',
            'dot-style-focused': 'METRO',
            'dot-style-unfocused': 'METRO',
            'hide-overview-on-startup': true,
            'hotkeys-overlay-combo': 'TEMPORARILY',
            'leftbox-padding': -1,
            'panel-anchors': std.toString({"0":"MIDDLE"}),
            'panel-element-positions': std.toString(
                {
                    "0": [
                        {
                            "element":"showAppsButton",
                            "visible":true,
                            "position":"stackedTL"
                        },
                        {
                            "element": "activitiesButton",
                            "visible":false,
                            "position":"stackedTL"
                        },
                        {
                            "element":"leftBox",
                            "visible":true,
                            "position":"stackedTL"
                        },
                        {
                            "element":"taskbar",
                            "visible":true,
                            "position":"stackedTL"
                        },
                        {
                            "element":"centerBox",
                            "visible":true,
                            "position":"stackedBR"
                        },
                        {
                            "element":"rightBox",
                            "visible":true,
                            "position":"stackedBR"
                        },
                        {
                            "element":"dateMenu",
                            "visible":true,
                            "position":"stackedBR"
                        },
                        {
                            "element":"systemMenu",
                            "visible":true,
                            "position":"stackedBR"
                        },
                        {
                            "element":"desktopButton",
                            "visible":true,
                            "position":"stackedBR"}]
                        }),
            'panel-lengths': std.toString({"0": 40}),
            'panel-positions': std.toString({'0': 'BOTTOM'}),
            'panel-sizes': std.toString({"0": 64}),
            'primary-monitor': 0,
            'show-appmenu': false,
            'show-apps-icon-file': '',
            'status-icon-padding': -1,
            'stockgs-keep-top-panel': false,
            'trans-bg-color': color_defs.Colors.RoofTerracotta,
            'trans-gradient-bottom-color': color_defs.Colors.Cardinal,
            'trans-gradient-bottom-opacity': 0.6,
            'trans-gradient-top-color': color_defs.Colors.Carnation,
            'trans-gradient-top-opacity': 0.1,
            'trans-panel-opacity': 0.1,
            'trans-use-custom-bg': true,
            'trans-use-custom-gradient': true,
            'trans-use-custom-opacity': true,
            'trans-use-dynamic-opacity': true,
            'tray-padding': -1,
            'window-preview-title-position': 'TOP',
        }
    }
})
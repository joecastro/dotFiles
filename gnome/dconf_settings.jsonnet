local color_defs = import '../shell/color_definitions.libsonnet';

local mouse_settings = {
    'left-handed': true,
    'natural-scroll': false,
    'speed': 0.4
};

local touchpad_settings = {
    'two-finger-scrolling-enabled': true
};

local desktop_accessibility_settings = {
    'always-show-universal-access-status': false,
};

local desktop_calendar_settings = {
    'show-weekdate': true
};

local desktop_datetime_settings = {
    'automatic-timezone': true,
};

local desktop_wm_preferences = {
    'button-layout': 'appmenu:minimize,maximize,close'
};

local desktop_interface_settings = {
    'clock-format': '12h',
    'clock-show-date': true,
    'clock-show-seconds': false,
    'clock-show-weekday': false,
    'enable-hot-corners': true,
    'font-name': 'Noto Sans 14',
    'gtk-theme': 'Adwaita',
    'locate-pointer': true,
    'monospace-font-name': 'JetBrains Mono Nerd Font Mono 14',
    'text-scaling-factor': 1.0
};

local shell_settings = {
    'favorite-apps': ['org.kde.konsole.desktop', 'google-chrome.desktop', 'org.gnome.Nautilus.desktop']
};

local background_settings(wallpaper_path, dark_wallpaper_path=null) = {
    'picture-uri': 'file://' + wallpaper_path,
    [if dark_wallpaper_path != null then 'picture-uri-dark' ]: 'file://"$HOME"/' + dark_wallpaper_path,
};

local dash_to_panel_settings = {
    LeftElement(element, visible=true):: {
        'element': element,
        'visible': visible,
        'position': 'stackedTL'
    },
    RightElement(element, visible=true):: {
        'element': element,
        'visible': visible,
        'position': 'stackedBR'
    },
    'animate-appicon-hover': true,
    'animate-appicon-hover-animation-type': 'SIMPLE',
    'appicon-margin': 8,
    'appicon-padding': 4,
    'available-monitors': [0],
    'dot-position': 'BOTTOM',
    'dot-style-focused': 'METRO',
    'dot-style-unfocused': 'METRO',
    'hide-overview-on-startup': true,
    'hotkeys-overlay-combo': 'TEMPORARILY',
    'intellihide-key-toggle': ['<Super>i'],
    'leftbox-padding': -1,
    'overview-click-to-exit': true,
    'panel-anchors': std.toString({"0":"MIDDLE"}),
    'panel-element-positions': std.toString({
        "0": [
            $.LeftElement("showAppsButton"),
            $.LeftElement("activitiesButton", false),
            $.LeftElement("leftBox"),
            $.LeftElement("taskbar"),
            $.RightElement("centerBox"),
            $.RightElement("rightBox"),
            $.RightElement("dateMenu"),
            $.RightElement("systemMenu"),
            $.RightElement("desktopButton")]}),
    'panel-lengths': std.toString({"0": 50}),
    'panel-positions': std.toString({'0': 'BOTTOM'}),
    'panel-sizes': std.toString({"0": 64}),
    'primary-monitor': 0,
    'shift-click-action': 'MINIMIZE',
    'shift-middle-click-action': 'LAUNCH',
    'shortcut': ['<Super>q'],
    'show-appmenu': false,
    'show-apps-icon-file': '',
    'status-icon-padding': -1,
    'stockgs-force-hotcorner': false,
    'stockgs-keep-dash': false,
    'stockgs-keep-top-panel': false,
    'trans-bg-color': color_defs.Colors.RoofTerracotta.hexcolor,
    'trans-gradient-bottom-color': color_defs.Colors.Cardinal.hexcolor,
    'trans-gradient-bottom-opacity': 0.6,
    'trans-gradient-top-color': color_defs.Colors.Carnation.hexcolor,
    'trans-gradient-top-opacity': 0.1,
    'trans-panel-opacity': 0.1,
    'trans-use-custom-bg': true,
    'trans-use-custom-gradient': true,
    'trans-use-custom-opacity': true,
    'trans-use-dynamic-opacity': true,
    'tray-padding': -1,
    'window-preview-title-position': 'TOP',
};

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
                ["%s=%s" % [k, std.strReplace(std.toString(value_or_values), '"', "'")]]
        for k in std.objectFields(body)
    ]) + [''];

    local section_lines(sname, sbody) = ['[%s]' % [sname]] + body_lines(sbody),
        all_sections = [section_lines(k, ini[k]) for k in std.objectFields(ini)];
    std.join('\n', std.flattenArrays(all_sections));

manifestDconfIni({
    'org/gnome/desktop/a11y': desktop_accessibility_settings,
    'org/gnome/desktop/calendar': desktop_calendar_settings,
    'org/gnome/desktop/datetime': desktop_datetime_settings,
    'org/gnome/desktop/interface': desktop_interface_settings,
    'org/gnome/desktop/peripherals/mouse': mouse_settings,
    'org/gnome/desktop/peripherals/touchpad': touchpad_settings,
    'org/gnome/desktop/wm/preferences': desktop_wm_preferences,
    'org/gnome/shell': shell_settings,
    'org/gnome/shell/desktop/background': background_settings('/usr/share/backgrounds/gnome/fold-l.jpg'),
    'org/gnome/shell/extensions/dash-to-panel': dash_to_panel_settings,
})

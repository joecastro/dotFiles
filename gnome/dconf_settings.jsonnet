local color_defs = import '../shell/color_definitions.libsonnet';

local mouse_settings = {
    'left-handed': true,
    'natural-scroll': false,
    'speed': 0.4
};

local touchpad_settings = {
    'two-finger-scrolling-enabled': true
};

local desktop_interface_settings = {
    'button-layout': 'appmenu:minimize,maximize,close',
    'clock-show-date': true,
    'clock-show-seconds': false,
    'clock-show-weekday': false,
    'clock-format': '12h',
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
    'picture-uri': 'file://"$HOME"/' + wallpaper_path,
    'picture-uri-dark': 'file://"$HOME"/' + if dark_wallpaper_path != null then dark_wallpaper_path else wallpaper_path,
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
    'animate-appicon-hover-animation-extent': {'RIPPLE': 4, 'PLANK': 4, 'SIMPLE': 1},
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
    'panel-lengths': std.toString({"0": 40}),
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
};

{
    'org/gnome/desktop/peripherals/mouse': mouse_settings,
    'org/gnome/desktop/peripherals/touchpad': touchpad_settings,
    'org/gnome/desktop/interface': desktop_interface_settings,
    'org/gnome/shell': shell_settings,
    'org/gnome/shell/desktop/background': background_settings,
    'org/gnome/shell/extensions/dash-to-panel': dash_to_panel_settings,
}

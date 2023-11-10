local iterm = import './iterm_core.libsonnet';
local wallpapers = import '../wallpaper/wallpapers.jsonnet';
{
    guids:: [
        "FA66AC80-6AAA-4A3B-9CFE-B934F789D5EF",
        "658b147e-4e39-48a1-8ecc-92eeed6c0104"
    ],
    ZshTheHardWay:: iterm.ItermProfile("Zsh the Hard Way", self.guids[0], wallpapers.abstract_colorful),
    HotkeyWindow:: iterm.ItermProfile("Guake Window", self.guids[1], wallpapers.quake) {
        "Has Hotkey": true,
        "Horizontal Spacing": 1.0,
        "HotKey Activated By Modifier": false,
        "HotKey Alternate Shortcuts": [],
        "HotKey Characters": "\uf70f",
        "HotKey Characters Ignoring Modifiers": "\uf70f",
        "HotKey Key Code": 111,
        "HotKey Modifier Activation": 0,
        "HotKey Modifier Flags": 0,
        "HotKey Window Animates": true,
        "HotKey Window AutoHides": true,
        "HotKey Window Dock Click Action": 0,
        "HotKey Window Floats": false,
        "HotKey Window Reopens On Activation": false,
        "Initial Use Transparency": true,
        "Keyboard Map": {
            "0x74-0x100000-0x0": {
                "Action": 27,
                "Label": "",
                "Text": self.guids[1],
                "Version": 1
            }
        },
        Space: -1,
        Transparency: 0.3,
        "Vertical Spacing": 1.0,
        "Window Type": 2,
    },

    Profiles: [ self.ZshTheHardWay ],
}
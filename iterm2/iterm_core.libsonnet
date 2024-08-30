local wallpapers = import '../wallpaper/wallpapers.jsonnet';
local color_defs = import '../shell/color_definitions.libsonnet';
local apply_configs = import '../apply_configs.jsonnet';

local host = apply_configs.host;

local Color = color_defs.Color;
local ColorWithAlpha = color_defs.ColorWithAlpha;
local Colors = color_defs.Colors;
local ExtendedTerminalColors = color_defs.ExtendedTerminalColors;

local default_color_scheme = color_defs.Schemes.ITerm;

local ItermColor(color) =
{
    "Red Component": std.toString(color.red),
    "Green Component": std.toString(color.green),
    "Blue Component": std.toString(color.blue),
};
// Note numbers, not strings :shrug:
local ItermColorAlpha(color) = {
    "Color Space": "sRGB",
    "Red Component": color.red,
    "Green Component": color.green,
    "Blue Component": color.blue,
    "Alpha Component": color.alpha,
};
local ItermColorPreset(name, color_scheme, extended_colors) = {
    [if name != null then "name"]:: name,

    "Ansi 0 Color": ItermColor(color_scheme.color0),
    "Ansi 1 Color": ItermColor(color_scheme.color1),
    "Ansi 2 Color": ItermColor(color_scheme.color2),
    "Ansi 3 Color": ItermColor(color_scheme.color3),
    "Ansi 4 Color": ItermColor(color_scheme.color4),
    "Ansi 5 Color": ItermColor(color_scheme.color5),
    "Ansi 6 Color": ItermColor(color_scheme.color6),
    "Ansi 7 Color": ItermColor(color_scheme.color7),
    "Ansi 8 Color": ItermColor(color_scheme.color8),
    "Ansi 9 Color": ItermColor(color_scheme.color9),
    "Ansi 10 Color": ItermColor(color_scheme.color10),
    "Ansi 11 Color": ItermColor(color_scheme.color11),
    "Ansi 12 Color": ItermColor(color_scheme.color12),
    "Ansi 13 Color": ItermColor(color_scheme.color13),
    "Ansi 14 Color": ItermColor(color_scheme.color14),
    "Ansi 15 Color": ItermColor(color_scheme.color15),

    [if extended_colors.background != null then "Background Color"]: ItermColor(extended_colors.background),
    [if extended_colors.foreground != null then "Foreground Color"]: ItermColor(extended_colors.foreground),
    [if extended_colors.bold != null then "Bold Color"]: ItermColor(extended_colors.bold),
    [if extended_colors.link != null then "Link Color"]: ItermColor(extended_colors.link),
    [if extended_colors.selection_background != null then "Selection Color"]: ItermColor(extended_colors.selection_background),
    [if extended_colors.selection_foreground != null then "Selected Text Color"]: ItermColor(extended_colors.selection_foreground),
    [if extended_colors.cursor_background != null then "Cursor Color"]: ItermColor(extended_colors.cursor_background),
    [if extended_colors.cursor_foreground != null then "Cursor Text Color"]: ItermColor(extended_colors.cursor_foreground),
    [if extended_colors.underline != null then "Underline Color"]: ItermColor(extended_colors.underline),
    [if extended_colors.tab != null then "Tab Color"]: ItermColor(extended_colors.tab)
};

local ItermColorBlack = ItermColor(Colors.Black);
local ItermColorWhite = ItermColor(Colors.White);
{
    guids:: [
        "4122d667-ad31-4565-8731-164b3a3f078f",
        "4d4ccc47-a95a-4b77-ac34-5f5583d0a6ce",
        "2eebfac1-df35-475a-b147-f72d415802c1",
        "b027d842-7e00-4842-9732-348c0230a77e",
        "8d185233-91f7-4096-98f0-bf40467bb7ce",
        "540d8be1-f9ff-4e3b-ada3-9d11b74a5d36",
        "bbff99ed-7cfa-455f-b78a-4876d7ca83e4",
        "3e0a37ad-41d2-427c-a380-e3186cf450c1",
        "13cc1650-4043-44d0-8d49-bf718f40469b",
        "e193340a-970f-4d21-b087-9b82e4743655",
        "a18dfdbc-995c-422a-a639-3b4ac16575f5",
        "bff4f950-c91c-4e1f-9808-efc3f64af260",
        "ef3a40d8-a1ef-48b6-99f9-bdd2b1f2eb04",
        "92803fb5-7f06-494d-aadb-7d5678e8d09f",
        "ddd748f9-d9aa-4e00-a2b3-dfff86b4cebf",
        "a5f40a0d-b445-4bf1-bfcd-30bf34fa6905",
        "56dd2b39-28e7-450f-bb9e-242bcb37f4a9",
        "46c05cb5-a8ea-4abe-a301-02a75d6352bb",
        "88f46a90-3f8e-4258-93e4-e08b1fcdb520",
        "fe30c44a-f7f8-479e-9608-812f4e7d621c"
    ],
    private_guids:: [
        "748cf42e-b25d-4113-9bc6-134455bf65e6",
        "FA66AC80-6AAA-4A3B-9CFE-B934F789D5EF",
        "658b147e-4e39-48a1-8ecc-92eeed6c0104"
    ],
    ItermProfileTemplate::
    {
        "ASCII Anti Aliased": true,
        "ASCII Ligatures": true,
        "Ambiguous Double Width": false,
        "BM Growl": true,
        "Background Image Mode": 2,
        "Blink Allowed": false,
        "Blinking Cursor": false,
        "Blur": true,
        "Blur Radius": 10,
        "Bold Color": ItermColorWhite,
        "Character Encoding": 4,
        "Close Sessions On End": true,
        "Columns": 140,
        "Command": "/opt/homebrew/bin/zsh",
        "Custom Command": "Custom Shell",
        "Custom Directory": "No",
        "Default Bookmark": "No",
        "Description": "Default",
        "Disable Window Resizing": true,
        "Enable Triggers in Interactive Apps": false,
        "Flashing Bell": false,
        "Horizontal Spacing": 1,
        "Icon": 1,
        "Idle Code": 0,
        "Initial Text": "",
        "Initial Use Transparency": false,
        "Jobs to Ignore": [],
        "Left Option Key Changeable": false,
        "Link Color": ItermColorAlpha(Colors.CeruleanBlue),
        "Mouse Reporting": true,
        "Non-ASCII Anti Aliased": true,
        "Normal Font": "CascadiaCodeNF-Regular_SemiLight 14",
        "Only The Default BG Color Uses Transparency": false,
        "Option Key Sends": 0,
        "Prompt Before Closing 2": false,
        "Right Option Key Sends": 0,
        "Rows": 25,
        "Screen": -1,
        "Scrollback Lines": 0,
        "Send Code When Idle": false,
        "Shortcut": "",
        "Silence Bell": false,
        "Space": 0,
        "Sync Title": false,
        "Tags": [],
        "Terminal Type": "xterm-256color",
        "Thin Strokes": 3,
        "Transparency": 0,
        "Triggers": [],
        "Unicode Normalization": 0,
        "Unlimited Scrollback": true,
        "Use Bold Font": true,
        "Use Bright Bold": true,
        "Use Italic Font": true,
        "Use Non-ASCII Font": false,
        "Vertical Spacing": 1,
        "Visual Bell": true,
        "Window Type": 0
    },
    ITermColorPreset:: ItermColorPreset,
    ItermProfileTrigger(regex, action, parameter, partial=false)::
    {
        action : action,
        parameter : parameter,
        regex : regex,
        [if partial then "partial"]: true,
    },
    ItermProfile(profile_name, color, guid, wallpaper)::
        ItermColorPreset(null, default_color_scheme, default_color_scheme.terminal_colors) +
        $.ItermProfileTemplate +
    {
        "Background Image Location": wallpaper.target_path(null),
        "Badge Color": ItermColorAlpha(ColorWithAlpha(color, 0.5)),
        "Blend": wallpaper.blend,
        "Cursor Guide Color": ItermColorAlpha(ColorWithAlpha(color, 0.25)),
        "Guid": guid,
        "Name": profile_name,
    },
    SessionView(profile):: {
        "Is Active": 1,
        "Session": {
            "Bookmark": profile,
            "Is UTF-8": true,
            "Short Lived Single Use": false,
        },
        "View Type": "SessionView",
    },
    Tab(subviews):: {
        "Subviews": subviews,
        "View Type": "Splitter",
        "isVertical": false
    },
    WindowArrangement(name, tabs):: {
        Name:: name,
        "Desired Columns": 140,
        "Desired Rows": 25,
        "Has Toolbelt": false,
        "Height": 600.0,
        "Hide After Opening": false,
        "Hiding Toolbelt Should Resize Window": true,
        "Initial Profile": {},
        "Is Hotkey Window": false,
        "Saved Window Type": 0,
        "Screen": 0,
        "Scroller Width": 0.0,
        "Selected Tab Index": 0,
        "Tabs": [
            {
                "Root": tab,
                //"Tab GUID": tab.guid
            } for tab in tabs],
        //"TerminalGuid": "pty-994A17A5-BC75-46F8-B5BD-B1BAE6737A70",
        "Use Transparency": false,
        "Width": 1500.0,
        "Window Type": 0,
        "X Origin": 844.0,
        "Y Origin": 648.0
    },
    Profiles:: {
        ZshTheHardWay: $.ItermProfile("Zsh the Hard Way", Colors.White, $.private_guids[0], wallpapers.hokusai_wave),
        BashTheOldWay: $.ItermProfile("Bash the Old Way", Colors.White, $.private_guids[1], wallpapers.abstract_pastel) {
            "Command": "/opt/homebrew/bin/bash",
        },
        HotkeyWindow: $.ItermProfile("Guake Window", Colors.White, $.private_guids[2], wallpapers.quake) {
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
                    "Text": $.private_guids[2],
                    "Version": 1
                }
            },
            Space: -1,
            Transparency: 0.3,
            "Vertical Spacing": 1.0,
            "Window Type": 2,
        },
    }
}
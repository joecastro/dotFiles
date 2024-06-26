local wallpapers = import '../wallpaper/wallpapers.jsonnet';

local ItermColor(r, g, b) =
{
    "Red Component": std.toString(r),
    "Green Component": std.toString(g),
    "Blue Component": std.toString(b),
};
// Note numbers, not strings :shrug:
local ItermColorAlpha(r, g, b, a) = {
    "Color Space": "sRGB",
    "Red Component": r,
    "Green Component": g,
    "Blue Component": b,
    "Alpha Component": a,
};
local ItermColorBlack = ItermColor(0, 0, 0);
local ItermColorWhite = ItermColor(1, 1, 1);
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
    ItermProfileTrigger(regex, action, parameter, partial=false)::
    {
        action : action,
        parameter : parameter,
        regex : regex,
        [if partial then "partial"]: true,
    },
    ItermProfile(profile_name, guid, wallpaper)::
    {
        "ASCII Anti Aliased": true,
        "ASCII Ligatures": true,
        "Ambiguous Double Width": false,
        "Ansi 0 Color": ItermColorBlack,
        "Ansi 1 Color": ItermColor(0.8, 0, 0),
        "Ansi 2 Color": ItermColor(0.31, 0.60, 0.02),
        "Ansi 3 Color": ItermColor(0.77, 0.63, 0),
        "Ansi 4 Color": ItermColor(0.20, 0.40, 0.64),
        "Ansi 5 Color": ItermColor(0.46, 0.31, 0.48),
        "Ansi 6 Color": ItermColor(0.02, 0.60, 0.60),
        "Ansi 7 Color": ItermColor(0.83, 0.84, 0.81),
        "Ansi 8 Color": ItermColor(0.33, 0.34, 0.33),
        "Ansi 9 Color": ItermColor(0.94, 0.16, 0.16),
        "Ansi 10 Color": ItermColor(0.54, 0.89, 0.20),
        "Ansi 11 Color": ItermColor(0.99, 0.91, 0.31),
        "Ansi 12 Color": ItermColor(0.45, 0.62, 0.81),
        "Ansi 13 Color": ItermColor(0.68, 0.50, 0.66),
        "Ansi 14 Color": ItermColor(0.20, 0.89, 0.89),
        "Ansi 15 Color": ItermColor(0.93, 0.93, 0.92),
        "BM Growl": true,
        "Background Color": ItermColorBlack,
        "Background Image Location": std.extVar("cwd") + "/wallpaper/" + wallpaper.path,
        "Background Image Mode": 2,
        "Badge Color": ItermColorAlpha(1, 0.15, 0, 0.5),
        "Blend": wallpaper.blend,
        "Blink Allowed": false,
        "Blinking Cursor": false,
        "Blur": true,
        "Blur Radius": 10,
        "Bold Color": ItermColorWhite,
        "Character Encoding": 4,
        "Close Sessions On End": true,
        "Columns": 140,
        "Command": "/opt/homebrew/bin/zsh",
        "Cursor Color": ItermColorWhite,
        "Cursor Guide Color": ItermColorAlpha(0.70, 0.93, 1, 0.25),
        "Cursor Text Color": ItermColorBlack,
        "Custom Command": "Custom Shell",
        "Custom Directory": "No",
        "Default Bookmark": "No",
        "Description": "Default",
        "Disable Window Resizing": true,
        "Enable Triggers in Interactive Apps": false,
        "Flashing Bell": false,
        "Foreground Color": ItermColorWhite,
        "Guid": guid,
        "Horizontal Spacing": 1,
        "Icon": 1,
        "Idle Code": 0,
        "Initial Text": "",
        "Initial Use Transparency": false,
        "Jobs to Ignore": [],
        "Left Option Key Changeable": false,
        "Link Color": ItermColorAlpha(0, 0.36, 0.73, 1),
        "Mouse Reporting": true,
        "Name": profile_name,
        "Non-ASCII Anti Aliased": true,
        "Normal Font": "CaskaydiaCoveNFM-Regular 14",
        "Only The Default BG Color Uses Transparency": false,
        "Option Key Sends": 0,
        "Prompt Before Closing 2": false,
        "Right Option Key Sends": 0,
        "Rows": 25,
        "Screen": -1,
        "Scrollback Lines": 0,
        "Selected Text Color": ItermColorBlack,
        "Selection Color": ItermColor(0.71, 0.84, 1),
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
        ZshTheHardWay: $.ItermProfile("Zsh the Hard Way", $.private_guids[0], wallpapers.abstract_colorful),
        BashTheOldWay: $.ItermProfile("Bash the Old Way", $.private_guids[1], wallpapers.abstract_pastel) {
            "Command": "/opt/homebrew/bin/bash",
        },
        HotkeyWindow: $.ItermProfile("Guake Window", $.private_guids[2], wallpapers.quake) {
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
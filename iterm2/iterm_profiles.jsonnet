local BackgroundImageNode(file_name, blend_percent=0.4) =
{
    full_path: std.extVar('dot_files_root') + "/wallpaper/" + file_name,
    blend: blend_percent,
};
{
    ItermProfile(profile_name, wallpaper, guid)::
    {
        "ASCII Anti Aliased": true,
        "ASCII Ligatures": true,
        "Ambiguous Double Width": false,
        "Ansi 0 Color": {
            "Blue Component": "0",
            "Green Component": "0",
            "Red Component": "0"
        },
        "Ansi 1 Color": {
            "Blue Component": "0",
            "Green Component": "0",
            "Red Component": "0.8"
        },
        "Ansi 10 Color": {
            "Blue Component": "0.2039216",
            "Green Component": "0.8862745",
            "Red Component": "0.5411764999999999"
        },
        "Ansi 11 Color": {
            "Blue Component": "0.3098039",
            "Green Component": "0.9137255",
            "Red Component": "0.9882353"
        },
        "Ansi 12 Color": {
            "Blue Component": "0.8117647",
            "Green Component": "0.6235294",
            "Red Component": "0.4470588"
        },
        "Ansi 13 Color": {
            "Blue Component": "0.6588235",
            "Green Component": "0.4980392",
            "Red Component": "0.6784314"
        },
        "Ansi 14 Color": {
            "Blue Component": "0.8862745",
            "Green Component": "0.8862745",
            "Red Component": "0.2039216"
        },
        "Ansi 15 Color": {
            "Blue Component": "0.9254902",
            "Green Component": "0.9333333",
            "Red Component": "0.9333333"
        },
        "Ansi 2 Color": {
            "Blue Component": "0.02352941",
            "Green Component": "0.6039215999999999",
            "Red Component": "0.3058824"
        },
        "Ansi 3 Color": {
            "Blue Component": "0",
            "Green Component": "0.627451",
            "Red Component": "0.7686275"
        },
        "Ansi 4 Color": {
            "Blue Component": "0.6431373",
            "Green Component": "0.3960784",
            "Red Component": "0.2039216"
        },
        "Ansi 5 Color": {
            "Blue Component": "0.4823529",
            "Green Component": "0.3137255",
            "Red Component": "0.4588235"
        },
        "Ansi 6 Color": {
            "Blue Component": "0.6039215999999999",
            "Green Component": "0.5960785",
            "Red Component": "0.02352941"
        },
        "Ansi 7 Color": {
            "Blue Component": "0.8117647",
            "Green Component": "0.8431373",
            "Red Component": "0.827451"
        },
        "Ansi 8 Color": {
            "Blue Component": "0.3254902",
            "Green Component": "0.3411765",
            "Red Component": "0.3333333"
        },
        "Ansi 9 Color": {
            "Blue Component": "0.1607843",
            "Green Component": "0.1607843",
            "Red Component": "0.9372549"
        },
        "BM Growl": true,
        "Background Color": {
            "Blue Component": "0",
            "Green Component": "0",
            "Red Component": "0"
        },
        "Background Image Location": wallpaper.full_path,
        "Background Image Mode": 2,
        "Badge Color": {
            "Alpha Component": 0.5,
            "Blue Component": 0,
            "Color Space": "sRGB",
            "Green Component": 0.15,
            "Red Component": 1
        },
        "Blend": wallpaper.blend,
        "Blink Allowed": false,
        "Blinking Cursor": false,
        "Blur": true,
        "Blur Radius": 10,
        "Bold Color": {
            "Blue Component": "1",
            "Green Component": "1",
            "Red Component": "1"
        },
        "Character Encoding": 4,
        "Close Sessions On End": true,
        "Columns": 140,
        "Command": "/bin/zsh",
        "Cursor Color": {
            "Blue Component": "1",
            "Green Component": "1",
            "Red Component": "1"
        },
        "Cursor Guide Color": {
            "Alpha Component": 0.25,
            "Blue Component": 1,
            "Color Space": "sRGB",
            "Green Component": 0.93,
            "Red Component": 0.70
        },
        "Cursor Text Color": {
            "Green Component": "0",
            "Blue Component": "0",
            "Red Component": "0"
        },
        "Custom Command": "Custom Shell",
        "Custom Directory": "No",
        "Default Bookmark": "No",
        "Description": "Default",
        "Disable Window Resizing": true,
        "Flashing Bell": false,
        "Foreground Color": {
            "Blue Component": "1",
            "Green Component": "1",
            "Red Component": "1"
        },
        "Guid": guid,
        "Horizontal Spacing": 1,
        "Icon": 1,
        "Idle Code": 0,
        "Initial Text": "",
        "Initial Use Transparency": false,
        "Jobs to Ignore": [],
        "Left Option Key Changeable": false,
        "Link Color": {
            "Alpha Component": 1,
            "Blue Component": 0.7342271208763123,
            "Color Space": "sRGB",
            "Green Component": 0.35915297269821167,
            "Red Component": 0
        },
        "Mouse Reporting": true,
        "Name": profile_name,
        "Non-ASCII Anti Aliased": true,
        "Normal Font": "CaskaydiaCoveNerdFontCompleteM-Regular 14",
        "Only The Default BG Color Uses Transparency": false,
        "Option Key Sends": 0,
        "Prompt Before Closing 2": false,
        "Right Option Key Sends": 0,
        "Rows": 25,
        "Screen": -1,
        "Scrollback Lines": 0,
        "Selected Text Color": {
            "Blue Component": "0",
            "Green Component": "0",
            "Red Component": "0"
        },
        "Selection Color": {
            "Blue Component": "1",
            "Green Component": "0.8353",
            "Red Component": "0.7098"
        },
        "Send Code When Idle": false,
        "Shortcut": "",
        "Silence Bell": false,
        "Space": 0,
        "Sync Title": false,
        "Tags": [],
        "Terminal Type": "xterm-256color",
        "Thin Strokes": 3,
        "Transparency": 0,
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
    wallpapers:: {
        abstract_blue: BackgroundImageNode("abstract_blue.png"),
        abstract_red: BackgroundImageNode("abstract_red.png"),
        abstract_gray: BackgroundImageNode("abstract_gray.png"),
        abstract_colorful: BackgroundImageNode("abstract_colorful.png"),
        abstract_purple_blue: BackgroundImageNode("abstract_purple_blue.jpg", 0.7),
        android_army: BackgroundImageNode("android_army.jpg", 0.6),
        android_backpack: BackgroundImageNode("android_backpack.jpg"),
        android_colorful: BackgroundImageNode("android_colorful.jpg"),
        android_umbrella: BackgroundImageNode("android_umbrella.jph"),
        android_wood: BackgroundImageNode("android_wood.jpg", 0.6),
        google_colors: BackgroundImageNode("google_colors.jpg", 0.35),
    },
    Profiles: [
        self.ItermProfile("Zsh the Hard Way", self.wallpapers.abstract_colorful, "FA66AC80-6AAA-4A3B-9CFE-B934F789D5EF")
    ],
}
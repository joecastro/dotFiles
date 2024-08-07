local Color(r, g, b, a=1) = {
    assert r >= 0 && r <= 1: "Red component must be between 0 and 1",
    assert g >= 0 && g <= 1: "Green component must be between 0 and 1",
    assert b >= 0 && b <= 1: "Blue component must be between 0 and 1",
    assert a >= 0 && a <= 1: "Alpha component must be between 0 and 1",

    red:: r,
    green:: g,
    blue:: b,
    alpha:: a,

    red255:: std.round(r * 255),
    green255:: std.round(g * 255),
    blue255:: std.round(b * 255),
    alpha255:: std.round(a * 255),

    assert $.red255 >= 0 && $.red255 <= 255: "Red component must be between 0 and 255",
    assert $.green255 >= 0 && $.green255 <= 255: "Green component must be between 0 and 255",
    assert $.blue255 >= 0 && $.blue255 <= 255: "Blue component must be between 0 and 255",
    assert $.alpha255 >= 0 && $.alpha255 <= 255: "Alpha component must be between 0 and 255",

    hexcolor:: "#%02x%02x%02x" % [$.red255, $.green255, $.blue255],
    HEXCOLOR:: std.asciiUpper($.hexcolor),
    rgb255:: "%d,%d,%d" % [$.red255, $.green255, $.blue255],
};

local ColorFromHex(hex) =
    local r = std.parseHex(std.substr(hex, 1, 2)) / 255;
    local g = std.parseHex(std.substr(hex, 3, 2)) / 255;
    local b = std.parseHex(std.substr(hex, 5, 2)) / 255;
    Color(r, g, b);

local Color255(r, g, b, a=255) =
    Color(r / 255, g / 255, b / 255, a / 255);

local ColorWithAlpha(color, alpha) =
    Color(color.red, color.green, color.blue, alpha);

local Black = Color(0, 0, 0);
local Blue = Color(0, 0, 1);
local Green = Color(0, 1, 0);
local Cyan = Color(0, 1, 1);
local Red = Color(1, 0, 0);
local Magenta = Color(1, 0, 1);
local Yellow = Color(1, 1, 0);
local White = Color(1, 1, 1);

local AnsiColorScheme(black, red, green, yellow, blue, magenta, cyan, white, bright_black, bright_red, bright_green, bright_yellow, bright_blue, bright_magenta, bright_cyan, bright_white, ext=null) = {
    black:: black,
    red:: red,
    green:: green,
    yellow:: yellow,
    blue:: blue,
    magenta:: magenta,
    cyan:: cyan,
    white:: white,
    bright_black:: bright_black,
    bright_red:: bright_red,
    bright_green:: bright_green,
    bright_yellow:: bright_yellow,
    bright_blue:: bright_blue,
    bright_magenta:: bright_magenta,
    bright_cyan:: bright_cyan,
    bright_white:: bright_white,

    terminal_colors:: ext,

    color0:: black,
    color1:: red,
    color2:: green,
    color3:: yellow,
    color4:: blue,
    color5:: magenta,
    color6:: cyan,
    color7:: white,
    color8:: bright_black,
    color9:: bright_red,
    color10:: bright_green,
    color11:: bright_yellow,
    color12:: bright_blue,
    color13:: bright_magenta,
    color14:: bright_cyan,
    color15:: bright_white,

    color0_bold:: bright_black,
    color1_bold:: bright_red,
    color2_bold:: bright_green,
    color3_bold:: bright_yellow,
    color4_bold:: bright_blue,
    color5_bold:: bright_magenta,
    color6_bold:: bright_cyan,
    color7_bold:: bright_white,

    color_pack:: {
        black: black.hexcolor,
        blue: blue.hexcolor,
        cyan: cyan.hexcolor,
        green: green.hexcolor,
        purple: magenta.hexcolor,
        red: red.hexcolor,
        white: white.hexcolor,
        yellow: yellow.hexcolor
    },

    bright_color_pack:: {
        brightBlack: bright_black.hexcolor,
        brightBlue: bright_blue.hexcolor,
        brightCyan: bright_cyan.hexcolor,
        brightGreen: bright_green.hexcolor,
        brightPurple: bright_magenta.hexcolor,
        brightRed: bright_red.hexcolor,
        brightWhite: bright_white.hexcolor,
        brightYellow: bright_yellow.hexcolor
    },

    printable:: {
        black: black.hexcolor,
        red: red.hexcolor,
        green: green.hexcolor,
        yellow: yellow.hexcolor,
        blue: blue.hexcolor,
        magenta: magenta.hexcolor,
        cyan: cyan.hexcolor,
        white: white.hexcolor,
        bright_black: bright_black.hexcolor,
        bright_red: bright_red.hexcolor,
        bright_green: bright_green.hexcolor,
        bright_yellow: bright_yellow.hexcolor,
        bright_blue: bright_blue.hexcolor,
        bright_magenta: bright_magenta.hexcolor,
        bright_cyan: bright_cyan.hexcolor,
        bright_white: bright_white.hexcolor,
    }
};
local ExtendedTerminalColors(
        foreground,
        background,
        bold,
        link,
        selection_background,
        selection_foreground,
        cursor_background,
        cursor_foreground,
        underline,
        tab) = {
    foreground: foreground,
    background: background,
    bold: bold,
    link: link,
    selection_background: selection_background,
    selection_foreground: selection_foreground,
    cursor_foreground: cursor_foreground,
    cursor_background: cursor_background,
    underline: underline,
    tab: tab
};
{
    Color: Color,
    AnsiColorScheme: AnsiColorScheme,
    ExtendedTerminalColors: ExtendedTerminalColors,
    ColorFromHex: ColorFromHex,
    ColorWithAlpha: ColorWithAlpha,
    # https://hexcolor.co
    Colors: {
        Black: ColorFromHex("#000000"),
        BlueBell: ColorFromHex("#95a0c5"),
        BlueMartini: ColorFromHex("#52B4D3"),
        Cardinal: ColorFromHex("#c01c28"),
        Carnation: ColorFromHex('#f66151'),
        ForestGreen: ColorFromHex("#228B22"),
        Ginger: ColorFromHex("#B06500"),
        Ghost: ColorFromHex("#ccd1d9"),
        GuardsmanRed: ColorFromHex("#D31100"),
        CeruleanBlue: Color(0, 0.36, 0.73, 1),
        NoblePlum: ColorFromHex("#871F78"),
        RoofTerracotta: ColorFromHex("#a51d2d"),
        SelectiveYellow: ColorFromHex("#ffb506"),
        Viola: ColorFromHex("#cc87a9"),
        White: ColorFromHex("#FFFFFF"),
        YellowSea: ColorFromHex("#ffaf00"),
    },
    PeacockColors: {
        "Angular Red": ColorFromHex("#dd0531"),
        "Azure Blue": ColorFromHex("#007fff"),
        "JavaScript Yellow": ColorFromHex("#f9e64f"),
        "Mandalorian Blue": ColorFromHex("#1857a4"),
        "Node Green": ColorFromHex("#215732"),
        "React Blue": ColorFromHex("#61dafb"),
        "Something Different": ColorFromHex("#832561"),
        "Svelte Orange": ColorFromHex("#ff3d00"),
        "Vue Green": ColorFromHex("#42b883"),
    },
    Schemes: {
        Campbell: AnsiColorScheme(
            ColorFromHex("#0C0C0C"),
            ColorFromHex("#C50F1F"),
            ColorFromHex("#13A10E"),
            ColorFromHex("#C19C00"),
            ColorFromHex("#0037DA"),
            ColorFromHex("#881798"),
            ColorFromHex("#3A96DD"),
            ColorFromHex("#CCCCCC"),
            ColorFromHex("#767676"),
            ColorFromHex("#E74856"),
            ColorFromHex("#16C60C"),
            ColorFromHex("#F9F1A5"),
            ColorFromHex("#3B78FF"),
            ColorFromHex("#B4009E"),
            ColorFromHex("#61D6D6"),
            ColorFromHex("#F2F2F2"),
            ExtendedTerminalColors(
                ColorFromHex('#CCCCCC'), // foregound
                Black, // background
                null, // bold
                null, // link
                White, // selection_background
                null, // selection_foreground
                null, // cursor_background
                White, // cursor_foreground
                null, // underline
                null)), // tab
        CampbellPoweshell: AnsiColorScheme(
            ColorFromHex("#0C0C0C"),
            ColorFromHex("#C50F1F"),
            ColorFromHex("#13A10E"),
            ColorFromHex("#C19C00"),
            ColorFromHex("#0037DA"),
            ColorFromHex("#881798"),
            ColorFromHex("#3A96DD"),
            ColorFromHex("#CCCCCC"),
            ColorFromHex("#767676"),
            ColorFromHex("#E74856"),
            ColorFromHex("#16C60C"),
            ColorFromHex("#F9F1A5"),
            ColorFromHex("#3B78FF"),
            ColorFromHex("#B4009E"),
            ColorFromHex("#61D6D6"),
            ColorFromHex("#F2F2F2"),
            ExtendedTerminalColors(
                ColorFromHex('#CCCCCC'), // foregound
                ColorFromHex('#012456'), // background
                null, // bold
                null, // link
                White, // selection_background
                null, // selection_foreground
                null, // cursor_background
                White, // cursor_foreground
                null, // underline
                null)), // tab
        Vintage: AnsiColorScheme(
            ColorFromHex("#000000"),
            ColorFromHex("#800000"),
            ColorFromHex("#008000"),
            ColorFromHex("#808000"),
            ColorFromHex("#000080"),
            ColorFromHex("#800080"),
            ColorFromHex("#008080"),
            ColorFromHex("#C0C0C0"),
            ColorFromHex("#808080"),
            ColorFromHex("#FF0000"),
            ColorFromHex("#00FF00"),
            ColorFromHex("#FFFF00"),
            ColorFromHex("#0000FF"),
            ColorFromHex("#FF00FF"),
            ColorFromHex("#00FFFF"),
            ColorFromHex("#FFFFFF"),
            ExtendedTerminalColors(
                ColorFromHex('#C0C0C0'),
                Black,
                null,
                null,
                White,
                null,
                null,
                White,
                null,
                null)),
        Frost: AnsiColorScheme(
            ColorFromHex("#3C5712"),
            ColorFromHex("#8D0C0C"),
            ColorFromHex("#6AAE08"),
            ColorFromHex("#991070"),
            ColorFromHex("#17b2ff"),
            ColorFromHex("#991070"),
            ColorFromHex("#3C96A6"),
            ColorFromHex("#6E386E"),
            ColorFromHex("#749B36"),
            ColorFromHex("#F49B36"),
            ColorFromHex("#89AF50"),
            ColorFromHex("#991070"),
            ColorFromHex("#27B2F6"),
            ColorFromHex("#F2A20A"),
            ColorFromHex("#13A8C0"),
            ColorFromHex("#741274")),
        '3024 Day': AnsiColorScheme(
            ColorFromHex('#090300'),
            ColorFromHex('#db2d20'),
            ColorFromHex('#01a252'),
            ColorFromHex('#fded02'),
            ColorFromHex('#01a0e4'),
            ColorFromHex('#a16a94'),
            ColorFromHex('#b5e4f4'),
            ColorFromHex('#a5a2a2'),
            ColorFromHex('#5c5855'),
            ColorFromHex('#e8bbd0'),
            ColorFromHex('#3a3432'),
            ColorFromHex('#4a4543'),
            ColorFromHex('#807d7c'),
            ColorFromHex('#d6d5d4'),
            ColorFromHex('#cdab53'),
            ColorFromHex('#f7f7f7'),
            ExtendedTerminalColors(
                ColorFromHex('#4a4543'), // foregound
                ColorFromHex('#f7f7f7'), // background
                ColorFromHex('#4a4543'), // bold
                null, // link
                ColorFromHex('#a5a2a2'), // selection_background
                ColorFromHex('#4a4543'), // selection_foreground
                ColorFromHex('#4a4543'), // cursor_background
                ColorFromHex('#f7f7f7'), // cursor_foreground
                null, // underline
                null)), // tab
        '3024 Night': AnsiColorScheme(
            ColorFromHex('#090300'),
            ColorFromHex('#db2d20'),
            ColorFromHex('#01a252'),
            ColorFromHex('#fded02'),
            ColorFromHex('#01a0e4'),
            ColorFromHex('#a16a94'),
            ColorFromHex('#b5e4f4'),
            ColorFromHex('#a5a2a2'),
            ColorFromHex('#5c5855'),
            ColorFromHex('#e8bbd0'),
            ColorFromHex('#3a3432'),
            ColorFromHex('#4a4543'),
            ColorFromHex('#807d7c'),
            ColorFromHex('#d6d5d4'),
            ColorFromHex('#cdab53'),
            ColorFromHex('#f7f7f7'),
            ExtendedTerminalColors(
                ColorFromHex('#a5a2a2'), // foregound
                ColorFromHex('#090300'), // background
                ColorFromHex('#a5a2a2'), // bold
                null, // link
                ColorFromHex('#4a4543'), // selection_background
                ColorFromHex('#a5a2a2'), // selection_foreground
                ColorFromHex('#a5a2a2'), // cursor_background
                ColorFromHex('#090300'), // cursor_foreground
                null, // underline
                null)), // tab
        Andromeda: AnsiColorScheme(
            ColorFromHex('#000000'),
            ColorFromHex('#cd3131'),
            ColorFromHex('#05bc79'),
            ColorFromHex('#e5e512'),
            ColorFromHex('#2472c8'),
            ColorFromHex('#bc3fbc'),
            ColorFromHex('#0fa8cd'),
            ColorFromHex('#e5e5e5'),
            ColorFromHex('#666666'),
            ColorFromHex('#cd3131'),
            ColorFromHex('#05bc79'),
            ColorFromHex('#e5e512'),
            ColorFromHex('#2472c8'),
            ColorFromHex('#bc3fbc'),
            ColorFromHex('#0fa8cd'),
            ColorFromHex('#e5e5e5'),
            ExtendedTerminalColors(
                ColorFromHex('#e5e5e5'), // foregound
                ColorFromHex('#262a33'), // background
                ColorFromHex('#e5e5e5'), // bold
                null, // link
                ColorFromHex('#5a5c62'), // selection_background
                ColorFromHex('#ece7e7'), // selection_foreground
                ColorFromHex('#f8f8f0'), // cursor_background
                ColorFromHex('#cfcfc2'), // cursor_foreground
                null, // underline
                null)), // tab
        Aurora: AnsiColorScheme(
            ColorFromHex('#23262e'),
            ColorFromHex('#f0266f'),
            ColorFromHex('#8fd46d'),
            ColorFromHex('#ffe66d'),
            ColorFromHex('#0321d7'),
            ColorFromHex('#ee5d43'),
            ColorFromHex('#03d6b8'),
            ColorFromHex('#c74ded'),
            ColorFromHex('#292e38'),
            ColorFromHex('#f92672'),
            ColorFromHex('#8fd46d'),
            ColorFromHex('#ffe66d'),
            ColorFromHex('#03d6b8'),
            ColorFromHex('#ee5d43'),
            ColorFromHex('#03d6b8'),
            ColorFromHex('#c74ded'),
            ExtendedTerminalColors(
                ColorFromHex('#ffca28'), // foregound
                ColorFromHex('#23262e'), // background
                ColorFromHex('#fbfbff'), // bold
                null, // link
                ColorFromHex('#292e38'), // selection_background
                ColorFromHex('#00e8c6'), // selection_foreground
                ColorFromHex('#ee5d43'), // cursor_background
                ColorFromHex('#ffd29c'), // cursor_foreground
                null, // underline
                null)), // tab
        Cobalt2: AnsiColorScheme(
            ColorFromHex('#000000'),
            ColorFromHex('#ff0000'),
            ColorFromHex('#38de21'),
            ColorFromHex('#ffe50a'),
            ColorFromHex('#1460d2'),
            ColorFromHex('#ff005d'),
            ColorFromHex('#00bbbb'),
            ColorFromHex('#bbbbbb'),
            ColorFromHex('#555555'),
            ColorFromHex('#f40e17'),
            ColorFromHex('#3bd01d'),
            ColorFromHex('#edc809'),
            ColorFromHex('#5555ff'),
            ColorFromHex('#ff55ff'),
            ColorFromHex('#6ae3fa'),
            ColorFromHex('#ffffff'),
            ExtendedTerminalColors(
                ColorFromHex('#ffffff'), // foregound
                ColorFromHex('#132738'), // background
                ColorFromHex('#f7fcff'), // bold
                null, // link
                ColorFromHex('#18354f'), // selection_background
                ColorFromHex('#b5b5b5'), // selection_foreground
                ColorFromHex('#f0cc09'), // cursor_background
                ColorFromHex('#fefff2'), // cursor_foreground
                null, // underline
                null)), // tab
        Darkside: AnsiColorScheme(
            ColorFromHex('#000000'),
            ColorFromHex('#e8341c'),
            ColorFromHex('#68c256'),
            ColorFromHex('#f2d42c'),
            ColorFromHex('#1c98e8'),
            ColorFromHex('#8e69c9'),
            ColorFromHex('#1c98e8'),
            ColorFromHex('#bababa'),
            ColorFromHex('#000000'),
            ColorFromHex('#e05a4f'),
            ColorFromHex('#77b869'),
            ColorFromHex('#efd64b'),
            ColorFromHex('#387cd3'),
            ColorFromHex('#957bbe'),
            ColorFromHex('#3d97e2'),
            ColorFromHex('#bababa'),
            ExtendedTerminalColors(
                ColorFromHex('#bababa'), // foregound
                ColorFromHex('#222324'), // background
                ColorFromHex('#ffffff'), // bold
                null, // link
                ColorFromHex('#303333'), // selection_background
                ColorFromHex('#bababa'), // selection_foreground
                ColorFromHex('#bbbbbb'), // cursor_background
                ColorFromHex('#ffffff'), // cursor_foreground
                null, // underline
                null)), // tab
        'GitHub Dark': AnsiColorScheme(
            ColorFromHex('#000000'),
            ColorFromHex('#f78166'),
            ColorFromHex('#56d364'),
            ColorFromHex('#e3b341'),
            ColorFromHex('#6ca4f8'),
            ColorFromHex('#db61a2'),
            ColorFromHex('#2b7489'),
            ColorFromHex('#ffffff'),
            ColorFromHex('#4d4d4d'),
            ColorFromHex('#f78166'),
            ColorFromHex('#56d364'),
            ColorFromHex('#e3b341'),
            ColorFromHex('#6ca4f8'),
            ColorFromHex('#db61a2'),
            ColorFromHex('#2b7489'),
            ColorFromHex('#ffffff'),
            ExtendedTerminalColors(
                ColorFromHex('#8b949e'), // foregound
                ColorFromHex('#101216'), // background
                ColorFromHex('#c9d1d9'), // bold
                null, // link
                ColorFromHex('#3b5070'), // selection_background
                ColorFromHex('#ffffff'), // selection_foreground
                ColorFromHex('#c9d1d9'), // cursor_background
                ColorFromHex('#101216'), // cursor_foreground
                null, // underline
                null)), // tab
        Github: AnsiColorScheme(
            ColorFromHex('#3e3e3e'),
            ColorFromHex('#970b16'),
            ColorFromHex('#07962a'),
            ColorFromHex('#f8eec7'),
            ColorFromHex('#003e8a'),
            ColorFromHex('#e94691'),
            ColorFromHex('#89d1ec'),
            ColorFromHex('#ffffff'),
            ColorFromHex('#666666'),
            ColorFromHex('#de0000'),
            ColorFromHex('#87d5a2'),
            ColorFromHex('#f1d007'),
            ColorFromHex('#2e6cba'),
            ColorFromHex('#ffa29f'),
            ColorFromHex('#1cfafe'),
            ColorFromHex('#ffffff'),
            ExtendedTerminalColors(
                ColorFromHex('#3e3e3e'), // foregound
                ColorFromHex('#f4f4f4'), // background
                ColorFromHex('#c95500'), // bold
                null, // link
                ColorFromHex('#a9c1e2'), // selection_background
                ColorFromHex('#535353'), // selection_foreground
                ColorFromHex('#3f3f3f'), // cursor_background
                ColorFromHex('#f4f4f4'), // cursor_foreground
                null, // underline
                null)), // tab
        Glacier: AnsiColorScheme(
            ColorFromHex('#2e343c'),
            ColorFromHex('#bd0f2f'),
            ColorFromHex('#35a770'),
            ColorFromHex('#fb9435'),
            ColorFromHex('#1f5872'),
            ColorFromHex('#bd2523'),
            ColorFromHex('#778397'),
            ColorFromHex('#ffffff'),
            ColorFromHex('#404a55'),
            ColorFromHex('#bd0f2f'),
            ColorFromHex('#49e998'),
            ColorFromHex('#fddf6e'),
            ColorFromHex('#2a8bc1'),
            ColorFromHex('#ea4727'),
            ColorFromHex('#a0b6d3'),
            ColorFromHex('#ffffff'),
            ExtendedTerminalColors(
                ColorFromHex('#ffffff'), // foregound
                ColorFromHex('#0c1115'), // background
                ColorFromHex('#ffffff'), // bold
                null, // link
                ColorFromHex('#bd2523'), // selection_background
                ColorFromHex('#ffffff'), // selection_foreground
                ColorFromHex('#6c6c6c'), // cursor_background
                ColorFromHex('#6c6c6c'), // cursor_foreground
                null, // underline
                null)), // tab
        'Gruvbox Dark': AnsiColorScheme(
            ColorFromHex('#282828'),
            ColorFromHex('#cc241d'),
            ColorFromHex('#98971a'),
            ColorFromHex('#d79921'),
            ColorFromHex('#458588'),
            ColorFromHex('#b16286'),
            ColorFromHex('#689d6a'),
            ColorFromHex('#a89984'),
            ColorFromHex('#928374'),
            ColorFromHex('#fb4934'),
            ColorFromHex('#b8bb26'),
            ColorFromHex('#fabd2f'),
            ColorFromHex('#83a598'),
            ColorFromHex('#d3869b'),
            ColorFromHex('#8ec07c'),
            ColorFromHex('#ebdbb2'),
            ExtendedTerminalColors(
                ColorFromHex('#ebdbb2'), // foregound
                ColorFromHex('#282828'), // background
                ColorFromHex('#ebdbb2'), // bold
                null, // link
                ColorFromHex('#665c54'), // selection_background
                ColorFromHex('#ebdbb2'), // selection_foreground
                ColorFromHex('#ebdbb2'), // cursor_background
                ColorFromHex('#282828'), // cursor_foreground
                null, // underline
                null)), // tab
        Gruvbox: AnsiColorScheme(
            ColorFromHex('#fbf1c7'),
            ColorFromHex('#9d0006'),
            ColorFromHex('#79740e'),
            ColorFromHex('#b57614'),
            ColorFromHex('#076678'),
            ColorFromHex('#8f3f71'),
            ColorFromHex('#427b58'),
            ColorFromHex('#3c3836'),
            ColorFromHex('#9d8374'),
            ColorFromHex('#cc241d'),
            ColorFromHex('#98971a'),
            ColorFromHex('#d79921'),
            ColorFromHex('#458588'),
            ColorFromHex('#b16186'),
            ColorFromHex('#689d69'),
            ColorFromHex('#7c6f64'),
            ExtendedTerminalColors(
                ColorFromHex('#282828'), // foregound
                ColorFromHex('#fbf1c7'), // background
                ColorFromHex('#ffffff'), // bold
                null, // link
                ColorFromHex('#d5c4a1'), // selection_background
                ColorFromHex('#665c54'), // selection_foreground
                ColorFromHex('#282828'), // cursor_background
                ColorFromHex('#fbf1c7'), // cursor_foreground
                null, // underline
                null)), // tab
        ITerm: AnsiColorScheme(
            ColorFromHex('#000000'),
            ColorFromHex('#c91b00'),
            ColorFromHex('#00c200'),
            ColorFromHex('#c7c400'),
            ColorFromHex('#2225c4'),
            ColorFromHex('#ca30c7'),
            ColorFromHex('#00c5c7'),
            ColorFromHex('#ffffff'),
            ColorFromHex('#686868'),
            ColorFromHex('#ff6e67'),
            ColorFromHex('#5ffa68'),
            ColorFromHex('#fffc67'),
            ColorFromHex('#6871ff'),
            ColorFromHex('#ff77ff'),
            ColorFromHex('#60fdff'),
            ColorFromHex('#ffffff'),
            ExtendedTerminalColors(
                ColorFromHex('#ffffff'), // foregound
                ColorFromHex('#000000'), // background
                ColorFromHex('#ffffff'), // bold
                null, // link
                ColorFromHex('#c1deff'), // selection_background
                ColorFromHex('#000000'), // selection_foreground
                ColorFromHex('#e5e5e5'), // cursor_background
                ColorFromHex('#000000'), // cursor_foreground
                null, // underline
                null)), // tab
        'Material Dark': AnsiColorScheme(
            ColorFromHex('#212121'),
            ColorFromHex('#b7141f'),
            ColorFromHex('#457b24'),
            ColorFromHex('#f6981e'),
            ColorFromHex('#134eb2'),
            ColorFromHex('#560088'),
            ColorFromHex('#0e717c'),
            ColorFromHex('#efefef'),
            ColorFromHex('#424242'),
            ColorFromHex('#e83b3f'),
            ColorFromHex('#7aba3a'),
            ColorFromHex('#ffea2e'),
            ColorFromHex('#54a4f3'),
            ColorFromHex('#aa4dbc'),
            ColorFromHex('#26bbd1'),
            ColorFromHex('#d9d9d9'),
            ExtendedTerminalColors(
                ColorFromHex('#e5e5e5'), // foregound
                ColorFromHex('#232322'), // background
                ColorFromHex('#b7141f'), // bold
                null, // link
                ColorFromHex('#dfdfdf'), // selection_background
                ColorFromHex('#3d3d3d'), // selection_foreground
                ColorFromHex('#16afca'), // cursor_background
                ColorFromHex('#dfdfdf'), // cursor_foreground
                null, // underline
                null)), // tab
        Material: AnsiColorScheme(
            ColorFromHex('#212121'),
            ColorFromHex('#b7141f'),
            ColorFromHex('#457b24'),
            ColorFromHex('#f6981e'),
            ColorFromHex('#134eb2'),
            ColorFromHex('#560088'),
            ColorFromHex('#0e717c'),
            ColorFromHex('#efefef'),
            ColorFromHex('#424242'),
            ColorFromHex('#e83b3f'),
            ColorFromHex('#7aba3a'),
            ColorFromHex('#ffea2e'),
            ColorFromHex('#54a4f3'),
            ColorFromHex('#aa4dbc'),
            ColorFromHex('#26bbd1'),
            ColorFromHex('#d9d9d9'),
            ExtendedTerminalColors(
                ColorFromHex('#232322'), // foregound
                ColorFromHex('#eaeaea'), // background
                ColorFromHex('#b7141f'), // bold
                null, // link
                ColorFromHex('#c2c2c2'), // selection_background
                ColorFromHex('#4e4e4e'), // selection_foreground
                ColorFromHex('#16afca'), // cursor_background
                ColorFromHex('#2e2e2d'), // cursor_foreground
                null, // underline
                null)), // tab
        Monokai: AnsiColorScheme(
            ColorFromHex('#1a1a1a'),
            ColorFromHex('#f4005f'),
            ColorFromHex('#98e024'),
            ColorFromHex('#fd971f'),
            ColorFromHex('#9d65ff'),
            ColorFromHex('#f4005f'),
            ColorFromHex('#58d1eb'),
            ColorFromHex('#c4c5b5'),
            ColorFromHex('#625e4c'),
            ColorFromHex('#f4005f'),
            ColorFromHex('#98e024'),
            ColorFromHex('#e0d561'),
            ColorFromHex('#9d65ff'),
            ColorFromHex('#f4005f'),
            ColorFromHex('#58d1eb'),
            ColorFromHex('#f6f6ef'),
            ExtendedTerminalColors(
                ColorFromHex('#d9d9d9'), // foregound
                ColorFromHex('#0c0c0c'), // background
                ColorFromHex('#ebebeb'), // bold
                null, // link
                ColorFromHex('#343434'), // selection_background
                ColorFromHex('#ffffff'), // selection_foreground
                ColorFromHex('#fc971f'), // cursor_background
                ColorFromHex('#000000'), // cursor_foreground
                null, // underline
                null)), // tab
        'Monokai Soda': AnsiColorScheme(
            ColorFromHex('#1a1a1a'),
            ColorFromHex('#f4005f'),
            ColorFromHex('#98e024'),
            ColorFromHex('#fa8419'),
            ColorFromHex('#9d65ff'),
            ColorFromHex('#f4005f'),
            ColorFromHex('#58d1eb'),
            ColorFromHex('#c4c5b5'),
            ColorFromHex('#625e4c'),
            ColorFromHex('#f4005f'),
            ColorFromHex('#98e024'),
            ColorFromHex('#e0d561'),
            ColorFromHex('#9d65ff'),
            ColorFromHex('#f4005f'),
            ColorFromHex('#58d1eb'),
            ColorFromHex('#f6f6ef'),
            ExtendedTerminalColors(
                ColorFromHex('#c4c5b5'), // foregound
                ColorFromHex('#1a1a1a'), // background
                ColorFromHex('#c4c5b5'), // bold
                null, // link
                ColorFromHex('#343434'), // selection_background
                ColorFromHex('#c4c5b5'), // selection_foreground
                ColorFromHex('#f6f7ec'), // cursor_background
                ColorFromHex('#c4c5b5'), // cursor_foreground
                null, // underline
                null)), // tab
        'Monokai Vivid': AnsiColorScheme(
            ColorFromHex('#121212'),
            ColorFromHex('#fa2934'),
            ColorFromHex('#98e123'),
            ColorFromHex('#fff30a'),
            ColorFromHex('#0443ff'),
            ColorFromHex('#f800f8'),
            ColorFromHex('#01b6ed'),
            ColorFromHex('#ffffff'),
            ColorFromHex('#838383'),
            ColorFromHex('#f6669d'),
            ColorFromHex('#b1e05f'),
            ColorFromHex('#fff26d'),
            ColorFromHex('#0443ff'),
            ColorFromHex('#f200f6'),
            ColorFromHex('#51ceff'),
            ColorFromHex('#ffffff'),
            ExtendedTerminalColors(
                ColorFromHex('#f9f9f9'), // foregound
                ColorFromHex('#121212'), // background
                ColorFromHex('#ffffff'), // bold
                null, // link
                ColorFromHex('#ffffff'), // selection_background
                ColorFromHex('#000000'), // selection_foreground
                ColorFromHex('#fb0007'), // cursor_background
                ColorFromHex('#ea0009'), // cursor_foreground
                null, // underline
                null)), // tab
        Novel: AnsiColorScheme(
            ColorFromHex('#000000'),
            ColorFromHex('#cc0000'),
            ColorFromHex('#009600'),
            ColorFromHex('#d06b00'),
            ColorFromHex('#0000cc'),
            ColorFromHex('#cc00cc'),
            ColorFromHex('#0087cc'),
            ColorFromHex('#cccccc'),
            ColorFromHex('#808080'),
            ColorFromHex('#cc0000'),
            ColorFromHex('#009600'),
            ColorFromHex('#d06b00'),
            ColorFromHex('#0000cc'),
            ColorFromHex('#cc00cc'),
            ColorFromHex('#0087cc'),
            ColorFromHex('#ffffff'),
            ExtendedTerminalColors(
                ColorFromHex('#3b2322'), // foregound
                ColorFromHex('#dfdbc3'), // background
                ColorFromHex('#8e2a19'), // bold
                null, // link
                ColorFromHex('#a4a390'), // selection_background
                ColorFromHex('#000000'), // selection_foreground
                ColorFromHex('#73635a'), // cursor_background
                ColorFromHex('#000000'), // cursor_foreground
                null, // underline
                null)), // tab
        'One Half Dark': AnsiColorScheme(
            ColorFromHex('#282c34'),
            ColorFromHex('#e06c75'),
            ColorFromHex('#98c379'),
            ColorFromHex('#e5c07b'),
            ColorFromHex('#61afef'),
            ColorFromHex('#c678dd'),
            ColorFromHex('#56b6c2'),
            ColorFromHex('#dcdfe4'),
            ColorFromHex('#282c34'),
            ColorFromHex('#e06c75'),
            ColorFromHex('#98c379'),
            ColorFromHex('#e5c07b'),
            ColorFromHex('#61afef'),
            ColorFromHex('#c678dd'),
            ColorFromHex('#56b6c2'),
            ColorFromHex('#dcdfe4'),
            ExtendedTerminalColors(
                ColorFromHex('#dcdfe4'), // foregound
                ColorFromHex('#282c34'), // background
                ColorFromHex('#abb2bf'), // bold
                null, // link
                ColorFromHex('#474e5d'), // selection_background
                ColorFromHex('#dcdfe4'), // selection_foreground
                ColorFromHex('#a3b3cc'), // cursor_background
                ColorFromHex('#dcdfe4'), // cursor_foreground
                null, // underline
                null)), // tab
        'One Half Light': AnsiColorScheme(
            ColorFromHex('#383a42'),
            ColorFromHex('#e45649'),
            ColorFromHex('#50a14f'),
            ColorFromHex('#c18401'),
            ColorFromHex('#0184bc'),
            ColorFromHex('#a626a4'),
            ColorFromHex('#0997b3'),
            ColorFromHex('#fafafa'),
            ColorFromHex('#4f525e'),
            ColorFromHex('#e06c75'),
            ColorFromHex('#98c379'),
            ColorFromHex('#e5c07b'),
            ColorFromHex('#61afef'),
            ColorFromHex('#c678dd'),
            ColorFromHex('#56b6c2'),
            ColorFromHex('#ffffff'),
            ExtendedTerminalColors(
                ColorFromHex('#383a42'), // foregound
                ColorFromHex('#fafafa'), // background
                ColorFromHex('#abb2bf'), // bold
                null, // link
                ColorFromHex('#bfceff'), // selection_background
                ColorFromHex('#383a42'), // selection_foreground
                ColorFromHex('#bfceff'), // cursor_background
                ColorFromHex('#383a42'), // cursor_foreground
                null, // underline
                null)), // tab
        'Raycast Dark': AnsiColorScheme(
            ColorFromHex('#000000'),
            ColorFromHex('#ff5360'),
            ColorFromHex('#59d499'),
            ColorFromHex('#ffc531'),
            ColorFromHex('#56c2ff'),
            ColorFromHex('#cf2f98'),
            ColorFromHex('#52eee5'),
            ColorFromHex('#ffffff'),
            ColorFromHex('#000000'),
            ColorFromHex('#ff6363'),
            ColorFromHex('#59d499'),
            ColorFromHex('#ffc531'),
            ColorFromHex('#56c2ff'),
            ColorFromHex('#cf2f98'),
            ColorFromHex('#52eee5'),
            ColorFromHex('#ffffff'),
            ExtendedTerminalColors(
                ColorFromHex('#ffffff'), // foregound
                ColorFromHex('#1a1a1a'), // background
                ColorFromHex('#ffffff'), // bold
                null, // link
                ColorFromHex('#333333'), // selection_background
                ColorFromHex('#000000'), // selection_foreground
                ColorFromHex('#cccccc'), // cursor_background
                ColorFromHex('#ffffff'), // cursor_foreground
                null, // underline
                null)), // tab
        Raycast: AnsiColorScheme(
            ColorFromHex('#000000'),
            ColorFromHex('#b12424'),
            ColorFromHex('#006b4f'),
            ColorFromHex('#f8a300'),
            ColorFromHex('#138af2'),
            ColorFromHex('#9a1b6e'),
            ColorFromHex('#3eb8bf'),
            ColorFromHex('#ffffff'),
            ColorFromHex('#000000'),
            ColorFromHex('#b12424'),
            ColorFromHex('#006b4f'),
            ColorFromHex('#f8a300'),
            ColorFromHex('#138af2'),
            ColorFromHex('#9a1b6e'),
            ColorFromHex('#3eb8bf'),
            ColorFromHex('#ffffff'),
            ExtendedTerminalColors(
                ColorFromHex('#000000'), // foregound
                ColorFromHex('#ffffff'), // background
                ColorFromHex('#ffffff'), // bold
                null, // link
                ColorFromHex('#e5e5e5'), // selection_background
                ColorFromHex('#000000'), // selection_foreground
                ColorFromHex('#000000'), // cursor_background
                ColorFromHex('#000000'), // cursor_foreground
                null, // underline
                null)), // tab
        'Red Sands': AnsiColorScheme(
            ColorFromHex('#000000'),
            ColorFromHex('#ff3f00'),
            ColorFromHex('#00bb00'),
            ColorFromHex('#e7b000'),
            ColorFromHex('#0072ff'),
            ColorFromHex('#bb00bb'),
            ColorFromHex('#00bbbb'),
            ColorFromHex('#bbbbbb'),
            ColorFromHex('#555555'),
            ColorFromHex('#bb0000'),
            ColorFromHex('#00bb00'),
            ColorFromHex('#e7b000'),
            ColorFromHex('#0072ae'),
            ColorFromHex('#ff55ff'),
            ColorFromHex('#55ffff'),
            ColorFromHex('#ffffff'),
            ExtendedTerminalColors(
                ColorFromHex('#d7c9a7'), // foregound
                ColorFromHex('#7a251e'), // background
                ColorFromHex('#dfbd22'), // bold
                null, // link
                ColorFromHex('#a4a390'), // selection_background
                ColorFromHex('#000000'), // selection_foreground
                ColorFromHex('#ffffff'), // cursor_background
                ColorFromHex('#000000'), // cursor_foreground
                null, // underline
                null)), // tab
        'Solarized Dark': AnsiColorScheme(
            ColorFromHex('#073642'),
            ColorFromHex('#dc322f'),
            ColorFromHex('#859900'),
            ColorFromHex('#b58900'),
            ColorFromHex('#268bd2'),
            ColorFromHex('#d33682'),
            ColorFromHex('#2aa198'),
            ColorFromHex('#eee8d5'),
            ColorFromHex('#002b36'),
            ColorFromHex('#cb4b16'),
            ColorFromHex('#586e75'),
            ColorFromHex('#657b83'),
            ColorFromHex('#839496'),
            ColorFromHex('#6c71c4'),
            ColorFromHex('#93a1a1'),
            ColorFromHex('#fdf6e3'),
            ExtendedTerminalColors(
                ColorFromHex('#839496'), // foregound
                ColorFromHex('#002b36'), // background
                ColorFromHex('#93a1a1'), // bold
                null, // link
                ColorFromHex('#073642'), // selection_background
                ColorFromHex('#93a1a1'), // selection_foreground
                ColorFromHex('#839496'), // cursor_background
                ColorFromHex('#073642'), // cursor_foreground
                null, // underline
                null)), // tab
        Solarized: AnsiColorScheme(
            ColorFromHex('#002b36'),
            ColorFromHex('#dc322f'),
            ColorFromHex('#859900'),
            ColorFromHex('#b58900'),
            ColorFromHex('#268bd2'),
            ColorFromHex('#d33682'),
            ColorFromHex('#2aa198'),
            ColorFromHex('#eee8d5'),
            ColorFromHex('#073642'),
            ColorFromHex('#cb4b16'),
            ColorFromHex('#586e75'),
            ColorFromHex('#657b83'),
            ColorFromHex('#839496'),
            ColorFromHex('#6c71c4'),
            ColorFromHex('#93a1a1'),
            ColorFromHex('#fdf6e3'),
            ExtendedTerminalColors(
                ColorFromHex('#657b83'), // foregound
                ColorFromHex('#fdf6e3'), // background
                ColorFromHex('#586e75'), // bold
                null, // link
                ColorFromHex('#eee8d5'), // selection_background
                ColorFromHex('#586e75'), // selection_foreground
                ColorFromHex('#657b83'), // cursor_background
                ColorFromHex('#eee8d5'), // cursor_foreground
                null, // underline
                null)), // tab
        SynthwaveAlpha: AnsiColorScheme(
            ColorFromHex('#241b30'),
            ColorFromHex('#e60a70'),
            ColorFromHex('#00986c'),
            ColorFromHex('#adad3e'),
            ColorFromHex('#6e29ad'),
            ColorFromHex('#b300ad'),
            ColorFromHex('#00b0b1'),
            ColorFromHex('#b9b1bc'),
            ColorFromHex('#7f7094'),
            ColorFromHex('#e60a70'),
            ColorFromHex('#0ae4a4'),
            ColorFromHex('#f9f972'),
            ColorFromHex('#aa54f9'),
            ColorFromHex('#ff00f6'),
            ColorFromHex('#00fbfd'),
            ColorFromHex('#f2f2e3'),
            ExtendedTerminalColors(
                ColorFromHex('#f2f2e3'), // foregound
                ColorFromHex('#241b30'), // background
                ColorFromHex('#f2f2e3'), // bold
                null, // link
                ColorFromHex('#6e29ad'), // selection_background
                ColorFromHex('#f2f2e3'), // selection_foreground
                ColorFromHex('#f2f2e3'), // cursor_background
                ColorFromHex('#241b30'), // cursor_foreground
                null, // underline
                null)), // tab
        Synthwave: AnsiColorScheme(
            ColorFromHex('#000000'),
            ColorFromHex('#f6188f'),
            ColorFromHex('#1ebb2b'),
            ColorFromHex('#fdf834'),
            ColorFromHex('#2186ec'),
            ColorFromHex('#f85a21'),
            ColorFromHex('#12c3e2'),
            ColorFromHex('#ffffff'),
            ColorFromHex('#000000'),
            ColorFromHex('#f841a0'),
            ColorFromHex('#25c141'),
            ColorFromHex('#fdf454'),
            ColorFromHex('#2f9ded'),
            ColorFromHex('#f97137'),
            ColorFromHex('#19cde6'),
            ColorFromHex('#ffffff'),
            ExtendedTerminalColors(
                ColorFromHex('#dad9c7'), // foregound
                ColorFromHex('#000000'), // background
                ColorFromHex('#dad9c7'), // bold
                null, // link
                ColorFromHex('#19cde6'), // selection_background
                ColorFromHex('#000000'), // selection_foreground
                ColorFromHex('#19cde6'), // cursor_background
                ColorFromHex('#dad9c7'), // cursor_foreground
                null, // underline
                null)), // tab
        'Tango Dark': AnsiColorScheme(
            ColorFromHex('#000000'),
            ColorFromHex('#d81e00'),
            ColorFromHex('#5ea702'),
            ColorFromHex('#cfae00'),
            ColorFromHex('#427ab3'),
            ColorFromHex('#89658e'),
            ColorFromHex('#00a7aa'),
            ColorFromHex('#dbded8'),
            ColorFromHex('#686a66'),
            ColorFromHex('#f54235'),
            ColorFromHex('#99e343'),
            ColorFromHex('#fdeb61'),
            ColorFromHex('#84b0d8'),
            ColorFromHex('#bc94b7'),
            ColorFromHex('#37e6e8'),
            ColorFromHex('#f1f1f0'),
            ExtendedTerminalColors(
                ColorFromHex('#dbdbe8'), // foregound
                Black, // background
                null, // bold
                null, // link
                White, // selection_background
                null, // selection_foreground
                null, // cursor_background
                White, // cursor_foreground
                null, // underline
                null)), // tab
        Tango: AnsiColorScheme(
            ColorFromHex("#000000"),
            ColorFromHex("#CC0000"),
            ColorFromHex("#4E9A06"),
            ColorFromHex("#C4A000"),
            ColorFromHex("#3465A4"),
            ColorFromHex("#75507B"),
            ColorFromHex("#06989A"),
            ColorFromHex("#D3D7CF"),
            ColorFromHex("#555753"),
            ColorFromHex("#EF2929"),
            ColorFromHex("#8AE234"),
            ColorFromHex("#FCE94F"),
            ColorFromHex("#729FCF"),
            ColorFromHex("#AD7FA8"),
            ColorFromHex("#34E2E2"),
            ColorFromHex("#EEEEEC"),
            ExtendedTerminalColors(
                Black, // foregound
                ColorFromHex('#D3D7CF'), // background
                null, // bold
                null, // link
                White, // selection_background
                null, // selection_foreground
                null, // cursor_background
                Black, // cursor_foreground
                null, // underline
                null)), // tab
        'Tango Adapted': AnsiColorScheme(
            ColorFromHex('#000000'),
            ColorFromHex('#d81e00'),
            ColorFromHex('#5ea702'),
            ColorFromHex('#cfae00'),
            ColorFromHex('#427ab3'),
            ColorFromHex('#89658e'),
            ColorFromHex('#00a7aa'),
            ColorFromHex('#dbded8'),
            ColorFromHex('#686a66'),
            ColorFromHex('#f54235'),
            ColorFromHex('#99e343'),
            ColorFromHex('#fdeb61'),
            ColorFromHex('#84b0d8'),
            ColorFromHex('#bc94b7'),
            ColorFromHex('#37e6e8'),
            ColorFromHex('#f1f1f0'),
            ExtendedTerminalColors(
                ColorFromHex('#000000'), // foregound
                ColorFromHex('#ffffff'), // background
                ColorFromHex('#000000'), // bold
                null, // link
                ColorFromHex('#c1deff'), // selection_background
                ColorFromHex('#000000'), // selection_foreground
                ColorFromHex('#000000'), // cursor_background
                ColorFromHex('#ffffff'), // cursor_foreground
                null, // underline
                null)), // tab
        Ubuntu: AnsiColorScheme(
            ColorFromHex('#2e3436'),
            ColorFromHex('#cc0000'),
            ColorFromHex('#4e9a06'),
            ColorFromHex('#c4a000'),
            ColorFromHex('#3465a4'),
            ColorFromHex('#75507b'),
            ColorFromHex('#06989a'),
            ColorFromHex('#d3d7cf'),
            ColorFromHex('#555753'),
            ColorFromHex('#ef2929'),
            ColorFromHex('#8ae234'),
            ColorFromHex('#fce94f'),
            ColorFromHex('#729fcf'),
            ColorFromHex('#ad7fa8'),
            ColorFromHex('#34e2e2'),
            ColorFromHex('#eeeeec'),
            ExtendedTerminalColors(
                ColorFromHex('#eeeeec'), // foregound
                ColorFromHex('#300a24'), // background
                ColorFromHex('#eeeeec'), // bold
                null, // link
                ColorFromHex('#b5d5ff'), // selection_background
                ColorFromHex('#000000'), // selection_foreground
                ColorFromHex('#bbbbbb'), // cursor_background
                ColorFromHex('#ffffff'), // cursor_foreground
                null, // underline
                null)), // tab

    }
}

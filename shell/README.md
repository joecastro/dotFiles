# dotFiles Shell

Schemes are accumulated from a few sources.

Including:

* <https://github.com/mbadolato/iTerm2-Color-Schemes>

colordefs.jsonnet:

```jsonnet
        '{{ scheme_name }}': AnsiColorScheme(
            ColorFromHex('#{{ Ansi_0_Color.hex }}'),
            ColorFromHex('#{{ Ansi_1_Color.hex }}'),
            ColorFromHex('#{{ Ansi_2_Color.hex }}'),
            ColorFromHex('#{{ Ansi_3_Color.hex }}'),
            ColorFromHex('#{{ Ansi_4_Color.hex }}'),
            ColorFromHex('#{{ Ansi_5_Color.hex }}'),
            ColorFromHex('#{{ Ansi_6_Color.hex }}'),
            ColorFromHex('#{{ Ansi_7_Color.hex }}'),
            ColorFromHex('#{{ Ansi_8_Color.hex }}'),
            ColorFromHex('#{{ Ansi_9_Color.hex }}'),
            ColorFromHex('#{{ Ansi_10_Color.hex }}'),
            ColorFromHex('#{{ Ansi_11_Color.hex }}'),
            ColorFromHex('#{{ Ansi_12_Color.hex }}'),
            ColorFromHex('#{{ Ansi_13_Color.hex }}'),
            ColorFromHex('#{{ Ansi_14_Color.hex }}'),
            ColorFromHex('#{{ Ansi_15_Color.hex }}'),
            ExtendedTerminalColors(
                ColorFromHex('#{{ Foreground_Color.hex }}'), // foregound
                ColorFromHex('#{{ Background_Color.hex }}'), // background
                ColorFromHex('#{{ Bold_Color.hex }}'), // bold
                null, // link
                ColorFromHex('#{{ Selection_Color.hex }}'), // selection_background
                ColorFromHex('#{{ Selected_Text_Color.hex }}'), // selection_foreground
                ColorFromHex('#{{ Cursor_Color.hex }}'), // cursor_background
                ColorFromHex('#{{ Cursor_Text_Color.hex }}'), // cursor_foreground
                null, // underline
                null)), // tab
```

```shell
./gen.py -s "3024 Day" "3024 Night" Andromeda Aurora Cobalt2 Darkside Github "GitHub Dark" Glacier "GruvboxDark" "GruvboxLight" "iTerm2 Default" "iTerm2 Solarized Light" "iTerm2 Solarized Dark" "iTerm2 Tango Dark" "iTerm2 Tango Light" Material "MaterialDark" "Monokai Remastered" "Monokai Soda" "Monokai Vivid" Novel "OneHalfDark" "OneHalfLight" "Raycast_Dark" "Raycast_Light" "Red Sands" "Solarized Dark - Patched" synthwave "SynthwaveAlpha" "Tango Adapted" "Ubuntu"
cat ../colordefs/* > ~/colordef_fragment.jsonnet
```

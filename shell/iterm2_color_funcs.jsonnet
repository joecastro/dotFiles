local color_defs = import './color_definitions.libsonnet';

local iterm_color_keys = {
    "black": "black",
    "blue": "blue",
    "br_black": "bright_black",
    "br_blue": "bright_blue",
    "br_cyan": "bright_cyan",
    "br_green": "bright_green",
    "br_magenta": "bright_magenta",
    "br_red": "bright_red",
    "br_white": "bright_white",
    "br_yellow": "bright_yellow",
    "cyan": "cyan",
    "green": "green",
    "magenta": "magenta",
    "red": "red",
    "white": "white",
    "yellow": "yellow"
};

local changeColorFunctionContentList(colors) =
    local changeColorCommand(iterm_key, color_value) =
        local iterm_value = std.substr(color_value.hexcolor, 1, 6);
        'echo -ne "\\033]1337;SetColors=%s=%s\\007"' % [ iterm_key, iterm_value ];
    [changeColorCommand(k, colors[iterm_color_keys[k]]) for k in std.objectFields(iterm_color_keys)];

local makeChangeColorSchemeFunctionList(name, scheme) =
    [ 'function changeScheme_%s() {' % [name] ]
     + ['    %s' % line for line in changeColorFunctionContentList(scheme)]
     + [ '}', '' ];

std.lines([
    '#! /bin/bash',
    '',
    '#pragma watermark',
    '',
    '#pragma once',
    '',
] + std.flattenArrays([
    makeChangeColorSchemeFunctionList(scheme.key, scheme.value)
    for scheme in std.objectKeysValues(color_defs.Schemes)
]))
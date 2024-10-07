local color_defs = import '../shell/color_definitions.libsonnet';

local makeChangeColorSchemeFunctionList(name, scheme) =
    [ 'alias changeScheme_%s=\'konsoleprofile colors="%s"\'' % [std.strReplace(name, ' ', ''), name] ];

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
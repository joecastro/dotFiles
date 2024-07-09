local color_defs = import '../terminals/color_definitions.libsonnet';

{
    [scheme.key]: scheme.value.printable
    for scheme in std.objectKeysValues(color_defs.Schemes)
}
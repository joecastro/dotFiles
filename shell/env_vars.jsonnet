local sh = import './manifestShellVars.libsonnet';
local env_vars_core = import './env_vars_core.libsonnet';

local localhost_properties = if std.extVar('is_localhost') == 'true'
    then env_vars_core.localhost_properties
    else {};
local localhost_directives = if std.extVar('is_localhost') == 'true'
    then env_vars_core.localhost_directives
    else {};
local localhost_aliases = if std.extVar('is_localhost') == 'true'
    then env_vars_core.localhost_aliases
    else {};

local root = {
    properties: env_vars_core.properties + localhost_properties,
    directives: env_vars_core.directives + localhost_directives,
    aliases: env_vars_core.aliases + localhost_aliases,
};

sh.manifestShellVars(root)

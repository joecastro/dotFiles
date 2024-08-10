local sh = import './manifestShellVars.libsonnet';
local apply_configs = import '../apply_configs.jsonnet';

sh.manifestShellVars(apply_configs.host.env_vars)

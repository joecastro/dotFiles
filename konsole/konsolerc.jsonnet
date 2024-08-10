local konsole_configs = import './KonsoleConfigs.libsonnet';
local apply_configs = import '../apply_configs.jsonnet';

std.manifestIni(konsole_configs.KonsolercIni(apply_configs.host.hostname + '.profile'))
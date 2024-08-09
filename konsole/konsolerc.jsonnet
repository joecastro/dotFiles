local konsole_configs = import './KonsoleConfigs.libsonnet';

std.manifestIni(konsole_configs.KonsolercIni(std.extVar('hostname') + '.profile'))
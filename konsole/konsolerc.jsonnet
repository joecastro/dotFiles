local konsole_configs = import './KonsoleConfigs.libsonnet';

std.manifestIni(konsole_configs.KonsolercIni(konsole_configs.KonsoleProfileIni('GLinux', null, 'Tango')))
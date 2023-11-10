local iterm = import './iterm_core.libsonnet';
local wallpapers = import '../wallpaper/wallpapers.jsonnet';
{
    ZshTheHardWay:: iterm.ItermProfile("Zsh the Hard Way", "FA66AC80-6AAA-4A3B-9CFE-B934F789D5EF", wallpapers.abstract_colorful),
    Profiles: [ self.ZshTheHardWay ],
}
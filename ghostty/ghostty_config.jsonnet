local wallpaper = import '../wallpaper/wallpaper.libsonnet';
local apply_configs = import '../apply_configs.jsonnet';

local host = apply_configs.host;

local config = {
    properties: {
        'font-family': 'CaskaydiaCove Nerd Font Light',
        'font-size': 14,
        'theme': 'Andromeda',
        'window-decoration': 'client',
        'background-image': wallpaper.backgrounds.hokusai_mt_fuji.target_path(host),
        'background-image-fit': 'cover',
        'background-image-opacity': 0.6,
    },
    keybindings: {
        'ctrl+t': 'new_tab',
        'ctrl+w': 'close_surface',
        'ctrl+q': 'close_window',
        'ctrl+shift+tab': 'previous_tab',
        'ctrl+tab': 'next_tab',
        'ctrl+shift+right': 'next_tab',
        'ctrl+shift+left': 'previous_tab',
        'ctrl+shift+c': 'copy_to_clipboard',
        'ctrl+shift+v': 'paste_from_clipboard',
        'shift+F12': 'toggle_quick_terminal'
    }
};

local manifestGhosttyConfig(value) =
    assert std.isObject(value);
    local aux(root) =
        local props = ['%s = %s' % [k, root.properties[k]] for k in std.objectFields(root.properties)];
        local keybindings = ['keybind = %s=%s' % [k, root.keybindings[k]] for k in std.objectFields(root.keybindings)];
        std.lines(props + [''] + keybindings);
    aux(value);

manifestGhosttyConfig(config)
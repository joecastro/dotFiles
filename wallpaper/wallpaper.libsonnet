local apply_configs_core = import '../apply_configs_core.jsonnet';

local BackgroundImageNode(path, blend_percent=0.4) = {
    path: path,
    blend: blend_percent,
    local_path: 'images/' + path,
    target_path(host)::
        host.home + '/' + host.config_dir + '/wallpaper/' + path,
};
local SvgImage(path) = {
    path: path,
    local_path: 'svg/' + path,
    target_path(host)::
        host.home + '/' + host.config_dir + '/svg/' + path,
};
{
    backgrounds: {
        abstract_blue: BackgroundImageNode("abstract_blue.png"),
        abstract_red: BackgroundImageNode("abstract_red.png"),
        abstract_gray: BackgroundImageNode("abstract_gray.png"),
        abstract_colorful: BackgroundImageNode("abstract_colorful.png"),
        abstract_pastel: BackgroundImageNode("abstract_pastel.png", 0.45),
        abstract_purple_blue: BackgroundImageNode("abstract_purple_blue.png", 0.7),
        google_colors: BackgroundImageNode("google_colors.jpg", 0.35),
        quake: BackgroundImageNode("quake_1996.png"),
        under_construction: BackgroundImageNode("under_construction.jpg"),
        hokusai_cranes: BackgroundImageNode("hokusai_cranes.png"),
        hokusai_mt_fuji: BackgroundImageNode("hokusai_mt_fuji.png"),
        hokusai_wave: BackgroundImageNode("hokusai_wave.jpg"),
        dolby: BackgroundImageNode("dolby.jpg", 0.6),
    },

    android_backgrounds: {
        army: BackgroundImageNode("android_army.jpg", 0.6),
        backpack: BackgroundImageNode("android_backpack.jpg"),
        colorful: BackgroundImageNode("android_colorful.jpg"),
        headphones: BackgroundImageNode("android_headphones.jpg"),
        umbrella: BackgroundImageNode("android_umbrella.jpg"),
        wood: BackgroundImageNode("android_wood.jpg", 0.6),
    },

    icons: {
        android: SvgImage("android.svg"),
        bash: SvgImage("bash.svg"),
        google: SvgImage("google_logo.svg"),
        google_cloud: SvgImage("google_cloud_icon.svg"),
        quake: SvgImage("quake.svg"),
        tux: SvgImage("tux_simple.svg"),
        zsh: SvgImage("zsh.svg"),
    },
}

local BackgroundImageNode(path, blend_percent=0.4) =
{
    path: path,
    blend: blend_percent,
    local_path: 'wallpaper/' + path,
};
{
    abstract_blue: BackgroundImageNode("abstract_blue.png"),
    abstract_red: BackgroundImageNode("abstract_red.png"),
    abstract_gray: BackgroundImageNode("abstract_gray.png"),
    abstract_colorful: BackgroundImageNode("abstract_colorful.png"),
    abstract_pastel: BackgroundImageNode("abstract_pastel.png", 0.45),
    abstract_purple_blue: BackgroundImageNode("abstract_purple_blue.png", 0.7),
    android_army: BackgroundImageNode("android_army.jpg", 0.6),
    android_backpack: BackgroundImageNode("android_backpack.jpg"),
    android_colorful: BackgroundImageNode("android_colorful.jpg"),
    android_headphones: BackgroundImageNode("android_headphones.jpg"),
    android_umbrella: BackgroundImageNode("android_umbrella.jpg"),
    android_wood: BackgroundImageNode("android_wood.jpg", 0.6),
    google_colors: BackgroundImageNode("google_colors.jpg", 0.35),
    quake: BackgroundImageNode("quake_1996.png"),
    under_construction: BackgroundImageNode("under_construction.jpg"),
    hokusai_cranes: BackgroundImageNode("hokusai_cranes.png"),
    hokusai_mt_fuji: BackgroundImageNode("hokusai_mt_fuji.png"),
    hokusai_wave: BackgroundImageNode("hokusai_wave.jpg"),
}

local ext_vars = {
    home: std.extVar('home'),
    cwd: std.extVar('cwd'),
    is_macos: std.extVar('kernel') == 'darwin',
    is_linux: std.extVar('kernel') == 'linux',
    is_localhost: std.extVar('is_localhost') == 'true',
    hostname: std.extVar('hostname')
};

local config_dir = '.config/dotShell';

local jsonnet_maps = [
    ['git/gitconfig.jsonnet', 'gen/gitconfig.ini', '.gitconfig'],
    # env_vars needs to be in the home directory for bootstrapping zsh
    ['shell/env_vars.jsonnet', 'gen/env_vars.sh', '.env_vars.sh'],
    ['konsole/konsolerc.jsonnet', 'gen/konsolerc.ini', '.config/konsolerc'],
    ['konsole/konsole_color_funcs.jsonnet', 'gen/konsole_color_funcs.sh', config_dir + '/'],
    ['shell/iterm2_color_funcs.jsonnet', 'gen/iterm2_color_funcs.sh', config_dir + '/'],
];

local jsonnet_localhost_mac_maps = [
    ['vscode/user_settings.jsonnet', 'gen/vscode_user_settings.json', 'Library/Application Support/Code/User/settings.json']
];

local jsonnet_localhost_linux_maps = [
    ['vscode/user_settings.jsonnet', 'gen/vscode_user_settings.json', '.config/Code/User/settings.json']
];

local jsonnet_multi_maps = [
    ['konsole/konsole_configs_multiplex.jsonnet', 'gen/konsole_configs', '.local/share/konsole'],
];

local curl_maps = [
    ['https://raw.githubusercontent.com/git/git/master/contrib/completion/git-prompt.sh', 'curl/git-prompt.sh', config_dir + '/completion/'],
    ['https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash', 'curl/git-completion.bash', config_dir + '/completion/'],
    ['https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.zsh', 'curl/git-completion.zsh', config_dir + '/zfuncs/_git'],
    ['https://iterm2.com/shell_integration/zsh', 'curl/iterm2_shell_integration.zsh', config_dir + '/'],
    ['https://iterm2.com/shell_integration/bash', 'curl/iterm2_shell_integration.bash', config_dir + '/'],
    ['https://raw.githubusercontent.com/eza-community/eza/main/completions/zsh/_eza', 'curl/_eza', config_dir + '/zfuncs/'],
    ['https://raw.githubusercontent.com/mafredri/zsh-async/v1.8.6/async.zsh', 'curl/async.zsh', config_dir + '/zfuncs/async'],
];

local file_maps = [
    ['bash/profile.sh', '.profile'],
    ['bash/bashrc.sh', '.bashrc'],
    ['bash/inputrc.sh', '.inputrc'],
    ['bash/colors.sh', config_dir + '/'],
    ['ghostty/ghostty_config.properties', '.config/ghostty/config'],
    ['ghostty/xterm-ghostty.terminfo', config_dir + '/'],
    ['konsole/konsole_funcs.sh', config_dir + '/'],
    ['shell/env_funcs.sh', config_dir + '/'],
    ['shell/platform.sh', config_dir + '/'],
    ['shell/cache.sh', config_dir + '/'],
    ['shell/icons.sh', config_dir + '/'],
    ['shell/git_funcs.sh', config_dir + '/'],
    ['shell/iterm2_funcs.sh', config_dir + '/'],
    ['shell/macos_funcs.sh', config_dir + '/'],
    ['shell/util_funcs.sh', config_dir + '/'],
    ['shell/android_funcs.sh', config_dir + '/'],
    ['zsh/zshrc.zsh', '.zshrc'],
    ['zsh/zprofile.zsh', '.zprofile'],
    ['zsh/zshenv.zsh', '.zshenv'],
    ['zsh/batcharge.py', config_dir + '/'],
    ['vim/vimrc.vim', '.vimrc'],
    ['tmux/tmux.conf', '.tmux.conf'],
    ['tmux/vscode-tmux.conf', config_dir + '/'],
];

local directory_maps = [
    ['vim/colors', '.vim/colors'],
    ['svg', config_dir + '/svg'],
    ['wallpaper', config_dir + '/wallpaper'],
];

local vim_pack_plugin_start_repos = [
    # Syntax highlighting for AOSP specific files
    'https://github.com/rubberduck203/aosp-vim.git',
    # Lean & mean status/tabline for vim that's light as air
    'https://github.com/vim-airline/vim-airline.git',
    # Kotlin plugin for Vim. Featuring: syntax highlighting, basic indentation, Syntastic support
    'https://github.com/udalov/kotlin-vim.git',
    # A tree explorer plugin for vim.
    'https://github.com/preservim/nerdtree.git',
    # A Vim plugin which shows git diff markers in the sign column
    # and stages/previews/undoes hunks and partial hunks.
    'https://github.com/airblade/vim-gitgutter.git',
    # 💻 Terminal manager for (neo)vim
    'https://github.com/voldikss/vim-floaterm.git',
    # Check syntax in Vim asynchronously and fix files, with Language Server Protocol (LSP) support
    'https://github.com/dense-analysis/ale.git',
    # Neovim plugin for GitHub Copilot
    'https://github.com/github/copilot.vim.git',
    # Vim plugin to diff two directories
    'https://github.com/will133/vim-dirdiff.git',
    # colorschemes for Vim
    'https://github.com/vim/colorschemes.git',
    # Retro groove color scheme for Vim
    'https://github.com/morhetz/gruvbox.git',
    # Jsonnet filetype plugin for Vim.
    'https://github.com/google/vim-jsonnet.git',
];

local vim_pack_plugin_opt_repos = [
    # A dark Vim/Neovim color scheme inspired by Atom's One Dark syntax theme.
    'https://github.com/joshdick/onedark.vim.git'
];

local zsh_plugin_repos = [
    # Fish shell like syntax highlighting for Zsh.
    'https://github.com/zsh-users/zsh-syntax-highlighting.git'
];

local macros = {
    '#pragma once': [
        '[ -n "${PRAGMA_@@FILE_NAME}" ] && return',
        'PRAGMA_@@FILE_NAME=0',
    ],
    '#pragma watermark': [
        '# Generated by dotFiles scripting tools - @@NOW',
    ],
    '#pragma validate-dotfiles': [
        '[[ -e ~/.env_vars.sh ]] || return',
        'source ~/.env_vars.sh',
    ],
    '#pragma requires': [
        'if [[ -f "${DOTFILES_CONFIG_ROOT}/@@PRAGMA_ARG" ]]; then',
        '    source "${DOTFILES_CONFIG_ROOT}/@@PRAGMA_ARG"',
        'else',
        '    echo "ERROR: Missing required file ${DOTFILES_CONFIG_ROOT}/@@PRAGMA_ARG (@@FILE_NAME)" >&2',
        '    return 1',
        'fi',
    ],
    '#pragma wants': [
        'if [[ -f "${DOTFILES_CONFIG_ROOT}/@@PRAGMA_ARG" ]]; then',
        '    source "${DOTFILES_CONFIG_ROOT}/@@PRAGMA_ARG"',
        'else',
        '    echo "WARN: Optional file not found ${DOTFILES_CONFIG_ROOT}/@@PRAGMA_ARG (@@FILE_NAME)" >&2',
        'fi',
    ],
};

local remote_post_install_commands = [
    'tic -x $DOTFILES_CONFIG_ROOT/xterm-ghostty.terminfo',
];

// Colors for less binary
// Source: https://github.com/Valloric/dotfiles/blob/master/less/LESS_TERMCAP
// Source: http://unix.stackexchange.com/a/147
// More info: http://unix.stackexchange.com/a/108840
local less_termcaps_directives = {
    // LESS_TERMCAP_DEBUG: 0, // set this to see tags printed in less.
    LESS_TERMCAP_mb: 'tput bold; tput setaf 2', // green
    LESS_TERMCAP_md: 'tput bold; tput setaf 6', // cyan
    LESS_TERMCAP_me: 'tput sgr0',
    LESS_TERMCAP_so: 'tput bold; tput setaf 3; tput setab 4', // yellow on blue
    LESS_TERMCAP_se: 'tput rmso; tput sgr0',
    LESS_TERMCAP_us: 'tput smul; tput bold; tput setaf 7', // white
    LESS_TERMCAP_ue: 'tput rmul; tput sgr0',
    LESS_TERMCAP_mr: 'tput rev',
    LESS_TERMCAP_mh: 'tput dim',
    LESS_TERMCAP_ZN: 'tput ssubm',
    LESS_TERMCAP_ZV: 'tput rsubm',
    LESS_TERMCAP_ZO: 'tput ssupm',
    LESS_TERMCAP_ZW: 'tput rsupm',
};

local less_termcaps_properties = {
    GROFF_NO_SGR: 1, // For Konsole and Gnome-terminal
    LESS: "--RAW-CONTROL-CHARS",
    // https://stackoverflow.com/questions/1049350/how-to-make-less-indicate-location-in-percentage/19871578#19871578
    MANPAGER: 'less -s -M +Gg',
};

local env_vars = {
    properties: {
        // XDG_CONFIG_HOME: '${XDG_CONFIG_HOME:-$HOME/.config}',
        DOTFILES_CONFIG_ROOT: '$HOME/' + config_dir,
        LSCOLORS: 'GxDxbxhbcxegedabagacad',
        LS_COLORS: 'di=1;36:ln=1;33:so=31:pi=37;41:ex=32:bd=34;46:cd=34;43:su=30;41:sg=30;46:tw=30;42:ow=30;43',
        EDITOR: 'vim',
        EXPECT_NERD_FONTS: '${EXPECT_NERD_FONTS:-0}',
        DOTFILES_INIT_EPOCHREALTIME_START: "${EPOCHREALTIME:-}",
        NVM_DIR: "$HOME/.nvm",
    } + less_termcaps_properties,
    interactive_directives: less_termcaps_directives,
    aliases: {
        '...': 'cd ../..',
    },
    directives: {}
};

local localhost_env_vars = env_vars + {
    properties+: {
        DOTFILES_SRC_HOME: ext_vars.cwd,
    },
    aliases+: {
        dotGo: 'pushd $DOTFILES_SRC_HOME'
    },
};

local Host(hostname, home, icon, color, primary_wallpaper, android_wallpaper) = {
    assert hostname != null || ext_vars.is_localhost,
    assert home != null || ext_vars.is_localhost,
    hostname:
        if hostname != null then hostname
        else ext_vars.hostname,
    home: if home != null then home else ext_vars.home,
    color:: color,
    primary_wallpaper:: primary_wallpaper,
    android_wallpaper:: android_wallpaper,
    icon:: icon,

    is_localhost:: ext_vars.is_localhost,
    is_macos:: $.is_localhost && ext_vars.is_macos,
    is_linux:: $.is_localhost && ext_vars.is_linux,

    config_dir: config_dir,
    curl_maps: curl_maps,
    jsonnet_maps: jsonnet_maps +
        if $.is_macos then jsonnet_localhost_mac_maps else
        if $.is_linux then jsonnet_localhost_linux_maps else [],
    jsonnet_multi_maps: jsonnet_multi_maps,
    directory_maps: directory_maps,
    macros: macros,
    post_install_commands: if $.is_localhost then [] else remote_post_install_commands,
    file_maps: file_maps,

    env_vars:: (if $.is_localhost then localhost_env_vars else env_vars) + {
        properties+: {
            HOST_COLOR: color.hexcolor,
            ANDROID_HOME: if ext_vars.is_macos
                then '~/Library/Android/sdk'
                else '$HOME/android_sdk',
            [if primary_wallpaper != null then 'PRIMARY_WALLPAPER']: primary_wallpaper.target_path($),
            [if android_wallpaper != null then 'ANDROID_WALLPAPER']: android_wallpaper.target_path($),
        },
    },
};

{
    ext_vars: ext_vars,
    hostname: ext_vars.hostname,
    is_macos: ext_vars.is_macos,
    cwd: ext_vars.cwd,

    config_dir: config_dir,

    vim_pack_plugin_start_repos: vim_pack_plugin_start_repos,
    vim_pack_plugin_opt_repos: vim_pack_plugin_opt_repos,
    zsh_plugin_repos: zsh_plugin_repos,

    Host:: Host,
}

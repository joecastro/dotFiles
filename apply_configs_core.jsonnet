{
    file_maps: [
        ['bash/bashrc.sh', '.bashrc'],
        ['bash/profile.sh', '.profile'],
        ['bash/bash_profile.sh', '.bash_profile'],
        ['zsh/zshrc.zsh', '.zshrc'],
        ['zsh/zprofile.zsh', '.zprofile'],
        ['zsh/zshenv.zsh', '.zshenv'],
        ['zsh/android_funcs.zsh', '.android_funcs.zsh'],
        ['zsh/osx_funcs.zsh', '.osx_funcs.zsh'],
        ['zsh/util_funcs.zsh', '.util_funcs.zsh'],
        ['vim/vimrc.vim', '.vimrc'],
        ['vim/colors/molokai.vim', '.vim/colors/molokai.vim'],
        ['tmux/tmux.conf', '.tmux.conf'],
        ['out/gitconfig.ini', '.gitconfig'],
        ['verify_fonts.py', 'dotScripts/verify_fonts.py']
    ],
    vim_pack_plugin_start_repos: [
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
        'https://github.com/dense-analysis/ale.git'
    ],
    vim_pack_plugin_opt_repos: [
        # A dark Vim/Neovim color scheme inspired by Atom's One Dark syntax theme.
        'https://github.com/joshdick/onedark.vim.git'
    ],
    zsh_plugin_repos: [
        # Fish shell like syntax highlighting for Zsh.
        'https://github.com/zsh-users/zsh-syntax-highlighting.git'
    ]
}
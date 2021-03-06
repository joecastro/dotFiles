set nocompatible

if has('win32') || has('win64')
  set runtimepath=$HOME/.vim,$VIM/vimfiles,$VIMRUNTIME,$VIM/vimfiles/after,$HOME/.vim/after
endif

if has("gui_running")
    if has("gui_win32")
        " Assuming a pretty standard Windows install.
        " This makes most of the expected standard keyboard shortcuts work.
        source $VIMRUNTIME/mswin.vim
        behave mswin
        set guifont=Consolas:h11:cANSI
    elseif has("gui_gtk2")
        set guifont=Inconsolata\ 12
    endif
endif

" source ~/extra_commands.vim

set softtabstop=4
set shiftwidth=4
set tabstop=4

set expandtab

set list
set listchars=tab:>-,trail:`

set number
set relativenumber
set numberwidth=4

set encoding=utf-8

map <C-t> <Esc>:tabnew<CR>
map <C-F4> <Esc>:tabclose<CR>

vmap <TAB> :><cr>gv
vmap <S-TAB> :<<cr>gv

set history=700

" Enable filetype plugins
filetype plugin on
filetype indent on

" Set to auto read when a file is changed from the outside
set autoread 

" Set 7 lines to the cursor - when moving vertically using j/k
set so=7

" Turn on the WiLd menu
set wildmenu

" Ignore compiled files
set wildignore=*.o,*~,*.pyc

"Always show current position
set ruler

" Height of the command bar
set cmdheight=1

" A buffer becomes hidden when it is abandoned
set hid

" Configure backspace so it acts as it should act
set backspace=eol,start,indent
set whichwrap+=<,>,h,l

" Ignore case when searching
set ignorecase

" When searching try to be smart about cases
set smartcase

" Highlight search results
set hlsearch

" Makes search act like search in modern browsers
set incsearch

" Don't redraw while executing macros (good performance config)
set lazyredraw

" For regular expressions turn magic on
set magic

" Show matching brackets when text indicator is over them
set showmatch
" How many tenths of a second to blink when matching brackets
set mat=2

" Enable syntax highlighting
syntax enable

colorscheme molokai

set cursorline
set sbr=↪\

" set statusline=%F%m%r%h%w\ [TYPE=Y\ %{&ff]}\ [%l/%L\ (%p%%)]

function! NumberToggle()
  if(&relativenumber == 1)
    set number
  else
    set relativenumber
  endif
endfunc

nnoremap <F2> :call NumberToggle()<CR>


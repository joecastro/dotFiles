set nocompatible

" Ways to update this:
" `:set guifont=*` will display the native font picker.
" Once Vim looks as desired, it can be pasted in INSERT mode by
" `<ctrl-R>=&guifont;`
if has("gui_running")
    if has("gui_win32")
        " Assuming a pretty standard Windows install.
        " This makes most of the expected standard keyboard shortcuts work.
        source $VIMRUNTIME/mswin.vim
        behave mswin
    endif
    set guifont=CaskaydiaCove\ Nerd\ Font\ Light\ 12
endif

" source ~/extra_commands.vim

" Reference chart of values:
"   Ps = 0  -> blinking block.
"   Ps = 1  -> blinking block (default).
"   Ps = 2  -> steady block.
"   Ps = 3  -> blinking underline.
"   Ps = 4  -> steady underline.
"   Ps = 5  -> blinking beam (xterm).
"   Ps = 6  -> steady beam (xterm).
if $LC_TERMINAL ==# 'iTerm2'
    let &t_SI = "\<Esc>]50;CursorShape=1\x7"
    let &t_EI = "\<Esc>]50;CursorShape=0\x7"
else
    let &t_SI = "\e[6 q"
    let &t_EI = "\e[2 q"
endif

set softtabstop=4
set shiftwidth=4
set tabstop=4
set expandtab

if !&diff
    set foldmethod=indent
    set foldcolumn=2
endif

set list
set listchars=tab:>-,trail:`

set relativenumber
set number
set numberwidth=4

set encoding=utf-8

map <C-t> <Esc>:tabnew<CR>
map <C-w> <Esc>:tabclose<CR>

" move among buffers with CTRL
map <C-j> :bnext<CR>
map <C-K> :bprev<CR>

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

" Turn on the Wild menu
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

" Make the escape key more responsive by decreasing the wait time for an
" escape sequence (e.g., arrow keys).
if !has('nvim') && &ttimeoutlen == -1
  set ttimeout
  set ttimeoutlen=100
endif

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

" packadd! onedark.vim
" colorscheme onedark
colorscheme gruvbox
set background=dark

" hi Normal ctermbg=NONE

set cursorline
set sbr=↪\

try
    helptags ALL
catch /E151:/
    echo "Error generating helptags: " . v:exception
endtry

" Airline config

set statusline=%F%m%r%h%w\ [TYPE=%Y\ %{&ff}]\ [%l/%L\ (%p%%)]
" or:
" set statusline=
" set statusline +=%1*\ %n\ %*            buffer number
" set statusline +=%5*%{&ff}%*            file format
" set statusline +=%3*%y%*                file type
" set statusline +=%4*\ %<%F%*            full path
" set statusline +=%2*%m%*                modified flag
" set statusline +=%1*%=%5l%*             current line
" set statusline +=%2*/%L%*               total lines
" set statusline +=%1*%4v\ %*             virtual column number
" set statusline +=%2*0x%04B\ %*          character under cursor

let g:airline#extensions#tabline#enabled = 1 " Enable the list of buffers

if !exists('g:airline_symbols')
    let g:airline_symbols = {}
endif

" powerline symbols
let g:airline_left_sep = ''
let g:airline_left_alt_sep = ''
let g:airline_right_sep = ''
let g:airline_right_alt_sep = ''
let g:airline_symbols.branch = ''
let g:airline_symbols.readonly = ''
let g:airline_symbols.linenr = '☰'
let g:airline_symbols.maxlinenr = ''
let g:airline_symbols.dirty='⚡'

let g:airline_theme='gruvbox'

" let g:airline_left_sep ="\ue0b4"
" let g:airline_right_sep ="\ue0b6"

function! SetAirlinePrompt()
    let g:airline_section_a = airline#section#create(['mode'])
    let g:airline_section_b = airline#section#create([''])
    let g:airline_section_c = airline#section#create(['%F%m%r%h%2'])
    let g:airline_section_x = airline#section#create([''])
    let g:airline_section_y = airline#section#create(['%3p%%'])
    let g:airline_section_z = airline#section#create(['%{line(".")}', ":", '%{col(".")}'])
endfunc

" Floaterm config
let g:floaterm_width = 0.9
" let g:floaterm_height = 0.9

" 0: Clear the gutter
" 1: Show folds and relative line numbers
" 2: 1, but with absolute line numbers
let g:gutter_cycle_state=0
function! CycleGutter()
    let g:gutter_cycle_state += 1
    if (g:gutter_cycle_state == 3)
        let g:gutter_cycle_state=0
    endif

    if (g:gutter_cycle_state == 0)
        set norelativenumber
        set nonumber
        set foldcolumn=0
    elseif (g:gutter_cycle_state == 1)
        set relativenumber
        set number
        set foldcolumn=2
    else
        set norelativenumber
        set number
        set foldcolumn=2
    endif
endfunc

" autocmd BufReadPost * call CycleGutter()

let g:is_background_cleared=0
function! ToggleBackgroundTransparency()
    if (g:is_background_cleared == 0)
        hi Normal ctermbg=NONE
        let g:is_background_cleared=1
    else
        let g:is_background_cleared=0
        set background&
    endif
endfunc

" Function-key mappings
nnoremap <F2> :call CycleGutter()<CR>
nnoremap <F2> :call CycleGutter()<CR>
nnoremap <F5> :NERDTreeToggle<CR>
nnoremap <F8> :call ToggleBackgroundTransparency()<CR>
let g:floaterm_keymap_toggle = '<F12>'


autocmd User AirlineAfterInit call SetAirlinePrompt()

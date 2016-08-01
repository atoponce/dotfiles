colorscheme hybrid                  " set the theme

" must install vim-airline
"   $ git clone https://github.com/bling/vim-airline
" manually copy or symbolic link everything into ~/.vim/
let g:airline#extensions#tabline#enabled = 1

" set the bubblegum.vim airline theme
let g:airline_theme='bubblegum'

if !exists('g:airline_symbols')
  let g:airline_symbols = {}
endif
let g:airline_symbols.space = "\ua0"


nnoremap <Space> za
vnoremap <Space> za

set autoindent                      " auto indent tabs when pressing enter
set colorcolumn=80                  " column warning line at 80 characters
set cryptmethod=blowfish2           " use the blowfish rather than default "zip" method
set expandtab                       " convert tabs to spaces
set guifont=Liberation\ Mono\ 8     " set the appropriate font
set guioptions='aegit'              " set mouse options, and otherwise
set laststatus=2                    " always set a status line at the bottom
set nobackup                        " don't create a .file.swp
set nocompatible                    " don't use strict vi mode with vim and gvim
set nojoinspaces                    " one space after the period joining sentences
set nowrap                          " do not wrap long lines
set number                          " number the lines on the left
set relativenumber                  " show the relative line numbers above and below the cursor
set ruler                           " show the line and column number of the cursor position in the status bar
set shell=/bin/zsh                  " set the default shell
set shiftwidth=4                    " the number of charcters to shift with >> and <<
set smarttab                        " smart backspace for identifying tabs when expandtab is used
set softtabstop=4                   " four characters when the tab key is pressed
set t_Co=256                        " tell vim that 256 colors are available
set tabstop=8                       " if the tab character is identified, use an 8 character width
set textwidth=79                    " wrap text at 75 lines
syntax enable                       " enable syntax highlighting for config files and source code

if has("autocmd")
    """"""""""""""""""""
    " GnuPG Extensions "
    """"""""""""""""""""

    " Tell the GnuPG plugin to armor new files.
    let g:GPGPreferArmor=1

    " Tell the GnuPG plugin to sign new files.
    let g:GPGPreferSign=1

    " Use gpg(2) to take advantage of the agent.
    let g:GPGExecutable="/usr/bin/gpg2"

    " Take advantage of the running agent
    let g:GPGUseAgent=1

    " Override default set of file patterns
    let g:GPGFilePattern='*.\(gpg\|asc\|pgp\|pw\)'

    augroup GnuPGExtra
	" Set extra file options.
        autocmd BufReadCmd,FileReadCmd *.\(pw\) call SetGPGOptions()
	" Automatically close unmodified files after inactivity.
	autocmd CursorHold *.\(pw\) quit
    augroup END

    function SetGPGOptions()
	" Set the filetype for syntax highlighting.
	set filetype=gpgpass
	" Set updatetime to 1 minute.
	set updatetime=300000
	" Fold at markers.
	set foldmethod=marker
	" Automatically close all folds.
	set foldclose=all
	" Only open folds with insert commands.
	set foldopen=insert
    endfunction
endif " has ("autocmd")

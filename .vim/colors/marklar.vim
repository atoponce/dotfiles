" ------------------------------------------------------------------
" Filename:	 marklar.vim
" Last Modified: Nov, 01 2006 (19:34)
" Maintainer:	 SM Smithfield (m_smithfield AT yahoo DOT com)
" Copyright:	 2006 SM Smithfield
"                This script is free software; you can redistribute it and/or 
"                modify it under the terms of the GNU General Public License as 
"                published by the Free Software Foundation; either version 2 of 
"                the License, or (at your option) any later version. 
" Description:   Vim colorscheme file.
" Install:       Put this file in the users colors directory (~/.vim/colors)
"                then load it with :colorscheme marklar
" ------------------------------------------------------------------
hi clear
set background=dark
if exists("syntax_on")
    syntax reset
endif
let g:colors_name = "marklar"
if version >= 700
    hi SpellBad               guisp=#FF0000
    hi SpellCap               guisp=#0000FF
    hi SpellRare              guisp=#ff4046
    hi SpellLocal	      guisp=#000000 ctermbg=0
    hi Pmenu                  guibg=#266955 ctermbg=0 ctermfg=6
    hi PmenuSel               guibg=#0B7260 cterm=bold ctermfg=3
    hi PmenuSbar              guibg=#204d40 ctermbg=6
    hi PmenuThumb             guifg=#38ff56 ctermfg=3
    hi CursorColumn           guibg=#096354
    hi CursorLine             guibg=#096354
    hi Tabline                guifg=bg guibg=fg gui=NONE cterm=reverse,bold ctermfg=NONE ctermbg=NONE
    hi TablineSel             guifg=#20012e guibg=#00a675 gui=bold
    hi TablineFill            guifg=#689C7C
    hi MatchParen             guifg=#38ff56 guibg=#0000ff gui=bold ctermbg=4
endif

hi Comment guifg=#00BBBB guibg=NONE ctermfg=6 cterm=none
hi Constant guifg=#FFFFFF guibg=NONE ctermfg=7 cterm=none
hi Cursor guifg=NONE guibg=#FF0000
hi DiffAdd guifg=fg guibg=#136769 ctermfg=4 ctermbg=7 cterm=none
hi DiffChange guifg=fg guibg=#096354 ctermfg=4 ctermbg=2 cterm=none
hi DiffDelete guifg=fg guibg=#50694A ctermfg=1 ctermbg=7 cterm=none
hi DiffText guifg=#7CFC94 guibg=#096354 ctermfg=4 ctermbg=3 cterm=none
hi Directory guifg=#25B9F8 guibg=NONE ctermfg=2
hi Error guifg=#FFFFFF guibg=#000000 ctermfg=7 ctermbg=0 cterm=bold
hi ErrorMsg guifg=#8eff2e guibg=#204d40
hi FoldColumn guifg=#00BBBB guibg=#204d40
hi Folded guifg=#44DDDD guibg=#204d40 ctermfg=0 ctermbg=8 cterm=bold
hi Identifier guifg=#38FF56 guibg=NONE gui=bold ctermfg=8 cterm=bold
" completely invisible
" hi Ignore guifg=bg guibg=NONE ctermfg=0 
" nearly invisible
hi Ignore guifg=#467C5C guibg=NONE ctermfg=0 
hi IncSearch  guibg=#52891f gui=bold
hi LineNr guifg=#38ff56 guibg=#204d40
hi ModeMsg guifg=#FFFFFF guibg=#0000FF ctermfg=7 ctermbg=4 cterm=bold
hi MoreMsg guifg=#FFFFFF guibg=#00A261 ctermfg=7 ctermbg=2 cterm=bold
hi NonText guifg=#00bbbb guibg=#204d40
hi Normal guifg=#71C293 guibg=#06544a
hi PreProc guifg=#25B9F8 guibg=bg gui=underline ctermfg=2 cterm=underline
hi Question guifg=#FFFFFF guibg=#00A261
hi Search guifg=NONE guibg=#0f7e7b ctermfg=3 ctermbg=0 cterm=bold
hi SignColumn guifg=#00BBBB guibg=#204d40
hi Special guifg=#00FFFF guibg=NONE gui=bold ctermfg=6 cterm=bold
hi SpecialKey guifg=#00FFFF guibg=#266955
hi Statement guifg=#FFFF00 guibg=NONE gui=bold ctermfg=3 cterm=bold
hi StatusLine guifg=#245748 guibg=#71C293 gui=none cterm=reverse
hi StatusLineNC guifg=#245748 guibg=#689C7C gui=none
hi Title guifg=#7CFC94 guibg=NONE gui=bold ctermfg=2 cterm=bold
hi Todo guifg=#FFFFFF guibg=#884400 ctermfg=6 ctermbg=4 cterm=none
hi Type guifg=#FF80FF guibg=bg gui=bold ctermfg=2
hi Underlined guifg=#df820c guibg=NONE gui=underline ctermfg=8 cterm=underline
hi Visual guibg=#0B7260 gui=NONE
hi WarningMsg guifg=#FFFFFF guibg=#FF0000 ctermfg=7 ctermbg=1 cterm=bold
hi WildMenu guifg=#20012e guibg=#00a675 gui=bold ctermfg=none ctermbg=none cterm=bold
"
hi pythonPreCondit ctermfg=2 cterm=none
hi tkWidget guifg=#D5B11C guibg=bg gui=bold ctermfg=7 cterm=bold

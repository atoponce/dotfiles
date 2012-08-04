" Vim color file
" Maintainer:	Ajit J. Thakkar (ajit AT unb DOT ca)
" Last Change:	2003 Sep. 02
" Version:	1.0
" URL:		http://www.unb.ca/chem/ajit/vim.htm

" This GUI-only color scheme has a blue-black background

set background=light
hi clear
if exists("syntax_on")
  syntax reset
endif

let colors_name = "jEdit"

hi Normal	guifg=Black guibg=White

" Groups used in the 'highlight' and 'guicursor' options default value.
hi ErrorMsg	gui=bold guifg=Red guibg=White
hi IncSearch	gui=NONE guibg=LightGreen guifg=Black
hi ModeMsg	gui=NONE guifg=fg guibg=bg
hi StatusLine	gui=NONE guifg=White guibg=#006699
hi StatusLineNC	gui=NONE guifg=#fffffe guibg=#2f2f6b
hi VertSplit	gui=bold guifg=Black guibg=White
hi Visual	gui=reverse guifg=#dbdbdb guibg=Black
hi VisualNOS	gui=underline guifg=fg guibg=bg
hi DiffText	gui=NONE guifg=Yellow guibg=LightSkyBlue4
hi Cursor	guibg=Black guifg=White
hi lCursor	guibg=Cyan guifg=Black
hi Directory	guifg=LightGreen guibg=bg
hi LineNr	guifg=#009966 guibg=bg
hi MoreMsg	gui=NONE guifg=SeaGreen guibg=bg
hi NonText	gui=NONE guifg=Black guibg=White
hi Question	gui=NONE guifg=LimeGreen guibg=bg
hi Search	gui=NONE guifg=SkyBlue4 guibg=Bisque
hi SpecialKey	guifg=Green guibg=bg
hi Title	gui=NONE guifg=#818762 guibg=bg
hi WarningMsg	guifg=Tomato3 guibg=Black
hi WildMenu	gui=NONE guifg=Black guibg=SkyBlue3
hi Folded	gui=bold guifg=#006699 guibg=bg
hi FoldColumn	guifg=DarkBlue guibg=Grey
hi DiffAdd	gui=NONE guifg=Blue guibg=LightCyan
hi DiffChange	gui=NONE guifg=white guibg=LightCyan4
hi DiffDelete	gui=NONE guifg=LightBlue guibg=LightCyan

" Colors for syntax highlighting
hi Constant	gui=bold guifg=#3b8548 guibg=bg
hi String	gui=NONE guifg=#0e8493 guibg=bg
hi Special	gui=NONE guifg=Black guibg=bg
hi Statement	gui=bold guifg=#006699 guibg=bg
"hi Statement	gui=NONE guifg=#d7cd7b guibg=bg
hi Operator	gui=bold guifg=#006699 guibg=bg
hi Ignore	gui=NONE guifg=bg guibg=bg
hi ToDo		gui=NONE guifg=DodgerBlue guibg=bg
hi Error	gui=NONE guifg=Purple guibg=White
hi Comment	gui=NONE guifg=Green guibg=bg
hi Comment	gui=NONE guifg=#cc0000 guibg=bg
hi Identifier	gui=bold guifg=#2f2f6b guibg=bg
hi PreProc	gui=NONE guifg=#2f2f6b guibg=bg
hi Type		gui=bold guifg=#2f2f6b guibg=bg
hi Underlined	gui=underline guifg=fg guibg=bg

" vim: sw=2

" Vim syntax file
" Language: GPG Passwords
" Maintainer: Aaron Toponce
" Latest Revision: 31 December 2015

if exists("b:current_syntax")
    finish
endif

let b:current_syntax = "gpgpass"

syntax case ignore

syntax match gpgpassPasswords "\%(^\s*pass.*:\s\+\)\@<=.*"
highlight gpgpassPasswords ctermbg=red ctermfg=red

syntax match gpgpassKeyword "\v^\s*(pass|password|user|username):"
syntax match gpgpassKeyword "\v^\s*(expire|comment|tag)s?:"
syntax match gpgpassKeyword "\v^\s*(type|url):"
highlight link gpgpassKeyword Keyword

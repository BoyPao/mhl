" License: GPL-3.0-or-later
"
" mhl: Match highlight.
" mhl is a Vim plugin to let match more convenient.
" Match pattern will be highlighted with some colors.
" The basic idea has refered to
" Yuheng Xie's Mark.vim (https://github.com/vim-scripts/Mark).
" To reslove highlight priority problem, mhl use matchadd() rather then
" syntax match.
"
" Copyright (c) 2023 Peng Hao <635945005@qq.com>

"==============================================================================
" Features:
"==============================================================================
" > Highlight match words with colors

"==============================================================================
" Installation:
"==============================================================================
" > Install manually
"     git clone --depth=1 https://github.com/BoyPao/mhl.git
"     cp mhl.vim ~/.vim/plugin
"
" > Install by vim-plug (recommanded)
"     Plug 'BoyPao/mhl'

"==============================================================================
" Commands:
"==============================================================================
" > MhlTriggerMatch
"     To trigger highlight on/off with current word when cursor is.
"     If the word is not highlighted, then it will be highlighted.
"     If the word has highlighted, then the highlight will be cleared.
"
" > MhlClearAllMatch
"     This command will clear all highlight which are triggered on by
"     MhlTriggerMatch.
"

"==============================================================================
" Configurations:
"==============================================================================
" > g:mhlIgnoreCase
"     If the value of g:mhlIgnoreCase is 0, then match will not ignore case.
"     Otherwise, match will ignore case. The default value is 0.

if !exists(':MhlTriggerMatch')
	command! -nargs=? MhlTriggerMatch call s:MHLTriggerMatch(<q-args>)
endif

if !exists(':MhlClearAllMatch')
	command! MhlClearAllMatch call s:MHLClearAllMatch()
endif

if !exists('g:mhlIgnoreCase')
	let g:mhlIgnoreCase = 0
endif

" The first id of MatchColor[id] should equals to s:mhlReserveId + 1
hi MatchColor4 guifg=#0c0d0d guibg=#f04848 guisp=#f04848 gui=NONE ctermfg=232 ctermbg=203 cterm=NONE
hi MatchColor5 guifg=#0c0d0d guibg=#e6ad12 guisp=#e6ad12 gui=NONE ctermfg=232 ctermbg=178 cterm=NONE
hi MatchColor6 guifg=#0c0d0d guibg=#4ce076 guisp=#4ce076 gui=NONE ctermfg=232 ctermbg=78 cterm=NONE
hi MatchColor7 guifg=#0c0d0d guibg=#3774e6 guisp=#3774e6 gui=NONE ctermfg=232 ctermbg=68 cterm=NONE
hi MatchColor8 guifg=#0c0d0d guibg=#ca78de guisp=#ca78de gui=NONE ctermfg=232 ctermbg=176 cterm=NONE
hi MatchColor9 guifg=#0c0d0d guibg=#4ccbeb guisp=#4ccbeb gui=NONE ctermfg=232 ctermbg=81 cterm=NONE

" set 0 to prevent overrule for hlsearch
let s:mhlMatchPriority = 0

" Check match reserve id with cmd:help matchadd
let s:mhlReserveId = 3

" Check match max id with cmd:help matchadd
let s:mhlMaxId = 10

let s:mhlBusyIdDict = {}

let s:mhlIdHistQueue = []

let s:mhlPatternSymbolDict = {
			\ 'wrdS' : '\<',
			\ 'wrdE' : '\>',
			\ 'strS' : '\zs',
			\ 'strE' : '\ze'
			\ }

if version >= 800
	autocmd WinNew /* call s:MHLApplyMatch()
endif

function! s:MHLTriggerMatch(str)
	let type = a:str != '' ? 'str' : 'wrd'
	let tar = type == 'str' ? a:str : expand('<cword>')
	let keys = keys(s:mhlBusyIdDict)
	for key in keys
		if s:MHLIsStrSame(tar, s:mhlBusyIdDict[key])
			call s:MHLClearMatch(key)
			return
		endif
	endfor
	call s:MHLAddMatch(tar, type)
endfunction

function! s:MHLIsStrSame(str1, str2)
	if g:mhlIgnoreCase == 0
		return a:str1 ==# a:str2 ? 1 : 0
	else
		return a:str1 ==? a:str2 ? 1 : 0
	endif
endfunction

function! s:MHLClearAllMatch()
	let keys = keys(s:mhlBusyIdDict)
	for key in keys
		call s:MHLClearMatch(key)
	endfor
endfunction

function! s:MHLClearMatch(id)
	if has_key(s:mhlBusyIdDict, a:id)
		let nr = winnr()
		exe 'windo call s:MHLResetHL(' . a:id . ')'
		exe nr . 'wincmd w'
		call remove(s:mhlBusyIdDict, a:id)
		let idx = index(s:mhlIdHistQueue, str2nr(a:id))
		call remove(s:mhlIdHistQueue, idx)
	endif
endfunction

function! s:MHLResetHL(id)
	let matches = getmatches()
	for item in matches
		let keys = keys(item)
		for key in keys
			if key != 'id'
				continue
			endif
			if item[key] == a:id
				call matchdelete(a:id)
				return
			endif
		endfor
	endfor
endfunction

function! s:MHLAddMatch(str, type)
	let id = s:MHLPickMatchId()
	call s:MHLClearMatch(id)
	let pat = s:MHLGeneratePattern(a:str, a:type)
	let nr = winnr()
	exe 'windo call matchadd("MatchColor' . id . '", "' . pat . '", ' . s:mhlMatchPriority . ', ' . id . ')'
	exe nr . 'wincmd w'
	let s:mhlBusyIdDict[id] = a:str
	call add(s:mhlIdHistQueue, id)
endfunction

function! s:MHLGeneratePattern(str, type)
	let pat = ''
	if a:type != 'wrd' && a:type != 'str'
		return pat
	endif
	let csymbol = g:mhlIgnoreCase ? '\c' : ''
	let ssymbol = csymbol . s:mhlPatternSymbolDict[a:type . 'S']
	let esymbol = s:mhlPatternSymbolDict[a:type . 'E']
	let pat = escape(ssymbol . a:str. esymbol, '\')
	return pat
endfunction

function! s:MHLPickMatchId()
	let maxId = s:MHLGetMaxMatchId()
	let id = s:mhlReserveId + 1
	while id <= maxId
		if has_key(s:mhlBusyIdDict, id)
			let id = id + 1
		else
			return id
		endif
	endwhile
	if id > maxId
		if len(s:mhlIdHistQueue) > 0
			let id = s:mhlIdHistQueue[0]
		else
			let id = s:mhlReserveId + 1
		endif
	endif
	return id
endfunction

function! s:MHLGetMaxMatchId()
	let id = s:mhlReserveId
	while hlexists('MatchColor' . (id + 1))
		let id = id + 1
	endwhile
	if id > s:mhlMaxId
		let id = s:mhlMaxId
	endif
	return id
endfunction

function! s:MHLApplyMatch()
	let keys = keys(s:mhlBusyIdDict)
	for key in keys
		let nr = winnr()
		exe 'windo call s:MHLResetHL(' . key . ')'
		exe 'windo call matchadd("MatchColor' . key . '", "' . s:mhlBusyIdDict[key] . '", ' . s:mhlMatchPriority . ', ' . key . ')'
		exe nr . 'wincmd w'
	endfor
endfunction


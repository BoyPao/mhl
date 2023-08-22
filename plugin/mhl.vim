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

if !exists(':MhlTriggerMatch')
	command! MhlTriggerMatch call <SID>MHLTriggerMatch()
endif

if !exists(':MhlClearAllMatch')
	command! MhlClearAllMatch call <SID>MHLClearAllMatch()
endif

" The first id of MatchColor[id] should equals to g:mhlReserveId + 1
hi MatchColor4 guifg=#0c0d0d guibg=#f04848 guisp=#f04848 gui=NONE ctermfg=232 ctermbg=203 cterm=NONE
hi MatchColor5 guifg=#0c0d0d guibg=#e6ad12 guisp=#e6ad12 gui=NONE ctermfg=232 ctermbg=178 cterm=NONE
hi MatchColor6 guifg=#0c0d0d guibg=#4ce076 guisp=#4ce076 gui=NONE ctermfg=232 ctermbg=78 cterm=NONE
hi MatchColor7 guifg=#0c0d0d guibg=#3774e6 guisp=#3774e6 gui=NONE ctermfg=232 ctermbg=68 cterm=NONE
hi MatchColor8 guifg=#0c0d0d guibg=#ca78de guisp=#ca78de gui=NONE ctermfg=232 ctermbg=176 cterm=NONE
hi MatchColor9 guifg=#0c0d0d guibg=#4ccbeb guisp=#4ccbeb gui=NONE ctermfg=232 ctermbg=81 cterm=NONE

if !exists('g:mhlMatchPriority')
	" set 0 to prevent overrule for hlsearch
	let g:mhlMatchPriority = 0
endif

if !exists('g:mhlReserveId')
	" Check match reserve id with cmd:help matchadd
	let g:mhlReserveId = 3
endif

if !exists('g:mhlMaxId')
	" Check match max id with cmd:help matchadd
	let g:mhlMaxId = 10
endif

let g:mhlBusyIdDict = {}
let g:mhlIdHistQueue = []

autocmd WinNew /* call <SID>MHLApplyMatch()

function! <SID>MHLTriggerMatch()
	let wrd = expand('<cword>')
	let wrd = escape('\<' . wrd. '\>', '\')
	let keys = keys(g:mhlBusyIdDict)
	for key in keys
		if <SID>MHLStrcmp(wrd, g:mhlBusyIdDict[key]) == 0
			call <SID>MHLClearMatch(key)
			return
		endif
	endfor
	call <SID>MHLAddMatch(wrd)
endfunction

function! <SID>MHLStrcmp(str1, str2)
	let lst1 = str2list(a:str1, 1)
	let lst2 = str2list(a:str2, 1)
	let len1 = len(a:str1)
	let len2 = len(a:str2)
	if len1 > len2
		return 1
	elseif len1 < len2
		return -1
	endif
	let idx = 0
	while idx < len1
		let diff = char2nr(lst1[idx]) - char2nr(lst2[idx])
		if diff
			return diff
		endif
		let idx = idx + 1
	endwhile
	return 0
endfunction

function! <SID>MHLClearAllMatch()
	let keys = keys(g:mhlBusyIdDict)
	for key in keys
		call <SID>MHLClearMatch(key)
	endfor
endfunction

function! <SID>MHLClearMatch(id)
	if has_key(g:mhlBusyIdDict, a:id)
		let nr = winnr()
		exe 'windo call <SID>MHLResetHL(' . a:id . ')'
		exe nr . 'wincmd w'
		call remove(g:mhlBusyIdDict, a:id)
		let idx = index(g:mhlIdHistQueue, str2nr(a:id))
		call remove(g:mhlIdHistQueue, idx)
	endif
endfunction

function! <SID>MHLResetHL(id)
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

function! <SID>MHLAddMatch(wrd)
	let id = <SID>MHLPickMatchId()
	call <SID>MHLClearMatch(id)
	let nr = winnr()
	exe 'windo call matchadd("MatchColor' . id . '", "' . a:wrd . '", ' . g:mhlMatchPriority . ', ' . id . ')'
	exe nr . 'wincmd w'
	let g:mhlBusyIdDict[id] = a:wrd
	call add(g:mhlIdHistQueue, id)
endfunction

function! <SID>MHLPickMatchId()
	let maxId = <SID>MHLGetMaxMatchId()
	let id = g:mhlReserveId + 1
	while id <= maxId
		if has_key(g:mhlBusyIdDict, id)
			let id = id + 1
		else
			return id
		endif
	endwhile
	if id > maxId
		if len(g:mhlIdHistQueue) > 0
			let id = g:mhlIdHistQueue[0]
		else
			let id = g:mhlReserveId + 1
		endif
	endif
	return id
endfunction

function! <SID>MHLGetMaxMatchId()
	let id = g:mhlReserveId
	while hlexists('MatchColor' . (id + 1))
		let id = id + 1
	endwhile
	if id > g:mhlMaxId
		let id = g:mhlMaxId
	endif
	return id
endfunction

function! <SID>MHLApplyMatch()
	let keys = keys(g:mhlBusyIdDict)
	for key in keys
		let nr = winnr()
		exe 'windo call <SID>MHLResetHL(' . key . ')'
		exe 'windo call matchadd("MatchColor' . key . '", "' . g:mhlBusyIdDict[key] . '", ' . g:mhlMatchPriority . ', ' . key . ')'
		exe nr . 'wincmd w'
	endfor
endfunction


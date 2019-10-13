let g:statusline_last_loaded = strftime('%s')
let g:orw_last_loaded = strftime('%s')

fun! Sync(file)
	let l:file = '~/.config/nvim/' . (a:file == 'orw' ? 'colors/' : 'plugin/') . a:file . '.vim'
    let l:last_modified = system("stat -c '%Y' " . l:file)
	let l:variable_name = a:file . '_last_loaded'

    if l:last_modified > {'g:'.l:variable_name}
		let {'g:'.l:variable_name} = l:last_modified
		return 1
    endif
endf

fun! SyncColors()
	if Sync('orw') || Sync('statusline')
		exe 'source ~/.config/nvim/plugin/statusline.vim'
	endif
endf

au FocusGained,BufEnter * :call SyncColors()

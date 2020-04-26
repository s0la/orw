func! Term(...)
	let l:orientation = 'sp'

	if len(a:000)
		for arg in a:000
			if arg =~ '^[0-9]\+%\?$'
				let l:size = (arg =~ '%$') ? ((l:orientation == 'sp') ? &lines : &columns) * arg / 100 : arg
				let l:orientation = l:size . l:orientation
			else
				let l:orientation = (arg == 'h') ? "sp" : "vs"
			endif
		endfor
	endif

	exec l:orientation . " | term"

	if exists('l:size')
		call feedkeys('A')
	endif
endf

func! Term(...)
	let l:command = ''
	let l:orientation = 'sp'

	if len(a:000)
		for arg in a:000
			if arg =~ '^[0-9]\+%\?$'
				let l:size = (arg =~ '%$') ? ((l:orientation == 'sp') ? &lines : &columns) * arg / 100 : arg
				let l:orientation = l:size . l:orientation
			elseif arg =~ '[hv]'
				let l:orientation = (arg == 'h') ? "sp" : "vs"
			else
				"let l:command = getbufinfo(a:bufnr)[0]['name']
				let l:command = expand('%:t') . " " . arg

				"if arg =~ 'b'
				"	let l:command += ' && bash'
				"endif
			endif
		endfor
	endif

	exec l:orientation . " | term " . l:command

	if exists('l:size')
		call feedkeys('A')
	endif
endf

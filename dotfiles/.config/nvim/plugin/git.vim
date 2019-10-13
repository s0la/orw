func! CheckIfBufferExists(bufname)
	for buffer in split(execute('ls'), '\n')
		let l:buffer_properties = split(buffer)
		let l:bufnr = str2nr(l:buffer_properties[0])
		let l:active = l:buffer_properties[1] =~ "a"

		if bufname(l:bufnr) == 'git_' . a:bufname && l:active
			call CloseGitOutput()
			return 1
		endif
	endfor

	return 0
endf


func! GitDiff(...)
	if ! CheckIfBufferExists('diff')
		for bufnr in range(1, bufnr('$'))
			if getbufinfo(bufnr)[0]['name'] =~ 'git_diff$'
				exe ':bd! ' . bufnr
			endif
		endfor

		let l:file = expand('%:p')
		let l:repo = system('git rev-parse --show-toplevel')

		let l:repo_length = strlen(l:repo)

		let l:repo_file = l:file[l:repo_length:]

		if a:0 > 0
			let l:reference = a:1 =~? '[0-9a-z]' ? system("git log --oneline --grep " . a:1 . " | awk '{print $1}'")[:-2] : 'master' . a:1
		else
			let l:reference = 'master'
		endif

		diffthis

		exe ':vs git_diff | r !git show ' . l:reference . ':' . l:repo_file
		exe ':norm 1Gdd'
		diffthis
	endif
endf

func! GitLog()
	if ! CheckIfBufferExists('log')
		exe ':sp git_log | r !git log --oneline'
		exe ':norm 1Gdd'
	endif
endf

func! CloseGitOutput()
	if @% =~ 'git_*'
		exe ':q!' . (&diff ? ' | diffoff' : '')
	endif
endf

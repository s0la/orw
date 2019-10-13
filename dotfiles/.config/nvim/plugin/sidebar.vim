set autochdir
set splitright

let g:netrw_altv = 1
let g:netrw_banner = 0
let g:netrw_preview = 0
let g:netrw_keepdir = 0
let g:netrw_winsize = 50
let g:netrw_liststyle = 4
let g:netrw_localrmdir='rm -r'

fun! CalculateSplit()
	let l:winnr = winnr('$')
	let l:width = winwidth(l:winnr)
	let l:height = winheight(l:winnr)

	let g:netrw_preview = l:width > l:height * 3 ? 1 : 0
endf

fun! Sidebar()
	if exists("t:sidebar") && t:sidebar
		exe "Lexplore"
		let t:sidebar = 0
	else
		exe "Lexplore %:p:h | vert resize 30"

		set winfixwidth
		set winfixheight

		let t:sidebar = 1

		call CalculateSplit()
	endif

	exe 'winc ='
endf

let t:winnr = 1
let t:no_previews = 0

func! OpenPreview()
	let l:winnr = winnr('$')

	if l:winnr == 1
		let t:no_previews = 1

		if exists('t:time')
			unlet t:time
		endif
	endif

	if winwidth(l:winnr) == winwidth(l:winnr - 1)
		if t:no_previews
			exe 'winc H | vert resize 30'
		endif
	else
		if t:no_previews
			if exists('t:time') && t:time < strftime('%s')
				exe l:winnr . 'winc w | sp ' . t:last_file
				let t:no_previews = 0
			endif

			let t:time = strftime('%s')
			let l:last_buffer = bufnr('$')
			let t:last_file = getbufinfo(l:last_buffer)[0]['name']
		endif

		if l:winnr > 2
			exe 'winc H | vert resize 30'

			if g:netrw_preview == 0
				exe winnr('$') . 'resize ' . winheight(1) / 2
			else
				exe 'winc ='
			endif
		endif
	endif
endf

au filetype netrw au BufEnter <buffer> call OpenPreview()

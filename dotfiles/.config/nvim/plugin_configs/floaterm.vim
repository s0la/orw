let g:floaterm_keymap_toggle = 'tt'

if winwidth(0) > 350
	let s:width = 0.45
	let s:height = 0.9
	let s:position = 'right'
else
	let s:width = 0.7
	let s:height = 0.5
	let s:position = 'center'
endif

let g:floaterm_autoinsert = 1
let g:floaterm_autoclose = 1
let g:floaterm_height = s:height
let g:floaterm_width = s:width
let g:floaterm_position = s:position
let g:floaterm_title = ''

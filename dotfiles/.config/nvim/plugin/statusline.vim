source ~/.config/nvim/colors/orw.vim

exe 'hi None guibg=none guifg=none'
exe 'hi StatusLight guibg=' . g:lbg . ' guifg=' . g:lfg
exe 'hi Statusline guibg=' . g:slbg . ' guifg=' . g:slfg . ' cterm=none'

let s:settings = ''
let s:settings .= 'NMC.nmbg.;'
let s:settings .= 'IMC.imbg.;'
let s:settings .= 'VMC.vmbg.;'
let s:settings .= 'BC.bcbg.;'
let s:settings .= 'BU.bdbg.;'
let s:settings .= 'r.. RO ;'
let s:settings .= 'mo.m.;'
let s:settings .= 'f.s. %F ;'
let s:settings .= 'b.b.;'
"let s:settings .= 'cpi.lfg.● ;'
let s:settings .= 'cpi.m.● ;'
" let s:settings .= 'c.imbg. ●.f;'
let s:settings .= 'e.f.;'
"let s:settings .= 'ln.fr.  %l:%c  .fr;'
"let s:settings .= 'ln.fr. line: %l, column: %c .fr;'
"let s:settings .= 'ln.fr. ln: %l, cl: %c .fr;'
"let s:settings .= 'ln.fr. %l |┃ %c .fr;'
"let s:settings .= 'ln.vfg. %l│%c .fr;'
"let s:settings .= 'ln.vfg. %l|%c .fr;'
"let s:settings .= 'ln.vmbg. %l/%c .fr;'
let s:settings .= 'ln.vmbg. %l ┃ %c .fr;'
" let s:settings .= 'ln.m.  line %l, column %c  .fr;'
let s:settings .= 't.f. %Y .fr;'

let s:swap_colors = 0
let g:statusline_state = 'full'

let s:separator = "%#None#"

" let s:active_buffer_modules = 'm.b.s.f.c.e.ln'
" let s:active_buffer_modules = 'm.s.b.s.f.c.e.ln'
let s:active_buffer_modules = 'm.b.f.c.e.ln'
"let s:active_buffer_modules = 'f.b.c.e.ln'
"let s:active_buffer_modules = 'f.c.e.ln'
let s:inactive_buffer_modules = 'f.c.e.ln'

func! HideStatusline()
	let g:statusline_state = 'blank'

	set noshowmode
	set noruler
	set laststatus=0
	set noshowcmd
	set cmdheight=1
endf

func! MapModule(module)
	if a:module ==? 'n'
		let l:var = 'None'
	elseif a:module ==? 'm'
		let l:var = 'Mode'
	elseif a:module ==? 'ln'
		let l:var = 'Line'
	elseif a:module ==? 'f'
		let l:var = 'File'
	elseif a:module ==? 't'
		let l:var = 'File_Type'
	elseif a:module ==? 'b'
		let l:var = 'Branch'
	elseif a:module ==? 'e'
		let l:var = 'Expand'
	elseif a:module ==? 'c'
		let l:var = 'Changed'
	elseif a:module ==? 'p'
		let l:var = 'Property'
	elseif a:module ==? 'r'
		let l:var = 'ReadOnly'
	elseif a:module ==? 's'
		let l:var = 'Statusline'
	elseif a:module ==? 'd'
		let l:var = 'StatusDark'
	elseif a:module ==? 'l'
		let l:var = 'StatusLight'
	elseif a:module == 'NMC'
		return s:normal_mode_color
	elseif a:module == 'IMC'
		return s:insert_mode_color
	elseif a:module == 'VMC'
		return s:visual_mode_color
	elseif a:module == 'BC'
		return s:branch_commited_color
	elseif a:module == 'BU'
		return s:branch_uncommited_color
	elseif a:module =~? 'i$'
		return MapModule(a:module[:-3])
	elseif a:module =~? 'r$'
		return MapModule(a:module[:-2]) . 'Reverse'
	else
		let l:var = a:module
	endif

	return a:module =~ '[A-Z]' ? l:var : tolower(l:var)
endf

func! GetBranch(bufnr)
	let l:path = getbufinfo(a:bufnr)[0]['name']
	let l:dir = join(split(l:path, '/')[:-2], '/')

	return system("cd /" . l:dir . "/ && " .
				\"git status -sb 2> /dev/null | " .
				\"awk -F '.' 'NR == 1 { print substr($1, 4) }" .
				\"END { if(NR > 1) print \"*\" }' | xargs -i echo -n '{}'")
endf

func! MakeHiGroup(hi_group, fg, bg, ...)
	if s:swap_colors && !len(a:000)
		let l:fg = a:bg
		let l:bg = a:fg
	else
		let l:fg = a:fg
		let l:bg = a:bg
	endif

	exe 'hi ' . a:hi_group . ' guifg=' . l:fg . ' guibg=' . l:bg
	return a:hi_group
endf

func! ReverseHiGroup(module, hi_group)
	if a:hi_group =~ '[bf]g$'
		let l:bg = g:slbg
		let l:fg = {'g:' . a:hi_group}

		let l:hi_group_name = MapModule(a:module)

		return MakeHiGroup(l:hi_group_name, l:fg, l:bg)
	else
		let l:hi_group = GetHiGroupColors(a:hi_group)

		if len(l:hi_group) > 0
			let l:fg = split(l:hi_group[0], '=')
			let l:bg = split(l:hi_group[1], '=')

			return MakeHiGroup(a:hi_group . 'Reverse', l:bg[1], l:fg[1])
		endif
	endif

	return a:hi_group . 'Reverse'
endf

func! GetHiGroup(module, hi_group)
	if a:hi_group =~ '[bf]g$\|[A-Z]'
		let l:fg = g:slbg
		let l:hi_group = MapModule(toupper(a:module))
		let l:bg = {'g:' . (a:hi_group =~ '[A-Z]' ? MapModule(a:hi_group) : a:hi_group)}

		return MakeHiGroup(l:hi_group, l:fg, l:bg)
	elseif a:hi_group =~ 'r$'
		if a:hi_group[-3:-2] =~ '[bf]g'
			let l:reversed_hi_group = a:hi_group[:-2]
		else
			let l:var_name = 's:' . MapModule(a:hi_group[:-2]) . '_hi_group'
			let l:reversed_hi_group = exists(l:var_name) ? {l:var_name} : MapModule(toupper(a:hi_group[:-2]))
		endif

		return ReverseHiGroup(a:module, l:reversed_hi_group)
	else
		return MapModule(toupper(a:hi_group))
	endif
endf

func! GetHiGroupColors(hi_group)
	return split(execute('hi ' . a:hi_group), '\s\+')[2:]
endf

func! GetAdjacentModuleBg(module, direction)
	let l:index = index(s:modules, a:module)
	let l:adjacent_modules = (a:direction == 'n') ? s:modules[l:index + 1:] : reverse(s:modules[:l:index - 1])

	for module in l:adjacent_modules
		if module != "s"
			let l:adjacent_module = MapModule(module)

			if {'s:' . l:adjacent_module . '_hi_group'} != ''
				let l:adjacent_hi_group = {'s:' . l:adjacent_module . '_hi_group'}

				if l:adjacent_hi_group != 'None'
					break
				endif
			endif
		endif
	endfor

	return GetHiGroupColors(l:adjacent_hi_group)[1]
endf

func! ClearHiGroup(module)
	let l:var = MapModule(a:module)
	let {'s:' . l:var . '_label'} = ''
	let {'s:' . l:var . '_hi_group'} = ''
endf

func! SetModeLabel(label)
	if b:bufnr == bufnr('%')
		let b:mode_label = a:label
	endif
endf

func! SetModeColor(mode, ...)
	call ClearHiGroup('m')

	let l:current_mode = b:bufnr == bufnr('%') ? mode() : 'n'

	if a:mode =~ 'v' && l:current_mode =~ '[ni]'
		return ClearHiGroup('m')
	else
		if l:current_mode == 'n'
			let l:mode = 'normal'
		elseif l:current_mode == 'i'
			let l:mode = 'insert'
		else
			if l:current_mode ==? 'c'
				let l:mode = 'command'
			elseif l:current_mode ==? 'r'
				let l:mode = 'replace'
			else
				let l:mode = 'visual'
			endif
		endif

		let l:mode_label = toupper(l:mode)
		let l:mode_var = 's:' . l:mode . '_mode_color'
		let l:mode_hi_group = exists(l:mode_var) ? {l:mode_var} : {'g:' . l:mode[0] . 'mbg'}
	endif

	let s:mode_label = ' ' . (a:mode =~ 'o' ? l:mode_label[0] : l:mode_label) . ' '

	if a:mode =~ 'i'
		let s:mode_label = a:1[0]
		call MakeIndicator('m' . a:mode[-2:2], l:mode_hi_group)
	else
		let s:mode_hi_group = MakeHiGroup('Mode', g:slbg, l:mode_hi_group)
	endif
endf

func! MakeIndicator(module, hi_group)
	let l:module = a:module[:-2]
	let l:direction = a:module[-1:]

	let l:var = MapModule(l:module)
	let l:hi_group = MapModule(toupper(l:module))

	if a:hi_group =~ 'g$'
		"let l:fg_index = 1
		let l:fg = {'g:' . a:hi_group}
	else
		"let l:fg_index = 0
		let l:fg = split(GetHiGroupColors(toupper(MapModule(a:hi_group)))[1], '=')[1]
	endif

	"echo "CHANGE " . l:fg
	"hi Mode

	"echo "CHANGE " . a:hi_group . " color " . MapModule(a:hi_group) . " " . l:hi_group_var . " " l:fg

	let l:adjacent_module_bg = GetAdjacentModuleBg(l:module, l:direction)
	let l:bg = split(l:adjacent_module_bg, '=')[1]

	"let {'s:' . l:var . '_hi_group'} = MakeHiGroup(l:hi_group, a:hi_group, l:bg, 'i')
	let {'s:' . l:var . '_hi_group'} = MakeHiGroup(l:hi_group, l:fg, l:bg, 'i')
endf

func! SetBranchColor()
	call ClearHiGroup('b')

	let l:branch = getbufvar(b:bufnr, 'branch')

	if l:branch != ''
		"if join(s:modules) !~ 'f.*b'
			"let s:branch_hi_group = GetHiGroup('b', (l:branch =~ '*$') ? s:branch_uncommited_color : s:branch_commited_color)

			if l:branch =~ '*$'
				let s:branch_label = l:branch[:-2]
				let s:branch_hi_group = GetHiGroup('b', s:branch_uncommited_color)
			else
				let s:branch_label = l:branch
				let s:branch_hi_group = GetHiGroup('b', s:branch_commited_color)
			endif

			"if s:swap_colors
			"	let l:file_hi_group = GetHiGroup('f', 'File')
			"	let l:start_bracket = '%#' . l:file_hi_group . '#('
			"	let l:end_branket = '%#' . l:file_hi_group . '#)'
			"	let s:branch_label = l:start_bracket . s:branch_label . l:end_branket
			"else
			"	let s:branch_label = ' ┣ ' . s:branch_label
			"endif

			"if l:branch =~ '*$'
			"	let s:branch_label = ' ┣ ' . l:branch[:-2] . ' '
			"	"let s:branch_hi_group = GetHiGroup('b', s:branch_uncommited_color)
			"else
			"	let s:branch_label = ' ┣ ' . l:branch . ' '
			"	"let s:branch_hi_group = GetHiGroup('b', s:branch_commited_color)
			"endif
		"else

		if join(s:modules) =~ 'f.*b'
			"if s:swap_colors
				if !s:swap_colors
					let s:branch_hi_group = ReverseHiGroup('b', s:branch_hi_group)
				endif
				"let l:file_hi_group = GetHiGroup('f', 'File')
				"let l:start_bracket = '%#' . l:file_hi_group . '#('
				"let l:end_branket = '%#' . l:file_hi_group . '#)'
				let l:start_bracket = '%#File_hi_group#('
				let l:end_bracket = '%#File_hi_group#)'
				let l:branch_hi_group = '%#' . s:branch_hi_group . '#'
				let s:branch_label = l:start_bracket . l:branch_hi_group . s:branch_label . l:end_bracket
			"else
			"	"let s:branch_hi_group = ''
			"	"let s:branch_label = '(' . l:branch . ')'

			"	"let s:branch_hi_group = ReverseHiGroup('b', s:branch_hi_group)

			"	"let l:branch_hi_group = ReverseHiGroup('b', s:branch_hi_group)
			"	"let l:start_bracket = '%#File_hi_group#('
			"	"let l:end_bracket = '%#File_hi_group#)'
			"	"let l:branch_hi_group = '%#' . l:branch_hi_group . '#'
			"	"let s:branch_label = l:start_bracket . l:branch_hi_group . s:branch_label . l:end_bracket
			"	"let s:branch_hi_group = s:file_hi_group
			"endif
		else
			let s:branch_label = ' ┣ ' . s:branch_label . ' '
		endif

			"let s:branch_label = '(' . l:branch . ') '
		"endif
	endif
endf

func! SetReadOnlyColor(module, hi_group, ...)
	if getbufvar(b:bufnr, '&readonly')
		call SetVar(a:module, a:hi_group, a:000)
	else
		call ClearHiGroup('r')
	endif
endf

func! SetExpandColor(module, hi_group)
	call SetVar(a:module, a:hi_group, [ '%=' ])
endf

func! SetChangedColor(module, hi_group, ...)
	if getbufvar(b:bufnr, '&mod')
		"if !exists('s:tab_changed_hi_group')
		"	if a:hi_group =~ 'gr?$\|[A-Z]'
		"		let l:fg = {'g:' . (a:hi_group =~ '[A-Z]' ? MapModule(a:hi_group) : a:hi_group)}
		"	else
		"		let l:hi_group = MapModule(toupper(a:hi_group))
		"		let l:guibg = GetHiGroupColors(l:hi_group)[1]
		"		let l:fg = split(l:guibg, '=')[1]
		"	endif

		"	let s:tab_changed_hi_group = MakeHiGroup('TabChanged', l:fg, g:lbg)
		"	let s:tab_changed_label = a:1
		"endif

		call SetVar(a:module, a:hi_group, a:000)
	else
		call ClearHiGroup('c')
	endif
endf

func! SetVar(module, hi_group, ...)
	let l:module = MapModule(a:module)

	if a:hi_group != ''
		if a:module =~ 'i$'
			"call MakeIndicator(a:module[:-2], {'g:' . a:hi_group})
			call MakeIndicator(a:module[:-2], a:hi_group)
		else
			if a:hi_group =~ 'g$'
				let l:hi_group = GetHiGroup(a:module, a:hi_group)
			else
				let l:reverse = a:hi_group[-1:] == 'r'
				let l:hi_group_var = 's:' . MapModule(l:reverse ? a:hi_group[:-2] : a:hi_group) . '_hi_group'

				if exists(l:hi_group_var)
					let l:hi_group = {l:hi_group_var}

					if l:reverse
						let l:hi_group = ReverseHiGroup(a:module, l:hi_group)
					elseif l:hi_group == ''
						let l:module_hi_group = MapModule(toupper(a:module))
						let l:hi_group = hlexists(l:module_hi_group) ? l:module_hi_group : GetHiGroup(a:module, a:1[1])
					endif
				else
					let l:module_hi_group = GetHiGroup(a:module, a:hi_group)
					let l:hi_group = hlexists(l:module_hi_group) ? l:module_hi_group : MapModule(toupper(a:1[1]))
				endif
			endif

			let {'s:' . l:module . '_hi_group'} = l:hi_group

			"if a:module == 'f'
			"	echo "File " . a:hi_group . " color " . s:mode_hi_group
			"endif

		endif
	else
		call ClearHiGroup(a:module)
	endif

	let {'s:' . l:module . '_label'} = a:1[0]
endf

func! GenerateStatusline(modules, bufnr)
	let b:bufnr = a:bufnr

	if getbufvar(b:bufnr, '&ft') =~ 'netrw\|help' || bufname(b:bufnr) =~ 'git_\(log\|diff\)'
		return '%#None#'
	else
		let s:status = ''
		let s:modules = split(a:modules, '\.')

		if type(s:settings) == 1
			let s:settings = split(s:settings, ';')
		endif

		for color in s:settings
			let l:args = split(color, '\.')

			if l:args[0] =~ '[flt]'
				call SetVar(l:args[0], l:args[1], l:args[2:])
			else
				if l:args[0] == 'm'
					call SetModeColor(l:args[1], l:args[2:])
				elseif l:args[0] =~ 'MC'
					let l:mode = l:args[0][0]
					let l:mode_color_var = l:args[1]

					if l:mode_color_var =~ '[bf]g$'
						let l:mode_color_value = {'g:' . l:mode_color_var}
					else
						let l:mode_color_value = GetHiGroupColors(MapModule(toupper(l:mode_color_var)))[1]
						" let l:mode_color_value = GetHiGroup(l:args[0], MapModule(toupper(l:mode_color_var)))[1]
					endif

					if l:mode == 'N'
						let s:normal_mode_color = l:mode_color_value
					elseif l:mode == 'I'
						let s:insert_mode_color = l:mode_color_value
					elseif l:mode == 'V'
						let s:visual_mode_color = l:mode_color_value
						let s:replace_mode_color = l:mode_color_value
						let s:command_mode_color = l:mode_color_value
					endif
				elseif l:args[0] == 'b'
					call SetBranchColor()
				elseif l:args[0] == 'BC'
					let s:branch_commited_color = l:args[1]
				elseif l:args[0] == 'BU'
					let s:branch_uncommited_color = l:args[1]
				else
					let l:module = l:args[0][0]
					let l:hi_group = MapModule(toupper(l:module))

					call call('Set' . l:hi_group . 'Color', l:args)
				endif
			endif
		endfor

		for module in s:modules
			if module =~ '^s'
				if len(module) > 1
					let l:multi = module[1:]
					let l:expr = printf('%*s', l:multi, ' ')
				endif

				let l:space = (exists('l:expr')) ? substitute('', '', l:expr, '') : ' '

				let s:status .= s:separator . l:space
			else
				let l:var = MapModule(module)
				let l:hi_group = 's:' . l:var . '_hi_group'
				let l:label = 's:' . l:var . '_label'

				let s:status .= (exists(l:hi_group) && {l:hi_group} != '' ? '%#' . {l:hi_group} . '#' : '')
				let s:status .= (exists(l:label) ? {l:label} : '')
			endif
		endfor

		return s:status
	endif
endf

function! SetTabline()
  let l:tabline = ''

  for i in range(tabpagenr('$'))
    let tab = i + 1
    let winnr = tabpagewinnr(tab)
    let buflist = tabpagebuflist(tab)
    let bufnr = buflist[winnr - 1]
    let bufname = bufname(bufnr)
    let bufmodified = getbufvar(bufnr, "&mod")

    let l:tabline .= (tab == tabpagenr() ? '%#TabLineSel#' : '%#TabLine#')
    let l:tabline .= (bufname != '' ? '  ' . fnamemodify(bufname, ':t') : '[No Name] ')

	if bufmodified
		if exists('s:tab_changed_label')
			let l:tabline .= '%#TabChanged#' . s:tab_changed_label
		endif
	endif

	let l:tabline .= '  '
  endfor

  return tabline . '%#None#'
endfunction

func! SetStatus()
	if g:statusline_state != 'blank'
		for buffer in split(execute('ls'), '\n')
			let l:buffer_properties = split(buffer)
			let l:bufnr = str2nr(l:buffer_properties[0])

			if l:buffer_properties[1] =~ '[%#]a'
				if l:bufnr == bufnr('%')
					let l:modules = s:active_buffer_modules
				else
					let l:modules = s:inactive_buffer_modules
				endif

				call setbufvar(l:bufnr, 'branch', GetBranch(l:bufnr))
				call setbufvar(l:bufnr, '&statusline', '%!GenerateStatusline("' . l:modules . '",' . l:bufnr . ')')
			endif
		endfor
	endif
endf

set tabline=%!SetTabline()

"au BufWritePost,BufEnter * call SetStatus()
augroup Statusline
	autocmd!
	autocmd BufWritePost,BufEnter * call SetStatus()
augroup END

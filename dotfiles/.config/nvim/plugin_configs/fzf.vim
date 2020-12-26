function TabName(name)
	let l:buflist = tabpagebuflist(a:name)
	let l:winnr = tabpagewinnr(a:name)
	return fnamemodify(bufname(buflist[winnr - 1]), ':t')
endfunction

function! JumpToTab(line)
	let pair = split(a:line, ' ')
	let cmd = pair[0].'gt'
	execute 'normal' cmd
endfunction

function! FloatingFZF()
	let buf = nvim_create_buf(v:false, v:true)
	call setbufvar(buf, '&signcolumn', 'no')

	let height = float2nr(&lines * 0.5)
	let width = float2nr(&columns * 0.7)
	" let vertical = float2nr(((&lines - height) / 3) * 2)
	" let vertical = float2nr((&lines / 3) * 2)
	let vertical = float2nr((&lines / 3) * 2 - 2)
	let vertical = float2nr((&lines / 5) * 2)
	" let vertical = float2nr(((&lines - height) / 2))
	let horizontal = float2nr((&columns - width) / 2)

	let opts = {
				\ 'relative': 'editor',
				\ 'row': vertical,
				\ 'col': horizontal,
				\ 'width': width,
				\ 'height': height,
				\ 'style': 'minimal'
				\ }

	call nvim_open_win(buf, v:true, opts)
endfunction

let g:fzf_colors = {
  \ 'bg':      ['bg', 'fzf_bg'],
  \ 'hl':      ['fg', 'fzf_fg'],
  \ 'fg':      ['fg', 'fzf_fg'],
  \ 'bg+':     ['bg', 'fzf_bg'],
  \ 'hl+':     ['fg', 'fzf_fgp'],
  \ 'fg+':     ['fg', 'fzf_fgp'],
  \ 'info':    ['bg', 'fzf_bg'],
  \ 'prompt':  ['bg', 'fzf_bg'],
  \ 'border':  ['bg', 'fzf_bg'],
  \ 'header':  ['bg', 'fzf_bg'],
  \ 'pointer': ['fg', 'fzf_hl'],
  \ 'spinner': ['bg', 'fzf_bg'] }

let g:fzf_action = {
  \ 'ctrl-t': 'tab split',
  \ 'ctrl-h': 'split',
  \ 'ctrl-v': 'vsplit' }

let g:fzf_tags_command = 'ctags -R'
let g:fzf_history_dir = '~/.local/share/fzf-history'

let g:fzf_preview_window = ['right:50%', 'ctrl-/']
let g:fzf_layout = { 'window': 'call FloatingFZF()' }
" let g:fzf_layout = {'up':'~90%', 'window': { 'width': 0.7, 'height': 0.5,'yoffset':0.5,'xoffset': 0.5, 'border': 'sharp' } }
" let g:fzf_layout = {'up':'~30%', 'window': { 'width': 1.0, 'height': 0.3, 'border': 'sharp' } }

" let custom_bindings = 'up:space-k,down:space-j'
let $FZF_DEFAULT_OPTS="--layout reverse --margin=2,5"
command! -bang -nargs=? -complete=dir Files call fzf#vim#files(<q-args>, 
	\{ 'options': '--prompt="" --bind=tab:down,ctrl-p:up' },
	\ <bang>0)
	"\{'options': '--prompt="> " --bind=ctrl-n:down,ctrl-p:up --info=inline'}, <bang>0)

let $FZF_DEFAULT_COMMAND =  "find * -path '*/\.*' -prune -o -path 'node_modules/**' -prune -o -path 'target/**' -prune -o -path 'dist/**' -prune -o  -type f -print -o -type l -print 2> /dev/null"

" Get text in files with Rg

let hi_fzf_hl = (execute('hi fzf_hl'))
let match_fg = split(hi_fzf_hl, '=')[1]

command! -bang -nargs=* Rg
  \ call fzf#vim#grep(
  \   'rg --column --line-number --no-heading --color=never --smart-case '.shellescape(<q-args>), 1,
  \   { 'options': '--prompt="" --bind=tab:down,ctrl-p:up
  \   --color="hl:' . match_fg . ',hl+:' . match_fg . '"' },
  \   <bang>0)
  "\   fzf#vim#with_preview(), <bang>0)

" Ripgrep advanced
function! RipgrepFzf(query, fullscreen)
  let command_fmt = 'rg --column --line-number --no-heading --color=always --smart-case %s || true'
  let initial_command = printf(command_fmt, shellescape(a:query))
  let reload_command = printf(command_fmt, '{q}')
  let spec = {'options': ['--phony', '--prompt="", '--query', a:query, '--bind', '--preview-window noborder', 'change:reload:'.reload_command]}
  call fzf#vim#grep(initial_command, 1, fzf#vim#with_preview(spec), a:fullscreen)
endfunction
command! -nargs=* -bang RG call RipgrepFzf(<q-args>, <bang>0)

" Git grep
command! -bang -nargs=* GGrep
  \ call fzf#vim#grep(
  \   'git grep --line-number '.shellescape(<q-args>), 0,
  \   fzf#vim#with_preview({'dir': systemlist('git rev-parse --show-toplevel')[0]}), <bang>0)

let colors_name = "orw"

set background=dark

hi clear

let s:da = '#A3BE8C'
let s:da = '#c6ca67'
let s:dd = '#BF616A'
let s:dd = '#a66c6c'
let s:dc = '#EBCB8B'

let g:bg = 'none'
let g:fg = '#a59ca2'
let g:sfg = '#a270a6'
let g:vfg = '#5b8ea0'
let g:cfg = '#909871'
let g:ifg = '#9291c2'
let g:ffg = '#9e757b'
let g:nbg = 'none'
let g:nfg = '#272b31'
let g:lbg = '#1d2025'
let g:lfg = '#5b8ea0'
let g:syfg = '#909871'
let g:cmfg = '#393c43'
let g:slbg = '#1d2025'
let g:slfg = '#393c43'
let g:fzfhl = '#5b8ea0'
let g:bcbg = '#68658e'
let g:bdbg = '#5b8ea0'
let g:nmbg = '#9291c2'
let g:imbg = '#a270a6'
let g:vmbg = '#9e757b'

"let g:bcbg = '#666662'
"let g:bdbg = '#7ec197'

"let g:nmbg = '#899c9e'
"let g:imbg = '#4e4e4e'
"let g:vmbg = '#4f565e'


let s:term_config = "~/.config/alacritty/alacritty.yml"
let s:bgc = system("awk -F \"'\" '/background/ { print $(NF - 1) }' " . s:term_config)
let s:bgc = g:cmfg

" augroup fix_colors
" 	autocmd!
" 	autocmd ColorScheme * highlight! link @variable Identifier
" 	autocmd ColorScheme * highlight! link @lsp.type.variable Identifier
" augroup end

exe 'hi Error          guibg=none'
exe 'hi MsgArea        guifg='.s:bgc
exe 'hi MoreMsg        guifg='.g:sfg
exe 'hi ErrorMsg       guibg=none                 guifg='.g:ffg
exe 'hi Visual         guibg='.g:slbg
exe 'hi Normal         guifg='.g:fg             .' guibg=none'
exe 'hi Underlined     guifg='.g:fg
exe 'hi NonText        guifg='.g:lbg
exe 'hi SpecialKey     guifg='.g:nfg            .' guibg='.g:lbg

exe 'hi LineNr         guifg='.g:nfg            .' guibg='.g:nbg
exe 'hi StatusLine     guifg='.g:nfg            .' guibg='.g:lbg            .' gui=none'
exe 'hi StatusLineNC   guifg='.g:cfg            .' guibg='.g:lbg            .' gui=none'
exe 'hi VertSplit      guifg='.g:lbg            .' guibg='.g:lbg            .' gui=none'

exe 'hi Pmenu          guifg='.g:slfg           .' guibg='.g:slbg
exe 'hi PmenuSel       guifg='.g:lfg            .' guibg='.g:slbg
exe 'hi WildMenu       guifg='.g:slfg           .' guibg='.g:slbg

exe 'hi TabLine        guifg='.g:slfg           .' guibg='.g:slbg           .' gui=none'
exe 'hi TabLineSel     guifg='.g:lfg            .' guibg='.g:slbg           .' gui=none'
exe 'hi TabLineFill    guifg='.g:slfg           .' guibg='.g:slbg           .' gui=none'

exe 'hi MatchParen     guifg='.g:fg             .' guibg='.g:nfg

exe 'hi Folded         guifg='.g:slfg           ' guibg='.g:slbg            .' gui=none'
exe 'hi FoldColumn     guifg='.g:slfg           ' guibg='.g:slbg            .' gui=none'
exe 'hi SignColumn     guifg='.g:slfg           ' guibg='.g:slbg            .' gui=none'

exe 'hi Comment        guifg='.g:cmfg
exe 'hi TODO           guifg='.g:vfg

exe 'hi Title          guifg='.g:cfg

exe 'hi Constant       guifg='.g:ffg            .' gui=none'
exe 'hi String         guifg='.g:sfg            .' gui=none'
exe 'hi Delimiter      guifg='.g:cfg            .' gui=none'
exe 'hi Special        guifg='.g:cfg            .' gui=none'

exe 'hi Function       guifg='.g:ffg            .' gui=none'
exe 'hi Directory      guifg='.g:ffg            .' gui=none'

exe 'hi Identifier     guifg='.g:ifg            .' gui=none'
exe 'hi Statement      guifg='.g:syfg           .' gui=none'
exe 'hi Conditional    guifg='.g:syfg           .' gui=none'
exe 'hi Repeat         guifg='.g:syfg           .' gui=none'
exe 'hi Structure      guifg='.g:syfg           .' gui=none'

exe 'hi PreProc        guifg='.g:vfg            .' gui=none'
exe 'hi Operator       guifg='.g:fg             .' gui=none'
exe 'hi Type           guifg='.g:syfg           .' gui=none'
exe 'hi Typedef        guifg='.g:syfg           .' gui=none'

exe 'hi DiffAdd        guifg='.s:da             .' guibg='.g:slbg
exe 'hi DiffText       guifg='.s:dc             .' guibg='.g:slbg
exe 'hi DiffChange                                 guibg='.g:slbg
exe 'hi DiffDelete     guifg='.s:dd             .' guibg='.g:slbg

exe 'hi CursorLine     guibg='.g:lbg            .' gui=none'
exe 'hi CursorLineNr   guifg='.g:lfg            .' guibg='.g:lbg

" exe 'hi! fzf_bg guibg='.g:bg
" exe 'hi! fzf_fg guifg='.g:fg
" exe 'hi! fzf_fgp guifg='.g:lbg
" exe 'hi! fzf_hl guifg='.g:lfg
" exe 'hi! fzf_hlp guifg='.g:lfg
" exe 'hi! fzf_info guifg='.g:cmfg
" exe 'hi! fzf_prompt guifg='.g:cmfg
" exe 'hi! fzf_spinner guifg='.g:lfg
" exe 'hi! fzf_pointer guifg='.g:lfg

"exe 'hi! fzf_bg guibg='.g:bg
"exe 'hi! fzf_fg guifg='.g:cmfg
"exe 'hi! fzf_fgp guifg='.g:fg
"exe 'hi! fzf_hl guifg='.g:lfg
"exe 'hi! fzf_hlp guifg='.g:lfg
"exe 'hi! fzf_info guifg='.g:bg
"exe 'hi! fzf_prompt guifg='.g:fg
"exe 'hi! fzf_spinner guifg='.g:fg
"exe 'hi! fzf_pointer guifg='.g:fg

"exe 'hi! fzf_bg guibg='.g:slbg
"exe 'hi! fzf_fg guifg='.g:slfg
"exe 'hi! fzf_bgp guibg='.g:lbg
"exe 'hi! fzf_fgp guifg='.g:ifg
"exe 'hi! fzf_hl guifg='.g:lfg
"exe 'hi! fzf_hlp guifg='.g:lfg
"exe 'hi! fzf_info guifg='.g:slbg
"exe 'hi! fzf_prompt guifg='.g:slfg
"exe 'hi! fzf_spinner guifg='.g:slfg
"exe 'hi! fzf_pointer guifg='.g:slfg
"exe 'hi! fzf_border guibg='.g:lfg

exe 'hi! fzf_bg guibg='.g:slbg
exe 'hi! fzf_fg guifg='.g:slfg
exe 'hi! fzf_bfg guifg='.g:slbg
exe 'hi! fzf_bgp guibg='.g:lbg
exe 'hi! fzf_fgp guifg='.g:fzfhl
exe 'hi! fzf_pfg guifg='.g:ffg
exe 'hi! fzf_mfg guifg='.g:lfg

"exe 'hi! fzf_hl guifg='.g:mfg
"exe 'hi! fzf_hlp guifg='.g:mpfg
"exe 'hi! fzf_border guibg='.g:lfg

"exe 'hi! fzf_bg guibg='.g:lbg
"exe 'hi! fzf_fg guifg='.g:cmfg
"exe 'hi! fzf_fgp guifg='.g:ifg
"exe 'hi! fzf_hl guifg='.g:lfg
"exe 'hi! fzf_hlp guifg='.g:lfg
"exe 'hi! fzf_info guifg='.g:lbg
"exe 'hi! fzf_prompt guifg='.g:cmfg
"exe 'hi! fzf_spinner guifg='.g:cmfg
"exe 'hi! fzf_pointer guifg='.g:cmfg
"exe 'hi! fzf_border guibg='.g:lfg

" exe 'hi! Floaterm guibg='.g:slbg
" exe 'hi! FloatermBorder guibg=none guifg='.g:lfg

exe 'hi! Floaterm guibg='.g:slbg
exe 'hi! FloatermBorder guibg=' . g:slbg . '  guifg='.g:slbg

exe 'hi! Floaterm guibg='.g:lbg
"exe 'hi! FloatermBorder guibg=' . g:lbg . '  guifg='.g:lbg
exe 'hi! FloatermBorder guibg=' . g:slbg . '  guifg='.g:slbg

set cursorline

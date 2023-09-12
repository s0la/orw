let colors_name = "orw"

set background=dark

hi clear

let s:da = '#A3BE8C'
let s:da = '#c6ca67'
let s:dd = '#BF616A'
let s:dd = '#a66c6c'
let s:dc = '#EBCB8B'

let g:bg = 'none'
let g:fg = '#bbcbc3'
let g:ifg = '#aacac3'
let g:vfg = '#7c8da5'
let g:cfg = '#75a082'
let g:ffg = '#9c7da5'
let g:sfg = '#5ec1bf'
let g:nbg = 'none'
let g:nfg = '#212c2c'
let g:lbg = '#172020'
let g:lfg = '#5ec1bf'
let g:syfg = '#75a082'
let g:cmfg = '#2c3939'
let g:slbg = '#172020'
let g:slfg = '#2c3939'
let g:fzfhl = '#5ec1bf'
let g:bcbg = '#9c7da5'
let g:bdbg = '#5ec1bf'
let g:nmbg = '#aacac3'
let g:imbg = '#7c8da5'
let g:vmbg = '#75a082'

"let g:bcbg = '#666662'
"let g:bdbg = '#7ec197'

"let g:nmbg = '#899c9e'
"let g:imbg = '#4e4e4e'
"let g:vmbg = '#4f565e'

exe 'hi Error          guibg=none'
exe 'hi MoreMsg        guifg='.g:sfg
exe 'hi ErrorMsg       guibg=none                 guifg='.g:ffg
exe 'hi Visual         guibg='.g:slbg
exe 'hi Normal         guifg='.g:fg             .' guibg=none'
exe 'hi Underlined     guifg='.g:fg
"exe 'hi NonText        guifg='.g:cmfg
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
exe 'hi! FloatermBorder guibg=' . g:lbg . '  guifg='.g:lbg

set cursorline

colorscheme orw

filetype plugin indent on

let mapleader = "\<Space>"

au OptionSet diff let &cursorline=!v:option_new

source $HOME/.config/nvim/plugin_configs/fzf.vim
source $HOME/.config/nvim/plugin_configs/floaterm.vim
" source $HOME/.config/nvim/plugin_configs/cmp.lua

"set guifont=iosevka-orw-regular:h8
"set guifont=iosevka-orw-regular:h8
set completeopt=menu,menuone,noselect
set notermguicolors

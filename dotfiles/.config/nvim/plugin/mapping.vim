"visual mode
vnoremap . :normal . <cr>

"terminal mode
tnoremap <Esc> <C-\><C-n>

"normal mode
noremap <leader>s :so %<cr>
noremap <leader>l :call GitLog()<cr>
noremap <leader>d :call GitDiff()<cr>
noremap <leader>n :set relativenumber!<cr>
noremap <leader>x :silent! !chmod +x %<cr>
noremap <leader>q :call CloseGitOutput()<cr>
noremap <leader>f :silent! call Sidebar()<cr>
noremap <leader>r :so ~/.config/nvim/init.vim<cr>

"insert mode
inoremap <expr><TAB> pumvisible() ? "\<C-n>" : "\<TAB>"

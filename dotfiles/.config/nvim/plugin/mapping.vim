"visual mode
vnoremap . :normal . <cr>

"terminal mode
tnoremap <Esc> <C-\><C-n>

"normal mode
noremap <silent> <leader>s :so %<cr>
"noremap <silent> <leader>l :call GitLog()<cr>
noremap <silent> <leader>d :call GitDiff()<cr>
noremap <silent> <leader>t :call Term()<cr>
noremap <silent> <leader>vt :call Term('v')<cr>
noremap <silent> <leader>n :set relativenumber!<cr>
noremap <silent> <leader>x :silent! !chmod +x %<cr>
noremap <silent> <leader>q :call CloseGitOutput()<cr>
" noremap <silent> <leader>f :silent! call Sidebar()<cr>
noremap <silent> <leader>r :so ~/.config/nvim/init.vim<cr>

"command! -nargs=* >leader>tea split | terminal <args>
command! -nargs=* Tre :call Term(<args>)

"resizing
noremap <silent> <C-j> :resize +3<cr>
noremap <silent> <C-k> :resize -3<cr>
noremap <silent> <C-h> :vert resize +3<cr>
noremap <silent> <C-l> :vert resize -3<cr>

"insert mode
inoremap <expr><TAB> pumvisible() ? "\<C-n>" : "\<TAB>"

"resizing
inoremap <silent> <C-j> <C-o>:resize +3<cr>
inoremap <silent> <C-k> <C-o>:resize -3<cr>
inoremap <silent> <C-h> <C-o>:vert resize +3<cr>
inoremap <silent> <C-l> <C-o>:vert resize -3<cr>

vnoremap <silent> <C-j> :m +1<cr><S-v>
vnoremap <silent> <C-k> :m -2<cr><S-v>
"inoremap <silent> <C-j> <C-o>:m +1<cr>
"inoremap <silent> <C-k> <C-o>:m -2<cr>

"insert mode
"inoremap ,, <C-x><C-o><C-r>=pumvisible() ? "\<lt>Down>\<lt>C-p>\<lt>Down>" : ""<CR>
inoremap <silent> <C-k> <C-n><C-r>=pumvisible() ? "\<lt>Up>\<lt>C-p>\<lt>Up>" : ""<CR>
inoremap <silent> <C-j> <C-n><C-r>=pumvisible() ? "\<lt>Down>\<lt>C-p>\<lt>Down>" : ""<CR>
"inoremap ,: <C-x><C-f><C-r>=pumvisible() ? "\<lt>Down>\<lt>C-p>\<lt>Down>" : ""<CR>
"inoremap ,= <C-x><C-l><C-r>=pumvisible() ? "\<lt>Down>\<lt>C-p>\<lt>Down>" : ""<CR>

"fzf
map <leader>f :Files<CR>
map <leader>b :Buffers<CR>
map <leader>b :BLines<CR>
nnoremap <leader>g :Rg<CR>
nnoremap <leader>t :Tags<CR>
nnoremap <leader>m :Marks<CR>
nnoremap <silent> <leader>t :call fzf#run(fzf#wrap({
			\   'source':  map(range(1, tabpagenr('$')), 'v:val." "." ".TabName(v:val)'),
			\   'sink':    function('JumpToTab') }))<CR>

au TermOpen * tnoremap <Esc> <c-\><c-n>
au FileType fzf tunmap <Esc>

" Vundle
set nocompatible 
filetype off 
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()
" alternatively, pass a path where Vundle should install plugins
"call vundle#begin('~/some/path/here')
" let Vundle manage Vundle, required
Plugin 'gmarik/Vundle.vim'
Plugin 'junegunn/fzf.vim'
Plugin 'tpope/vim-commentary'
Plugin 'christoomey/vim-tmux-navigator'
Plugin 'benmills/vimux'
Plugin 'raimondi/delimitmate'
Plugin 'godlygeek/tabular'
Plugin 'chaoren/vim-wordmotion'
Plugin 'scrooloose/nerdtree'
Plugin 'nanotech/jellybeans.vim'
" add all your plugins here (note older versions of Vundle
" used Bundle instead of Plugin)
" All of your Plugins must be added before the following line
call vundle#end()            " required
filetype plugin indent on    " required
" Vundle End

" Vim Settings
let mapleader=","
set noswapfile
set backspace=indent,eol,start
set lazyredraw
set nu
set encoding=utf-8
syntax on

" colors
set t_Co=256
set background=dark
colorscheme jellybeans

" split locations
set splitbelow
set splitright 

" split navigation
nnoremap <C-J> <C-W><C-J>
nnoremap <C-K> <C-W><C-K>
nnoremap <C-L> <C-W><C-L>
nnoremap <C-H> <C-W><C-H>

" vim split binds
nmap <Leader>= :vs<CR>
nmap <Leader>- :sv<CR>

" comfy save/quit binds
" just allows caps
command! Q q
command! W w
command! Wq wq
command! WQ wq
nmap Q  <silent>
nmap q: <silent>
nmap K <silent

" remap visual line down
nnoremap j gj
nnoremap k gk

" search settings
set incsearch
set hlsearch
" Map end search/stop highlighting
nnoremap <silent> <Esc><Esc> <Esc>:nohlsearch<CR><Esc>

" esc/save/quit maps
inoremap jj <Esc>
map ff :w! <CR>
map qq :q <CR>

" Default and file specific tab stops
set tabstop=4 softtabstop=4 shiftwidth=4 expandtab
au BufNewFile,BufRead *.py set tabstop=4 softtabstop=4 shiftwidth=4 expandtab autoindent fileformat=unix
au BufNewFile,BufRead *.c set tabstop=4 softtabstop=4 shiftwidth=4 expandtab autoindent fileformat=unix
au BufNewFile,BufRead *.md set tabstop=2 softtabstop=2 shiftwidth=2 expandtab autoindent fileformat=unix

" Python Commands
au FileType python map <leader>r :!python3 %<CR>
au FileType python map <leader>t :!pytest -vv<CR>

" C Commands
au FileType c map <leader>r :!make run<CR>
au FileType cpp map <leader>r :!make run<CR>

" Shell
au FileType sh map <leader>r :! sh %<CR>

" Vimux Commands
map <leader>vp :VimuxPromptCommand<CR>
map <leader>vv :VimuxRunLastCommand<CR>

" nerdtree 
nmap <leader>t :NERDTreeToggle<CR>

" FZF (replaces Ctrl-P, FuzzyFinder and Command-T)
set rtp+=/usr/local/opt/fzf
set rtp+=~/.fzf
nmap ; :Buffers<CR>
nmap <Leader>r :Tags<CR>
nmap <Leader>p :Files<CR>
nmap <Leader>a :Rg!<CR>
let $FZF_DEFAULT_COMMAND = 'rg --files --follow --hidden -g "!{.git,node_modules}/*" 2>/dev/null'
command! -bang -nargs=* Rg
  \ call fzf#vim#grep(
  \   'rg --column --line-number --no-heading --color=always --smart-case -g "!{*.lock,*-lock.json}" '.shellescape(<q-args>), 1,
  \   <bang>0 ? fzf#vim#with_preview('up:40%')
  \           : fzf#vim#with_preview('right:50%:hidden', '?'),
  \   <bang>0)

" FZF color scheme updater from https://github.com/junegunn/fzf.vim/issues/59
function! s:update_fzf_colors()
  let rules =
  \ { 'fg':      [['Normal',       'fg']],
    \ 'bg':      [['Normal',       'bg']],
    \ 'hl':      [['String',       'fg']],
    \ 'fg+':     [['CursorColumn', 'fg'], ['Normal', 'fg']],
    \ 'bg+':     [['CursorColumn', 'bg']],
    \ 'hl+':     [['String',       'fg']],
    \ 'info':    [['PreProc',      'fg']],
    \ 'prompt':  [['Conditional',  'fg']],
    \ 'pointer': [['Exception',    'fg']],
    \ 'marker':  [['Keyword',      'fg']],
    \ 'spinner': [['Label',        'fg']],
    \ 'header':  [['Comment',      'fg']] }
  let cols = []
  for [name, pairs] in items(rules)
    for pair in pairs
      let code = synIDattr(synIDtrans(hlID(pair[0])), pair[1])
      if !empty(name) && code != ''
        call add(cols, name.':'.code)
        break
      endif
    endfor
  endfor
  let s:orig_fzf_default_opts = get(s:, 'orig_fzf_default_opts', $FZF_DEFAULT_OPTS)
  let $FZF_DEFAULT_OPTS = s:orig_fzf_default_opts .
        \ (empty(cols) ? '' : (' --color='.join(cols, ',')))
endfunction

" DelimitMate
let delimitMate_expand_cr = 1
augroup mydelimitMate
  au!
  au FileType markdown let b:delimitMate_nesting_quotes = ["`"]
  au FileType tex let b:delimitMate_quotes = ""
  au FileType tex let b:delimitMate_matchpairs = "(:),[:],{:},`:'"
  au FileType python let b:delimitMate_nesting_quotes = ['"', "'"]
  au FileType scm let b:delimitMate_matchpairs = "(:)"
  au FileType scm let b:delimitMate_autoClose=1
augroup END

augroup _fzf
  autocmd!
  autocmd VimEnter,ColorScheme * call <sid>update_fzf_colors()
augroup END

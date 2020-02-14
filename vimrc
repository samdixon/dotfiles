set nocompatible "vundle
filetype off "vundle

" Vundle Start
" set the runtime path to include Vundle and initialize
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()

" alternatively, pass a path where Vundle should install plugins
"call vundle#begin('~/some/path/here')

" let Vundle manage Vundle, required
Plugin 'gmarik/Vundle.vim'
Plugin 'junegunn/fzf.vim'
Plugin 'junegunn/goyo.vim'
Plugin 'junegunn/seoul256.vim'
Plugin 'tpope/vim-commentary'
Plugin 'christoomey/vim-tmux-navigator'
Plugin 'fatih/vim-go'
Plugin 'benmills/vimux'
Plugin 'raimondi/delimitmate'
Plugin 'godlygeek/tabular'
Plugin 'chaoren/vim-wordmotion'
Plugin 'xavierd/clang_complete'
Plugin 'shougo/deoplete.nvim'
Plugin 'kjssad/quantum.vim'


" add all your plugins here (note older versions of Vundle
" used Bundle instead of Plugin)


" All of your Plugins must be added before the following line
call vundle#end()            " required
filetype plugin indent on    " required
" Vundle End

let g:deoplete#enable_at_startup = 1
set termguicolors

let mapleader=","
set noswapfile
set backspace=indent,eol,start
set lazyredraw
set nu

" colors
set t_Co=256
set background=light
let g:seoul256_background = 255
colorscheme seoul256-light

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

" remap visual line down
nnoremap j gj
nnoremap k gk

" search settings
set incsearch
set hlsearch
" Map no highlight
nnoremap <silent> <Esc><Esc> <Esc>:nohlsearch<CR><Esc>

" esc/save/quit maps
inoremap jj <Esc>
map ff :w! <CR>
map qq :q <CR>

set tabstop=4 softtabstop=4 shiftwidth=4 expandtab
au BufNewFile,BufRead *.py set tabstop=4 softtabstop=4 shiftwidth=4 expandtab autoindent fileformat=unix
au BufNewFile,BufRead *.go set tabstop=4 softtabstop=4 shiftwidth=4 expandtab autoindent fileformat=unix
au BufNewFile,BufRead *.c set tabstop=4 softtabstop=4 shiftwidth=4 expandtab autoindent fileformat=unix

set encoding=utf-8
syntax on


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

" comfy save/quit binds
" just allows caps
command! Q q
command! W w
command! Wq wq
command! WQ wq
nmap Q  <silent>
nmap q: <silent>
nmap K <silent


nmap cw ce
" Go specific commands
au FileType go map <leader>r :!go run %<CR>
au FileType go map <leader>b <Plug>(go-build)
au FileType go map <leader>t <Plug>(go-test)
au FileType go map <leader>c <Plug>(go-coverage)
call deoplete#custom#option('omni_patterns', { 'go': '[^. *\t]\.\w*' })

" Python Commands
au FileType python map <leader>r :!python3 %<CR>
au FileType python map <leader>t :!pytest -vv<CR>
call deoplete#custom#option('omni_patterns', { 'python': '[^. *\t]\.\w*' })

" Ruby Commands
au FileType ruby map <leader>r :!ruby %<CR>

" JS Commands
au FileType javascript map <leader>r :!node %<CR>

" C Commands
au FileType c map <leader>r :!make run<CR>
" path to directory where library can be found
let g:clang_library_path='/usr/lib/llvm-7/lib/libclang.so.1'
au FileType cpp map <leader>r :!make run<CR>

" PHP
au FileType php map <leader>r :!php %<CR>

" Scheme
au FileType scheme map <leader>r :!scheme --quiet < %<CR>
au FileType scheme map <leader>t :!scheme < %<CR>

" Vimux Commands
map <leader>vp :VimuxPromptCommand<CR>
map <leader>vv :VimuxRunLastCommand<CR>

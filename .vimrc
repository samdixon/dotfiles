let data_dir = has('nvim') ? stdpath('data') . '/site' : '~/.vim'
if empty(glob(data_dir . '/autoload/plug.vim'))
  silent execute '!curl -fLo '.data_dir.'/autoload/plug.vim --create-dirs  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif
call plug#begin()
Plug 'gmarik/Vundle.vim'
Plug 'junegunn/fzf.vim'
Plug 'tpope/vim-commentary'
Plug 'christoomey/vim-tmux-navigator'
Plug 'raimondi/delimitmate'
Plug 'chaoren/vim-wordmotion'
Plug 'sheerun/vim-polyglot'
Plug 'neovim/nvim-lspconfig'
Plug 'nvim-lua/completion-nvim'
Plug 'hrsh7th/cmp-nvim-lsp'
Plug 'hrsh7th/nvim-cmp'
call plug#end()

lua require("lsp_config")

" Vim Settings
let mapleader=","
set noswapfile
set backspace=indent,eol,start
set lazyredraw
set number
set encoding=utf-8
set ruler
syntax on

set noshowmode
set laststatus=2

" colors
set t_Co=256

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

" Default and file specific tab stops
set tabstop=4 softtabstop=4 shiftwidth=4 expandtab
au BufNewFile,BufRead *.py set tabstop=4 softtabstop=4 shiftwidth=4 expandtab autoindent fileformat=unix
au BufNewFile,BufRead *.c set tabstop=4 softtabstop=4 shiftwidth=4 expandtab autoindent fileformat=unix
au BufNewFile,BufRead *.md set tabstop=2 softtabstop=2 shiftwidth=2 expandtab autoindent fileformat=unix
au BufNewFile,BufRead *.html,*.htm,*.shtml,*.stm set ft=jinja

" various filesettings
au FileType python map <leader>r :!python3 %<CR>
au FileType python map <leader>t :!pytest -vv<CR>
au FileType php map <leader>r :!php %<CR>
au FileType ruby map <leader>r :!ruby %<CR>
au FileType c map <leader>r :!gcc % && ./a.out<CR>
au FileType go map <leader>r :GoRun %<CR>
au FileType sh map <leader>r :! sh %<CR>

" FZF
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

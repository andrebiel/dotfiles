:let mapleader = " "

set path+=**
set nocompatible             
set encoding=UTF-8
set number relativenumber
set tabstop=4 softtabstop=4
set shiftwidth=4    
set expandtab
set autoindent
set copyindent
set ttimeoutlen=50 
set timeoutlen=1000
set smartindent
set termguicolors
set hidden
set background=dark
set nobackup
set nowritebackup
set noswapfile
set cmdheight=1
set updatetime=300
set nohlsearch
set noerrorbells
set nowrap
set incsearch
set scrolloff=8
set signcolumn=yes
set completeopt=menuone,noselect
set shortmess+=c " Don't pass messages to ins-completion-menu
set guicursor=

" wild, Ignores
set wildmode=longest,list,full
set wildmenu
set wildignore+=*.pyc
set wildignore+=*_build/*
set wildignore+=**/coverage/*
set wildignore+=**/node_modules/*
set wildignore+=**/android/*
set wildignore+=**/ios/*
set wildignore+=**/.git/*


filetype off
syntax enable
filetype plugin indent on

" Vundle Plugin Manager
call plug#begin('~/.vim/plugged')
Plug 'marko-cerovac/material.nvim'
Plug 'altercation/vim-colors-solarized'
Plug 'tpope/vim-surround'
Plug 'nvim-lua/popup.nvim'
Plug 'nvim-lua/plenary.nvim'
Plug 'nvim-telescope/telescope.nvim'
Plug 'tpope/vim-commentary'
Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}  
Plug 'gruvbox-community/gruvbox'
Plug 'mhartington/oceanic-next'
Plug 'glepnir/galaxyline.nvim' , {'branch': 'main'}
Plug 'preservim/nerdtree'
Plug 'neovim/nvim-lspconfig'
Plug 'sbdchd/neoformat'
Plug 'ryanoasis/vim-devicons'
Plug 'hrsh7th/cmp-nvim-lsp'
Plug 'hrsh7th/cmp-buffer'
Plug 'hrsh7th/cmp-path'
Plug 'hrsh7th/cmp-cmdline'
Plug 'hrsh7th/nvim-cmp'
" Snippets
Plug 'SirVer/ultisnips'
Plug 'honza/vim-snippets'
Plug 'fhill2/telescope-ultisnips.nvim'
Plug 'quangnguyen30192/cmp-nvim-ultisnips'
" GIT
Plug 'TimUntersberger/neogit'
Plug 'evanleck/vim-svelte', {'branch': 'main'}
Plug 'github/copilot.vim'
" Files
Plug 'ThePrimeagen/harpoon'
call plug#end()

" ------------------------------------------------------
" KeyMaps
" ------------------------------------------------------

" Harpoon
nnoremap <leader>a :lua require("harpoon.mark").add_file()<CR>
nnoremap <leader>je :lua require("harpoon.ui").toggle_quick_menu()<CR>
nnoremap <leader>jf :lua require("harpoon.ui").nav_file(1)<CR>
nnoremap <leader>jd :lua require("harpoon.ui").nav_file(2)<CR>
nnoremap <leader>js :lua require("harpoon.ui").nav_file(3)<CR>
nnoremap <leader>ja :lua require("harpoon.ui").nav_file(4)<CR>
nnoremap <leader>jj :lua require("harpoon.term").gotoTerminal(1)<CR>
nnoremap <leader>jk :lua require("harpoon.term").gotoTerminal(2)<CR>

nnoremap qqq :qa!<CR>
nnoremap <C-s> :w!<CR>
nnoremap <Leader>+ :vertical resize +5<CR>
nnoremap <Leader>- :vertical resize -5<CR>
" Lit shit from theprimeagen
vnoremap J :m '>+1<CR>gv=gv
vnoremap K :m '<-2<CR>gv=gv
nnoremap Y yg$
nnoremap n nzzzv
nnoremap N Nzzzv
nnoremap J mzJ`z

" LSP
nnoremap gd <cmd>Telescope lsp_definitions<cr>
nnoremap gr <cmd>Telescope lsp_references<cr>
nnoremap gi <cmd>Telescope lsp_implementations<cr>
nnoremap <leader>ga <cmd>Telescope lsp_code_actions<cr>
nnoremap <leader>ds <cmd>Telescope lsp_document_symbols<cr>
nnoremap <leader>ws <cmd>Telescope lsp_workspace_symbols<cr>
nnoremap <leader>si <cmd>lua vim.lsp.buf.signature_help()<cr>
nnoremap <leader>rn <cmd>lua vim.lsp.buf.rename()<cr>
nnoremap K <cmd>lua vim.lsp.buf.hover()<cr>
nnoremap [d <cmd>lua vim.lsp.diagnostic.goto_prev()<CR>
nnoremap ]d <cmd>lua vim.lsp.diagnostic.goto_next()<CR>
    
" Telescope
nnoremap <leader>ft <cmd>lua require('karllson.telescope').file_tree()<cr>
nnoremap <leader>fb <cmd>lua require('karllson.telescope').file_browser()<cr>
nnoremap <leader>ct <cmd>lua require('karllson.telescope').current_tree()<cr>
nnoremap <leader>gc <cmd>lua require('karllson.telescope').grep_current()<cr>
nnoremap <leader>fg <cmd>lua require('karllson.telescope').git_files()<cr>
nnoremap <leader>ff <cmd>lua require('karllson.telescope').find_files()<cr>
nnoremap <leader>gg <cmd>lua require('karllson.telescope').grep()<cr>

" Nerdtree
nnoremap <C-t> :NERDTreeToggle<CR>
" nnoremap <leader>tf :NERDTreeFocus<CR>
nnoremap <leader>tt :NERDTreeFind<CR>

" Snippets
let g:UltiSnipsExpandTrigger="<tab>"
let g:UltiSnipsJumpForwardTrigger="<c-b>"
let g:UltiSnipsJumpBackwardTrigger="<c-z>"
let g:UltiSnipsSnippetDirectories=['~/dotfiles/snippets']
nnoremap <leader>sn <cmd>lua require'telescope'.extensions.ultisnips.ultisnips{}<cr>

" Copy to and from clipboard
nnoremap <leader>yy "+y
vnoremap <leader>yy "+y
nnoremap <leader>pp "+p
vnoremap <leader>pp "+p

tnoremap <Esc> <C-\><C-n>

let g:NERDTreeWinSize=80
let g:NERDTreeWinPos = "right"

" Theme
colorscheme gruvbox

augroup highlight_yank
    autocmd!
    autocmd TextYankPost * silent! lua require'vim.highlight'.on_yank({timeout = 40})
augroup END

augroup KARLLSON
    au BufWritePre * try | undojoin | Neoformat | catch /E790/ | Neoformat | endtry
augroup END

lua require("karllson.statusline")
lua require("karllson.lsp")
lua require("karllson.telescope")
lua require("karllson.treesitter")
lua require("karllson.snippets")
lua require("karllson.git")
lua require("karllson.harpoon")

let g:neoformat_php_phpcsfixer = {
    \ 'exe': 'php-cs-fixer',
    \ 'args': ['fix', '-q'],
    \ 'replace': 1,
    \ }

let g:neoformat_enabled_php = ['phpcsfixer']
let g:neoformat_enabled_typescript = ['prettier']


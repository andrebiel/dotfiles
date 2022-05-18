:let mapleader = " "

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
Plug 'preservim/nerdtree'
Plug 'neovim/nvim-lspconfig'
Plug 'sbdchd/neoformat'
Plug 'ryanoasis/vim-devicons'
Plug 'hrsh7th/cmp-nvim-lsp'
Plug 'hrsh7th/cmp-buffer'
Plug 'hrsh7th/cmp-path'
Plug 'hrsh7th/cmp-cmdline'
Plug 'hrsh7th/nvim-cmp'
Plug 'TimUntersberger/neogit'
Plug 'evanleck/vim-svelte', {'branch': 'main'}
Plug 'github/copilot.vim'
Plug 'ThePrimeagen/harpoon'
Plug 'nvim-lualine/lualine.nvim'
Plug 'tami5/lspsaga.nvim'
Plug 'leafOfTree/vim-svelte-plugin'
Plug 'marko-cerovac/material.nvim'
Plug 'L3MON4D3/LuaSnip'
Plug 'onsails/lspkind.nvim'
call plug#end()

" ------------------------------------------------------
" KeyMaps
" ------------------------------------------------------

nnoremap qqq :qa!<CR>
noremap <C-s> :w!<CR>
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
nnoremap <leader>ga <cmd>Lspsaga code_action<cr>
vnoremap <leader>ga <cmd>Lspsaga code_action<cr>
nnoremap <leader>si <cmd>lua vim.lsp.buf.signature_help()<cr>
nnoremap <leader>rn <cmd>lua vim.lsp.buf.rename()<cr>
" nnoremap <leader>rn <cmd>Lspsaga rename<cr>
nnoremap K <cmd>Lspsaga hover_doc<cr>
nnoremap [d <cmd>Lspsaga diagnostic_jump_prev<CR>
nnoremap ]d <cmd>Lspsaga diagnostic_jump_next<CR>
nnoremap <leader>ds <cmd>Telescope lsp_document_symbols<cr>
nnoremap <leader>ws <cmd>Telescope lsp_workspace_symbols<cr>

" copilot
imap <silent><script><expr> <C-Y> copilot#Accept("\<TAB>")
let g:copilot_no_tab_map = v:true

" Splits
nnoremap <C-J> <C-W><C-J>
nnoremap <C-K> <C-W><C-K>
nnoremap <C-L> <C-W><C-L>
nnoremap <C-H> <C-W><C-H>
nnoremap <Leader>+ :vertical resize +5<CR>
nnoremap <Leader>- :vertical resize -5<CR>

" Neogit
nnoremap <leader>it :Neogit<cr>

" Nerdtree
nnoremap <C-t> :NERDTreeToggle<CR>
" nnoremap <leader>tf :NERDTreeFocus<CR>
nnoremap <leader>tt :NERDTreeFind<CR>

" Copy to and from clipboard
nnoremap <leader>yy "+y
vnoremap <leader>yy "+y
nnoremap <leader>pp "+p
vnoremap <leader>pp "+p

tnoremap <Esc> <C-\><C-n>

let g:NERDTreeWinSize=80
let g:NERDTreeWinPos = "right"

" Theme
let g:oceanic_next_terminal_bold = 1
let g:oceanic_next_terminal_italic = 1
colorscheme OceanicNext
" colorscheme material
" let g:material_style = "oceanic"
" colorscheme gruvbox

augroup highlight_yank
    autocmd!
    autocmd TextYankPost * silent! lua require'vim.highlight'.on_yank({timeout = 40})
augroup END

augroup KARLLSON
    au BufWritePre * try | undojoin | Neoformat | catch /E790/ | Neoformat | endtry
augroup END

lua require("karllson.snippets")

let g:neoformat_php_phpcsfixer = {
    \ 'exe': 'php-cs-fixer',
    \ 'args': ['fix', '-q'],
    \ 'replace': 1,
    \ }

let g:neoformat_enabled_php = ['phpcsfixer']
let g:neoformat_enabled_typescript = ['prettier']


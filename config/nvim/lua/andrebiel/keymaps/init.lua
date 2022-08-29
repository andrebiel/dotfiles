local key = require("andrebiel.helpers.keymap")

key.nnoremap("<C-t>", key.exec_command(":NvimTreeToggle"))
key.nnoremap("<leader>tt", key.exec_command(":NvimTreeFindFile"))

key.nnoremap("qqq", key.exec_command(":qa!"))
key.nnoremap("<C-s>", key.exec_command(":w!"))

-- Lit shit from theprimeagen
key.vnoremap("J", key.exec_command(":m", ">+1<CR>gv=gv"))
key.vnoremap("K", key.exec_command(":m", "<-2<CR>gv=gv"))
key.nnoremap("Y", "yg$")
key.nnoremap("n", "nzzzv")
key.nnoremap("N", "Nzzzv")
key.nnoremap("J", "mzJ`z")

-- LSP
key.nnoremap("gd", key.exec_command(":Telescope lsp_definitions"))
key.nnoremap("gr", key.exec_command(":Telescope lsp_references"))
key.nnoremap("gi", key.exec_command(":Telescope lsp_implementations"))
key.nnoremap("<leader>ga", key.exec_command(":Lspsaga code_action"))
key.vnoremap("<leader>ga", key.exec_command(":Lspsaga code_action"))
key.nnoremap("<leader>si", key.exec_command(":lua vim.lsp.buf.signature_help()"))
key.nnoremap("<leader>rn", key.exec_command("lua vim.lsp.buf.rename()"))
key.nnoremap("K", key.exec_command(":Lspsaga hover_doc"))
key.nnoremap("[d", key.exec_command(":Lspsaga diagnostic_jump_prev"))
key.nnoremap("]d", key.exec_command(":Lspsaga diagnostic_jump_next"))
key.nnoremap("<leader>ds", key.exec_command(":Telescope lsp_document_symbols"))
key.nnoremap("<leader>ws", key.exec_command(":Telescope lsp_workspace_symbols"))

-- Splits
-- nnoremap <C-J> <C-W><C-J>
-- nnoremap <C-K> <C-W><C-K>
-- nnoremap <C-L> <C-W><C-L>
-- nnoremap <C-H> <C-W><C-H>
-- nnoremap <Leader>+ :vertical resize +5<CR>
-- nnoremap <Leader>- :vertical resize -5<CR>

-- Neogit
-- nnoremap <leader>it :Neogit<cr>

-- Copy to and from clipboard
-- nnoremap <leader>yy "+y
-- vnoremap <leader>yy "+y
-- nnoremap <leader>pp "+p
-- vnoremap <leader>pp "+p

-- tnoremap <Esc> <C-\><C-n>

-- let g:NERDTreeWinSize=80
-- let g:NERDTreeWinPos = "right"
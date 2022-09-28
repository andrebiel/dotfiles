local key = require("andrebiel.helpers.keymap")

key.nnoremap("<C-t>", key.exec_command(":NvimTreeToggle"))
key.nnoremap("<leader>tt", key.exec_command(":NvimTreeFindFile"))

key.nnoremap("qqq", key.exec_command(":qa!"))
key.nnoremap("<C-s>", key.exec_command(":w!"))

-- Lit shit from theprimeagen
key.vnoremap("J", ":m >+1<CR>gv=gv")
key.vnoremap("K", ":m <-2<CR>gv=gv")
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
key.nnoremap('<C-J>', '<C-W><C-J>')
key.nnoremap('<C-K>', '<C-W><C-K>')
key.nnoremap('<C-L>', '<C-W><C-L>')
key.nnoremap('<C-H>', '<C-W><C-H>')

-- Neogit
key.nnoremap('<leader>it', key.exec_command(':Neogit'))

-- Copy to and from clipboard
key.nnoremap('<leader>yy', '"+y')
key.vnoremap('<leader>yy', '"+y')
key.nnoremap('<leader>pp', '"+p')
key.vnoremap('<leader>pp', '"+p')

-- Terminal escape
key.tnoremap('<Esc>', '<C-\\><C-n>');

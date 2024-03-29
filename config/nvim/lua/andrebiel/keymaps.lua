vim.keymap.set("n", "qqq", "<cmd>:qa!<CR>")
vim.keymap.set("n", "<C-s>", "<cmd>:w!<CR>")
vim.keymap.set("n", "<leader>dd", function() vim.diagnostic.open_float(0, { scope = 'line' }) end)
vim.keymap.set("n", "<leader>bd", function() require("telescope.builtin").diagnostics({bufnr = 0}) end)

vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")
vim.keymap.set("n", "J", "mzJ`z")
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")

vim.keymap.set("n", "<C-J>", "<C-W><C-J>")
vim.keymap.set("n", "<C-K>", "<C-W><C-K>")
vim.keymap.set("n", "<C-L>", "<C-W><C-L>")
vim.keymap.set("n", "<C-H>", "<C-W><C-H>")

vim.keymap.set("n", "<C-J>", "<C-W><C-J>")
vim.keymap.set("n", "<C-K>", "<C-W><C-K>")
vim.keymap.set("n", "<C-L>", "<C-W><C-L>")
vim.keymap.set("n", "<C-H>", "<C-W><C-H>")

vim.keymap.set("n", '<leader>yy', '"+y')
vim.keymap.set("v", '<leader>yy', '"+y')
vim.keymap.set("n", '<leader>pp', '"+p')
vim.keymap.set("v", '<leader>pp', '"+p')


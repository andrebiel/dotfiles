-- format the shit on save
vim.api.nvim_exec([[
  augroup KARLLSON_LSP_ACM
    autocmd!
    autocmd BufWritePre * undojoin | Neoformat
  augroup END
]], false)

local augroup = vim.api.nvim_create_augroup
local MyGroup = augroup('AndreBiel', {})

local autocmd = vim.api.nvim_create_autocmd
local yank_group = augroup('HighlightYank', {})

autocmd('TextYankPost', {
    group = yank_group,
    pattern = '*',
    callback = function()
        vim.highlight.on_yank({
            higroup = 'IncSearch',
            timeout = 40,
        })
    end,
})

autocmd({"BufWritePre"}, {
    group = MyGroup,
    pattern = "*",
    command = [[%s/\s\+$//e]],
})

autocmd('DiagnosticChanged', {
  callback = function(args)
    local diagnostics = args.data.diagnostics
    vim.pretty_print(diagnostics)
  end,
})

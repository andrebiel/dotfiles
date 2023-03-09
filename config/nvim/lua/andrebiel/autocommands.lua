local augroup = vim.api.nvim_create_augroup
local MyGroup = augroup('AndreBiel', {})

local autocmd = vim.api.nvim_create_autocmd
local yank_group = augroup('HighlightYank', {})
local fmt_group = augroup("fmt", { clear = true })

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
  end,
})

autocmd(
    { "BufWritePre" },
    {
        pattern = { "*" },
        command = "try | undojoin | Neoformat | catch /E790/ | Neoformat | endtry",
        group = fmt_group
    }
)

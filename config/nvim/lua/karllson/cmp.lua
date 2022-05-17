local cmp = require('cmp') -- autocomplete

local ok, lspkind = pcall(require, "lspkind")
if not ok then
  return
end

lspkind.init()

cmp.setup({
    snippet = {
        expand = function(args)
            require("luasnip").lsp_expand(args.body)
        end,
    },

    mapping = {
        ['<C-u>'] = cmp.mapping.scroll_docs(-4),
        ['<C-d>'] = cmp.mapping.scroll_docs(4), 
        ['<C-Space>'] = cmp.mapping.complete(),
        ['<C-e>'] = cmp.mapping.close(),
        ['<CR>'] = cmp.mapping.confirm({ select = true }),
        ["<C-k>"] = cmp.mapping.select_prev_item(),
        ["<C-j>"] = cmp.mapping.select_next_item(),
    },

    sources = cmp.config.sources({
        { name = 'path' },
        { name = 'cmdline' },
        { name = 'nvim_lsp' },
        { name = "luasnip" },
        { name = "buffer", keyword_length = 5 },
    }),

    formatting = {
        format = lspkind.cmp_format {
            with_text = true,
            menu = {
                buffer = "[buf]",
                nvim_lsp = "[LSP]",
                nvim_lua = "[api]",
                path = "[path]",
                luasnip = "[snip]",
                gh_issues = "[issues]",
                tn = "[TabNine]",
            },
        },
    },
})

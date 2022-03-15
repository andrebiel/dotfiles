local lspconfig = require('lspconfig')
local cmp = require('cmp') -- autocomplete
-- local saga = require 'lspsaga'

local root_pattern = lspconfig.util.root_pattern
local on_attach = function(client, bufnr)

if client.resolved_capabilities.document_highlight then
    vim.api.nvim_exec([[
      hi LspReferenceRead cterm=bold ctermbg=red guibg=#4e4e4e
      hi LspReferenceText cterm=bold ctermbg=red guibg=#4e4e4e
      hi LspReferenceWrite cterm=bold ctermbg=red guibg=#4e4e4e
      augroup lsp_document_highlight
        autocmd! * <buffer>
        autocmd CursorHold <buffer> lua vim.lsp.buf.document_highlight()
        autocmd CursorMoved <buffer> lua vim.lsp.buf.clear_references()
      augroup END
    ]], false)
    end
end

--------------------------------------------------------------------------------------
-- CMP AUTOCOMPLETE
--------------------------------------------------------------------------------------
  -- Setup nvim-cmp.
cmp.setup({
    snippet = {
        -- REQUIRED - you must specify a snippet engine
        expand = function(args)
        vim.fn["UltiSnips#Anon"](args.body) -- For `ultisnips` users.
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
        { name = 'nvim_lsp' },
        { name = 'ultisnips' }, -- For ultisnips users.
    }, {
        { name = 'buffer' },
    })
})

-- Use buffer source for `/` (if you enabled `native_menu`, this won't work anymore).
cmp.setup.cmdline('/', {
    sources = {
        { name = 'buffer' }
    }
})

-- Use cmdline & path source for ':' (if you enabled `native_menu`, this won't work anymore).
cmp.setup.cmdline(':', {
    sources = cmp.config.sources({
        { name = 'path' }
    }, {
        { name = 'cmdline' }
    })
})

--------------------------------------------------------------------------------------
-- Server Setups
--------------------------------------------------------------------------------------
local capabilities = require('cmp_nvim_lsp').update_capabilities(vim.lsp.protocol.make_client_capabilities())

lspconfig.tsserver.setup({
    filetypes = {
      "javascript",
      "javascriptreact",
      "javascript.jsx",
      "typescript",
      "typescriptreact",
      "typescript.tsx"
    },
    on_attach = on_attach,
    capabilities = capabilities
})

lspconfig.intelephense.setup({
    on_attach = on_attach,
    capabilities = capabilities
})

lspconfig.pylsp.setup{
    on_attach = on_attach,
    capabilities = capabilities
}

lspconfig.gopls.setup{
    on_attach = on_attach,
    capabilities = capabilities
}

require'lspconfig'.tailwindcss.setup{}

--------------------------------------------------------------------------------------
-- LSP Saga
--------------------------------------------------------------------------------------
-- saga.init_lsp_saga()

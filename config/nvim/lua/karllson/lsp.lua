local lspconfig = require('lspconfig')
local saga = require 'lspsaga'

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

require"lspconfig".svelte.setup{
    on_attach = on_attach,
    capabilities = capabilities
}

require'lspconfig'.tailwindcss.setup{}

--------------------------------------------------------------------------------------
-- LSP Saga
--------------------------------------------------------------------------------------
saga.init_lsp_saga{
    code_action_icon = "",
    error_sign = "",
    warn_sign = "",
    hint_sign = "",
    infor_sign = "",
}

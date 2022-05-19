local runtime_path = vim.split(package.path, ';')
table.insert(runtime_path, "lua/?.lua")
table.insert(runtime_path, "lua/?/init.lua")

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

-- TYPESCRIPT
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

-- PHP INTELE
lspconfig.intelephense.setup({
    on_attach = on_attach,
    capabilities = capabilities
})

-- PYTHON
lspconfig.pylsp.setup{
    on_attach = on_attach,
    capabilities = capabilities
}

-- GOLANG
lspconfig.gopls.setup{
    on_attach = on_attach,
    capabilities = capabilities
}

-- SVELTE
require"lspconfig".svelte.setup{
    on_attach = on_attach,
    capabilities = capabilities
}

-- TAILWIND
require'lspconfig'.tailwindcss.setup{}

-- LUA
require'lspconfig'.sumneko_lua.setup {
    capabilities = capabilities,
    settings = {
    Lua = {
      runtime = {
        -- Tell the language server which version of Lua you're using (most likely LuaJIT in the case of Neovim)
        version = 'LuaJIT',
        -- Setup your lua path
        path = runtime_path,
      },
      diagnostics = {
        -- Get the language server to recognize the `vim` global
        globals = {'vim'},
      },
      workspace = {
        -- Make the server aware of Neovim runtime files
        library = vim.api.nvim_get_runtime_file("", true),
      },
      -- Do not send telemetry data containing a randomized but unique identifier
      telemetry = {
        enable = false,
      },
    },
  },
}

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

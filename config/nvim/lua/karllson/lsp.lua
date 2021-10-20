local nvim_lsp = require('lspconfig')
local root_pattern = nvim_lsp.util.root_pattern
local on_attach = function(client, bufnr)

-- autocomplete
require'compe'.setup {
  enabled = true;
  autocomplete = true;
  debug = false;
  min_length = 1;
  preselect = 'enable';
  throttle_time = 80;
  source_timeout = 200;
  incomplete_delay = 400;
  max_abbr_width = 100;
  max_kind_width = 100;
  max_menu_width = 100;
  documentation = true;

  source = {
    path = true;
    buffer = true;
    calc = true;
    nvim_lsp = true;
    nvim_lua = true;
    vsnip = true;
  };
}

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

nvim_lsp.tsserver.setup({
    filetypes = {
      "javascript",
      "javascriptreact",
      "javascript.jsx",
      "typescript",
      "typescriptreact",
      "typescript.tsx"
    },
    on_attach = on_attach
})

nvim_lsp.intelephense.setup({
    on_attach = on_attach
})

nvim_lsp.pylsp.setup{
    on_attach = on_attach
}

nvim_lsp.gopls.setup{
    on_attach = on_attach
}

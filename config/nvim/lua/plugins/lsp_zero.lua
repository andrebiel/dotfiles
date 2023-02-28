return {
    'VonHeikemen/lsp-zero.nvim',
    branch = 'v1.x',
    init = function()
        local lsp = require('lsp-zero').preset({
            suggest_lsp_servers = true,
            setup_servers_on_start = true,
            set_lsp_keymaps = true,
            configure_diagnostics = true,
            cmp_capabilities = true,
            manage_nvim_cmp = true,
            call_servers = 'local',
            sign_icons = {
                error = '✘',
                warn = '▲',
                hint = '⚑',
                info = ''
            }
        })

        lsp.setup()

        local cmp = require("cmp")
        lsp.setup_nvim_cmp({
            mapping = lsp.defaults.cmp_mappings({
                ['<C-u>'] = cmp.mapping.scroll_docs(-4),
                ['<C-d>'] = cmp.mapping.scroll_docs(4),
                ['<C-Space>'] = cmp.mapping.complete(),
                ['<CR>'] = cmp.mapping.confirm({ select = true }),
                ["<C-p>"] = cmp.mapping.select_prev_item(),
                ["<C-n>"] = cmp.mapping.select_next_item(),
            })
        })

        vim.diagnostic.config({
            float = {
                severity = { min = vim.diagnostic.severity.warn },
            }
        })

    end,
  dependencies = {
        -- LSP Support
        {'neovim/nvim-lspconfig'},             -- Required
        {'williamboman/mason.nvim'},           -- Optional
        {'williamboman/mason-lspconfig.nvim'}, -- Optional

        -- Autocompletion
        {'hrsh7th/nvim-cmp'},         -- Required
        {'hrsh7th/cmp-nvim-lsp'},     -- Required
        {'hrsh7th/cmp-buffer'},       -- Optional
        {'hrsh7th/cmp-path'},         -- Optional
        {'saadparwaiz1/cmp_luasnip'}, -- Optional
        {'hrsh7th/cmp-nvim-lua'},     -- Optional

        -- Snippets
        {'L3MON4D3/LuaSnip'},             -- Required
        {'rafamadriz/friendly-snippets'}, -- Optional
  },
}

return {
    "nvim-neotest/neotest",
    dependencies = {
        "nvim-lua/plenary.nvim",
        "nvim-treesitter/nvim-treesitter",
        "antoinemadec/FixCursorHold.nvim",
        -- test plugins
        'theutz/neotest-pest'
    },
    config = function()
        require('neotest').setup({
            adapters = {
                require('neotest-pest')({
                    pest_cmd = function()
                        return "vendor/bin/pest"
                    end
                })
            }
        })
    end,
    keys = {
        {"<leader>tf", function() require('neotest').run.run(vim.fn.expand('%')) end, mode = "n"},
        {"<leader>tm", function() require('neotest').run.run() end, mode = "n"}
    },
}

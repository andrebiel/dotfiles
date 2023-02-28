local builtin = require 'telescope.builtin'

return {
    "nvim-telescope/telescope.nvim",
    keys = {
        {"<leader>ff", builtin.find_files, mode = "n"},
        {"<leader>fg", builtin.git_files, mode = "n"},
        {"<leader>gg", builtin.live_grep, mode = "n"},
        {"<leader>gc", builtin.git_commits, mode = "n"},
        {"<C-t>", "<cmd>:Telescope file_browser<cr>", mode = "n"},
        {"<leader>tt", "<cmd>:Telescope file_browser path=%:p:h select_buffer=true<cr>", mode = "n"},
    },
    opts = function()
        return {
            defaults = {
                prompt_prefix = '❯ ',
                selection_caret = '❯ ',
                color_devicons = true
            }
        }
    end,
    config = function()
        require("telescope").load_extension "file_browser"
    end,
    extensions = {
        file_browser = {
              --theme = "ivy",
              -- disables netrw and use telescope-file-browser in its place
              hijack_netrw = true,
              mappings = {
                ["i"] = {
                  -- your custom insert mode mappings
                },
                ["n"] = {
                  -- your custom normal mode mappings
                },
              },
        },
    },
}



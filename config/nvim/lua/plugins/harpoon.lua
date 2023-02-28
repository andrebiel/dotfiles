
local harpoon = require 'harpoon'
local h_mark = require('harpoon.mark')
local h_ui = require('harpoon.ui')
local h_term = require('harpoon.term')

return {
    "ThePrimeagen/harpoon",
    keys = {
        {"<leader>a", require('harpoon.mark').add_file, mode = "n"},
        {"<leader>je", require('harpoon.ui').toggle_quick_menu, mode = "n"},
        {"<leader>jf", function() require('harpoon.ui').nav_file(1) end, mode = "n"},
        {"<leader>jd", function() require('harpoon.ui').nav_file(2) end, mode = "n"},
        {"<leader>js", function() require('harpoon.ui').nav_file(3) end, mode = "n"},
        {"<leader>ja", function() require('harpoon.ui').nav_file(4) end, mode = "n"},
    },

    config = function() 
        global_settings = {
            save_on_toggle = false,
            save_on_change = true,
            enter_on_sendcmd = false,
            excluded_filetypes = { "harpoon" }
        }
    end

}


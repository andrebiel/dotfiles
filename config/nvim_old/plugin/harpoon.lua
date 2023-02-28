local harpoon = require 'harpoon'
local h_mark = require('harpoon.mark')
local h_ui = require('harpoon.ui')
local h_term = require('harpoon.term')
local set_key = vim.keymap.set

harpoon.setup({
    global_settings = {
        save_on_toggle = false,
        save_on_change = true,
        enter_on_sendcmd = false,
        excluded_filetypes = { "harpoon" }
    }
})


set_key('n', '<leader>a', h_mark.add_file)
set_key('n', '<leader>je', h_ui.toggle_quick_menu)
set_key('n', '<leader>jf', function() h_ui.nav_file(1) end)
set_key('n', '<leader>jd', function() h_ui.nav_file(2) end)
set_key('n', '<leader>js', function() h_ui.nav_file(3) end)
set_key('n', '<leader>ja', function() h_ui.nav_file(4) end)
set_key('n', '<leader>jj', function() h_term.gotoTerminal(1) end)
set_key('n', '<leader>jk', function() h_term.gotoTerminal(2) end)


local builtin = require 'telescope.builtin'
local dropdown_theme = {
    theme = 'dropdown',
    layout_config = {
        width = 0.9
    }
}

require('telescope').setup {
  defaults = {
    prompt_prefix = '❯ ',
    selection_caret = '❯ ',
    color_devicons = true
  },
  pickers = {
    find_files = dropdown_theme,
    git_files = dropdown_theme,
    live_grep = dropdown_theme
  }
}

vim.keymap.set('n', '<leader>gc', builtin.current_buffer_fuzzy_find)
vim.keymap.set('n', '<leader>fg', builtin.git_files)
vim.keymap.set('n', '<leader>ff', builtin.find_files)
vim.keymap.set('n', '<leader>gg', builtin.live_grep)

local themes = require('telescope.themes')
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

-- telescope file and action functions
local M = {}

M.file_tree = function()
    require('telescope.builtin').file_browser()
end

M.current_tree = function()
    require('telescope.builtin').file_browser({cwd = '.'})
end

M.git_files = function()
    require('telescope.builtin').git_files()
end

M.find_files = function()
    require('telescope.builtin').find_files()
end

M.grep = function()
    require('telescope.builtin').live_grep()
end

M.grep_current = function()
    require('telescope.builtin').current_buffer_fuzzy_find()
end

return M

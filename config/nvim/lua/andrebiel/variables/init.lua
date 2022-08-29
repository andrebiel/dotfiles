-- disable unneeded providers
vim.g.loaded_perl_provider = 0
vim.g.loaded_ruby_provider = 0

vim.g.completion_matching_strategy_list = { "exact", "substring", "fuzzy" }

-- svelte
vim.g.vim_svelte_plugin_use_typescript = 1
vim.g.vim_svelte_plugin_use_sass = 1

-- php
-- vim.g.neoformat_enabled_php = ['phpcsfixer']

-- prettier
-- vim.g.neoformat_enabled_typescript = ['prettier']

-- additional variables
require("andrebiel.variables.neoformat")
require("andrebiel.variables.php")
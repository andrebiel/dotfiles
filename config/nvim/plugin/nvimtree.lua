require("nvim-tree").setup({
    diagnostics = {
		enable = true,
		show_on_dirs = true,
	},
	view = {
		side = "right",
		centralize_selection = true,
		adaptive_size = true,
	},
	renderer = {
		group_empty = true,
	},
	filters = {
		dotfiles = true,
	},
})


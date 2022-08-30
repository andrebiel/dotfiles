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
    actions = {
        open_file = {
            quit_on_open = true
        },
    },
})


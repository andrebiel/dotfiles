return {
	"mhartington/oceanic-next",
	lazy = false,
	priority = 1000,
	config = function()
		vim.g.oceanic_next_terminal_bold = 1
		vim.g.oceanic_next_terminal_italic = 1
		vim.cmd([[syntax enable]])
		vim.cmd([[set termguicolors]])
		vim.cmd([[colorscheme OceanicNext]])
	end,
}

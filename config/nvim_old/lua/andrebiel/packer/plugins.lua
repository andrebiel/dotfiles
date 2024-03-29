local packer = require("packer")

packer.startup(function(use)
    use "wbthomason/packer.nvim"
    use "nvim-lua/popup.nvim"

    use "altercation/vim-colors-solarized"
    use "tpope/vim-surround"
    use "nvim-lua/plenary.nvim"
    use "nvim-telescope/telescope.nvim"
    use "tpope/vim-commentary"
    use {"nvim-treesitter/nvim-treesitter", {
        run = function()
			vim.api.nvim_command("TSUpdate")
		end,
    }}
    use "gruvbox-community/gruvbox"
    use "mhartington/oceanic-next"
    use "neovim/nvim-lspconfig"
    use "sbdchd/neoformat"
    use "ryanoasis/vim-devicons"
    use "hrsh7th/cmp-nvim-lsp"
    use "hrsh7th/cmp-buffer"
    use "hrsh7th/cmp-path"
    use "hrsh7th/cmp-cmdline"
    use "hrsh7th/nvim-cmp"
    use {"evanleck/vim-svelte", branch = "main"}
    use "ThePrimeagen/harpoon"
    use "nvim-lualine/lualine.nvim"
    use "tami5/lspsaga.nvim"
    use "leafOfTree/vim-svelte-plugin"
    use "marko-cerovac/material.nvim"
    use "L3MON4D3/LuaSnip"
    use "onsails/lspkind.nvim"
    use "kyazdani42/nvim-web-devicons"
    use "kyazdani42/nvim-tree.lua"
    use "vim-test/vim-test"
end)

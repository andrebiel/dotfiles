-- vim.o.runtimepath = vim.fn.stdpath('data') .. '/site/pack/*/start/*,' .. vim.o.runtimepath
-- packer is located here
-- ~/.local/share/nvim/site/pack/packer/start/packer.nvim/

local download_packer = function()
	local directory = string.format("%s/site/pack/packer/start/", vim.fn.stdpath("data"))
	vim.fn.mkdir(directory, "p")

	local out = vim.fn.system(
		string.format("git clone %s %s", "https://github.com/wbthomason/packer.nvim", directory .. "/packer.nvim")
	)

	print(out)
	print("Downloading packer.nvim...")
	print("( You'll need to restart now )")
	vim.cmd([[qa]])
end

return function()
	local directory = string.format("%s/site/pack/packer/start/", vim.fn.stdpath("data"))
	vim.o.runtimepath = directory .. '/packer.nvim,' .. vim.o.runtimepath

	if not pcall(require, "packer") then
		download_packer()

		return true
	end

	return false
end

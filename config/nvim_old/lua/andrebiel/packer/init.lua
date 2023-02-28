-- vim.o.runtimepath = vim.fn.stdpath('data') .. '/site/pack/*/start/*,' .. vim.o.runtimepath
-- packer is located here
-- ~/.local/share/nvim/site/pack/packer/start/packer.nvim/

-- local download_packer = function()
-- 	local directory = string.format("%s/site/pack/packer/start/", vim.fn.stdpath("data"))
-- 	vim.fn.mkdir(directory, "p")

-- 	local out = vim.fn.system(
-- 		string.format("git clone %s %s", "https://github.com/wbthomason/packer.nvim", directory .. "/packer.nvim")
-- 	)

-- 	print(out)
-- 	print("Downloading packer.nvim...")
-- 	print("( You'll need to restart now )")
-- 	vim.cmd([[qa]])
-- end

-- return function()
-- 	local directory = string.format("%s/site/pack/packer/start/", vim.fn.stdpath("data"))
-- 	vim.o.runtimepath = directory .. '/packer.nvim,' .. vim.o.runtimepath

-- 	if not pcall(require, "packer") then
-- 		download_packer()

-- 		return true
-- 	end

-- 	return false
-- end

-- from github
local fn = vim.fn
local install_path = fn.stdpath('data')..'/site/pack/packer/start/packer.nvim'
if fn.empty(fn.glob(install_path)) > 0 then
  packer_bootstrap = fn.system({'git', 'clone', '--depth', '1', 'https://github.com/wbthomason/packer.nvim', install_path})
  vim.cmd [[packadd packer.nvim]]
end

return require('packer').startup(function(use)
	use "wbthomason/packer.nvim"
  -- My plugins here
  -- use 'foo1/bar1.nvim'
  -- use 'foo2/bar2.nvim'

  -- Automatically set up your configuration after cloning packer.nvim
  -- Put this at the end after all plugins
  if packer_bootstrap then
    require('packer').sync()
  end
end)

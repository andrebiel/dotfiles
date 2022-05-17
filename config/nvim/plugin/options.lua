local opt = vim.opt

-- opt.nobackup = true
-- opt.nowritebackup = true
-- opt.nohlsearch = true
-- opt.noerrorbells = true
-- opt.nowrap = true

-- ignore wilds
opt.wildignore = {
    '*.pyc',
    '*_build/*',
    '**/coverage/*',
    '**/node_modules/*',
    '**/android/*',
    '**/ios/*',
    '**/.git/*',
}
opt.wildmode = { 'longest', 'list', 'full' }
opt.wildmenu = true
opt.encoding = 'utf-8'
opt.number = true
opt.relativenumber = true
opt.tabstop = 4
opt.softtabstop = 4
opt.shiftwidth = 4
opt.expandtab = true
opt.autoindent = true
opt.copyindent = true
opt.ttimeoutlen = 50
opt.timeoutlen = 1000
opt.smartindent = true
opt.termguicolors = true
opt.hidden = true
opt.background = 'dark'
opt.cmdheight = 1
opt.updatecount = 300
opt.incsearch = true
opt.scrolloff = 8
opt.signcolumn = 'yes'
opt.completeopt = 'menuone,noselect'
opt.guicursor = ''
opt.colorcolumn = '80'
opt.splitbelow = true
opt.splitright = true
opt.list = true
opt.listchars = 'tab:!·,trail:·'
opt.swapfile = false

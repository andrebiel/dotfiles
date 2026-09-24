-- Set leaders before plugins and mappings are defined.
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Sensible defaults for an interactive editor.
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.cursorline = true
vim.opt.signcolumn = "yes"
vim.opt.breakindent = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.inccommand = "split"
vim.opt.splitbelow = true
vim.opt.splitright = true
vim.opt.undofile = true
vim.opt.updatetime = 250
vim.opt.timeoutlen = 300
vim.opt.scrolloff = 4
vim.opt.confirm = true
vim.opt.clipboard = "unnamedplus"
vim.opt.completeopt = { "menu", "menuone", "noselect" }
vim.opt.termguicolors = true
vim.opt.background = "dark"

vim.cmd.colorscheme("catppuccin")

local map = vim.keymap.set

map("n", "<leader>w", "<cmd>write<cr>", { desc = "Write file" })
map("n", "<leader>yyy", '"+yy', { desc = "Copy line to clipboard" })
map("x", "<leader>yyy", '"+y', { desc = "Copy selection to clipboard" })
map("n", "<Esc>", "<cmd>nohlsearch<cr>", { desc = "Clear search highlight" })

map("n", "<C-h>", "<C-w>h", { desc = "Focus left window" })
map("n", "<C-j>", "<C-w>j", { desc = "Focus lower window" })
map("n", "<C-k>", "<C-w>k", { desc = "Focus upper window" })
map("n", "<C-l>", "<C-w>l", { desc = "Focus right window" })

vim.api.nvim_create_autocmd("TextYankPost", {
  desc = "Highlight copied text",
  group = vim.api.nvim_create_augroup("highlight-yank", { clear = true }),
  callback = function()
    vim.hl.on_yank()
  end,
})

-- Neovim 0.12's built-in package manager keeps this setup dependency-light.
-- --noplugin is used by static checks, so skip plugin setup in that mode.
if vim.o.loadplugins then
  vim.pack.add({
    { src = "https://github.com/nvim-mini/mini.pick", version = "stable" },
    { src = "https://github.com/mason-org/mason.nvim" },
    { src = "https://github.com/mason-org/mason-lspconfig.nvim" },
    { src = "https://github.com/neovim/nvim-lspconfig" },
    { src = "https://github.com/nvim-treesitter/nvim-treesitter" },
    { src = "https://github.com/saghen/blink.cmp", version = "v1" },
  }, { confirm = false })

  -- Fuzzy finding.
  local pick = require("mini.pick")
  pick.setup({
    window = {
      config = { border = "rounded" },
    },
  })

  map("n", "<leader>ff", pick.builtin.files, { desc = "Find files" })
  map("n", "<leader>fg", pick.builtin.grep_live, { desc = "Find text" })
  map("n", "<leader>fb", pick.builtin.buffers, { desc = "Find buffers" })
  map("n", "<leader>fh", pick.builtin.help, { desc = "Find help" })
  map("n", "<leader>fr", pick.builtin.resume, { desc = "Resume picker" })

  -- Structural highlighting. Parser installation is asynchronous and a no-op
  -- for parsers that are already present.
  local treesitter_parsers = {
    "bash",
    "css",
    "html",
    "javascript",
    "json",
    "lua",
    "markdown",
    "markdown_inline",
    "python",
    "svelte",
    "toml",
    "tsx",
    "typescript",
    "vim",
    "vimdoc",
    "yaml",
  }
  local treesitter = require("nvim-treesitter")
  local can_install_parsers = vim.fn.executable("tree-sitter") == 1
  if not can_install_parsers then
    vim.schedule(function()
      vim.notify("Tree-sitter CLI missing: run bash scripts/install-tree-sitter in dotfiles (Linux)"
        .. " or brew install tree-sitter-cli (macOS), then restart Neovim.", vim.log.levels.WARN)
    end)
  end

  local function start_treesitter(buffer, language)
    if not vim.api.nvim_buf_is_valid(buffer) then
      return
    end
    -- Missing parsers throw, including after a failed asynchronous install.
    local ok, loaded = pcall(vim.treesitter.language.add, language)
    if ok and loaded then
      vim.treesitter.start(buffer, language)
    end
  end

  local available_parsers = treesitter.get_available()

  vim.api.nvim_create_autocmd("FileType", {
    desc = "Enable Tree-sitter highlighting when a parser is available",
    group = vim.api.nvim_create_augroup("treesitter-start", { clear = true }),
    callback = function(event)
      local language = vim.treesitter.language.get_lang(event.match)
      if not language then
        return
      end

      local installed_parsers = treesitter.get_installed("parsers")
      if vim.tbl_contains(installed_parsers, language) then
        start_treesitter(event.buf, language)
      elseif can_install_parsers and vim.tbl_contains(available_parsers, language) then
        treesitter.install(language):await(function()
          vim.schedule(function()
            if vim.api.nvim_buf_is_valid(event.buf)
                and vim.treesitter.language.get_lang(vim.bo[event.buf].filetype) == language then
              start_treesitter(event.buf, language)
            end
          end)
        end)
      else
        start_treesitter(event.buf, language)
      end
    end,
  })

  if can_install_parsers then
    treesitter.install(treesitter_parsers):await(function()
      vim.schedule(function()
        for _, buffer in ipairs(vim.api.nvim_list_bufs()) do
          if vim.api.nvim_buf_is_loaded(buffer) then
            local language = vim.treesitter.language.get_lang(vim.bo[buffer].filetype)
            if language then
              start_treesitter(buffer, language)
            end
          end
        end
      end)
    end)
  end

  -- Completion from LSPs, paths, snippets, and words in open buffers.
  local completion = require("blink.cmp")
  completion.setup({
    keymap = { preset = "default" },
    appearance = { nerd_font_variant = "mono" },
    completion = {
      documentation = { auto_show = true, auto_show_delay_ms = 400 },
      ghost_text = { enabled = true },
    },
    signature = { enabled = true },
    sources = { default = { "lsp", "path", "snippets", "buffer" } },
    fuzzy = { implementation = "prefer_rust_with_warning" },
  })

  vim.lsp.config("*", {
    capabilities = completion.get_lsp_capabilities(),
  })

  -- Prefer each project's TypeScript version. Bun projects get Bun globals
  -- and APIs when @types/bun is present in the project.
  vim.lsp.config("vtsls", {
    settings = {
      vtsls = { autoUseWorkspaceTsdk = true },
    },
  })

  vim.lsp.config("lua_ls", {
    settings = {
      Lua = {
        runtime = { version = "LuaJIT" },
        diagnostics = { globals = { "vim" } },
        workspace = {
          checkThirdParty = false,
          library = { vim.env.VIMRUNTIME },
        },
      },
    },
  })

  local language_servers = {
    "basedpyright",
    "bashls",
    "cssls",
    "eslint",
    "html",
    "jsonls",
    "lua_ls",
    "marksman",
    "ruff",
    "svelte",
    "taplo",
    "vtsls",
    "yamlls",
  }

  require("mason").setup()
  require("mason-lspconfig").setup({
    ensure_installed = language_servers,
    automatic_enable = language_servers,
  })
end

vim.diagnostic.config({
  severity_sort = true,
  float = { border = "rounded", source = true },
  virtual_text = { spacing = 2, source = "if_many" },
})

vim.api.nvim_create_autocmd("LspAttach", {
  desc = "Set buffer-local LSP mappings",
  group = vim.api.nvim_create_augroup("lsp-mappings", { clear = true }),
  callback = function(event)
    local client = assert(vim.lsp.get_client_by_id(event.data.client_id))
    if client.name == "ruff" then
      client.server_capabilities.hoverProvider = false
    end

    local function lsp_map(lhs, rhs, description)
      map("n", lhs, rhs, { buffer = event.buf, desc = "LSP: " .. description })
    end

    lsp_map("gd", vim.lsp.buf.definition, "Go to definition")
    lsp_map("gD", vim.lsp.buf.declaration, "Go to declaration")
    lsp_map("<leader>la", vim.lsp.buf.code_action, "Code action")
    lsp_map("<leader>lr", vim.lsp.buf.rename, "Rename symbol")
    lsp_map("<leader>ld", vim.diagnostic.open_float, "Line diagnostics")
    lsp_map("<leader>lq", vim.diagnostic.setloclist, "Diagnostic list")
    lsp_map("<leader>lf", function()
      vim.lsp.buf.format({ async = true })
    end, "Format buffer")
    lsp_map("<leader>lh", function()
      local enabled = vim.lsp.inlay_hint.is_enabled({ bufnr = event.buf })
      vim.lsp.inlay_hint.enable(not enabled, { bufnr = event.buf })
    end, "Toggle inlay hints")
  end,
})

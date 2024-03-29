return {
    "sbdchd/neoformat",
    keys = {},
    lazy = false,
    config = function()
            -- format unknown file types
        vim.g.neoformat_basic_format_align = 1
        vim.g.neoformat_basic_format_retab = 1
        vim.g.neoformat_basic_format_trim = 1

        vim.g.neoformat_enabled_cmake = { "cmakeformat" }
        vim.g.neoformat_enabled_cpp = { "uncrustify", "clangformat", "astyle" }
        vim.g.neoformat_enabled_cs = { "uncrustify", "astyle", "clangformat" }
        vim.g.neoformat_enabled_css = {
            "prettier",
            "stylelint",
            "stylefmt",
            "cssbeautify",
            "prettydiff",
            "csscomb",
        }
        vim.g.neoformat_enabled_csv = { "prettydiff" }
        vim.g.neoformat_enabled_dart = { "dartfmt", "format" }
        vim.g.neoformat_enabled_go = { "goimports", "gofmt", "gofumports", "gofumpt" }
        vim.g.neoformat_enabled_graphql = { "prettierd", "prettier" }
        vim.g.neoformat_enabled_html = { "htmlbeautify", "prettier", "tidy", "prettydiff" }
        vim.g.neoformat_enabled_javascript = {
            "prettier",
            "prettiereslint",
            "eslint_d",
            "jsbeautify",
            "standard",
            "semistandard",
            "prettydiff",
            "clangformat",
            "esformatter",
            "denofmt",
        }
        vim.g.neoformat_enabled_javascriptreact = {
            "prettier",
            "prettiereslint",
            "eslint_d",
            "jsbeautify",
            "standard",
            "semistandard",
            "prettydiff",
            "clangformat",
            "esformatter",
            "denofmt",
        }
        vim.g.neoformat_enabled_json = {  "prettier", "jsbeautify", "prettydiff", "jq", "fixjson", "denofmt" }
        vim.g.neoformat_enabled_markdown = { "prettier", "denofmt", "remark" }
        vim.g.neoformat_enabled_lua = { "luaformatter", "luafmt", "luaformat", "stylua" }
        vim.g.neoformat_enabled_nginx = { "nginxbeautifier" }
        vim.g.neoformat_enabled_php = { "php-cs-fixer", "laravel-pint",  "prettier" }
        vim.g.neoformat_enabled_python = { "yapf", "autopep8", "black", "isort", "docformatter", "pyment", "pydevf" }
        vim.g.neoformat_enabled_rust = { "rustfmt" }
        vim.g.neoformat_enabled_scss = {
            "prettier",
            "sassconvert",
            "stylelint",
            "stylefmt",
            "prettydiff",
            "csscomb",
        }
        vim.g.neoformat_enabled_sql = { "sqlformat", "pg_format", "sqlfmt" }
        vim.g.neoformat_enabled_svelte = {  "prettier" }
        vim.g.neoformat_enabled_typescript = {
            "prettier",
            "prettiereslint",
            "tsfmt",
            "tslint",
            "eslint_d",
            "clangformat",
            "denofmt",
        }
        vim.g.neoformat_enabled_typescriptreact = {
            "prettier",
            "prettiereslint",
            "tsfmt",
            "tslint",
            "eslint_d",
            "clangformat",
            "denofmt",
        }
        vim.g.neoformat_enabled_toml = { "taplo" }
        vim.g.neoformat_enabled_vue = {  "prettier" }
        vim.g.neoformat_enabled_yaml = {  "prettier", "pyaml" }
        vim.g.neoformat_enabled_zsh = { "shfmt" }

    end
}

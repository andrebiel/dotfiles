require("andrebiel.snippets.javascript")
require("andrebiel.snippets.svelte")
require("andrebiel.snippets.php")

local ls = require("luasnip")

ls.filetype_extend("typescript", { "javascript" })
ls.filetype_extend("svelte", { "javascript", "typescript" })




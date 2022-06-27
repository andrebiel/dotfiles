require("karllson.snippets.javascript")
require("karllson.snippets.svelte")

local ls = require("luasnip")

ls.filetype_extend("typescript", { "javascript" })
ls.filetype_extend("svelte", { "javascript", "typescript" })



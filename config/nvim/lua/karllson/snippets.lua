local luasnip = require 'luasnip'

-- some shorthands...
local s = luasnip.snippet
local i = luasnip.insert_node
local t = luasnip.text_node
-- local sn = ls.snippet_node
-- local f = ls.function_node
-- local c = ls.choice_node
-- local d = ls.dynamic_node
-- local r = ls.restore_node
-- local l = require("luasnip.extras").lambda
-- local rep = require("luasnip.extras").rep
-- local p = require("luasnip.extras").partial
-- local m = require("luasnip.extras").match
-- local n = require("luasnip.extras").nonempty
-- local dl = require("luasnip.extras").dynamic_lambda
-- local fmt = require("luasnip.extras.fmt").fmt
-- local fmta = require("luasnip.extras.fmt").fmta
-- local types = require("luasnip.util.types")
-- local conds = require("luasnip.extras.expand_conditions")
--

luasnip.add_snippets('typescriptreact', {
    s('cl', t({"console.log("}), i(1), t(")"))
})

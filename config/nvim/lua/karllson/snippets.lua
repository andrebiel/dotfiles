local luasnip = require 'luasnip'

-- some shorthands...
local s = luasnip.snippet
local i = luasnip.insert_node
local t = luasnip.text_node
local c = luasnip.choice_node
local fmt = require("luasnip.extras.fmt").fmt

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
-- local fmta = require("luasnip.extras.fmt").fmta
-- local types = require("luasnip.util.types")
-- local conds = require("luasnip.extras.expand_conditions")
--

luasnip.add_snippets('all', {
    s('cl', {
        t({"console.log('log', "}), i(1),
        t({");"}), i(0),
    })
})

luasnip.add_snippets('svelte', {
    s('mod', t(
        '<script context="module">' ..
        '/** @type {import(\'@sveltejs/kit\').Load} */' ..
        'export async function load({ params }) {' ..
            'return {};' ..
        '}' ..
        '</script>'
    ));
})

luasnip.add_snippets("svelte", {
	s(
		"script",
		fmt(
			[[
                <script {}>
                    {}
                </script>
            ]],
			{
				c(1, { t('lang="ts"'), t('context="module"') }),
				i(0),
			}
		)
	),
})





local ls = require("luasnip")
local fmt = require("luasnip.extras.fmt").fmt

local s = ls.s
local i = ls.insert_node
local c = ls.choice_node
local t = ls.text_node

ls.add_snippets("php", {
	s(
		"test",
		fmt(
			[[
			    /** @test */
                function {}() {{
                    {}
                }}
            ]],
			{
				i(1),
				i(0),
			}
		)
    ),
	s( "pest", fmt("it('{}', function () {{ {} }});", { i(1), i(0), } ) ),
	s(
		"rdb",
		fmt(
			[[
			use Illuminate\Foundation\Testing\RefreshDatabase;
            uses(RefreshDatabase::class);
            ]], {}
		)
    ),
})

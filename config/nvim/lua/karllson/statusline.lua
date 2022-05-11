function mysplit (inputstr, sep)
        if sep == nil then
                sep = "%s"
        end
        local t={}
        for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
                table.insert(t, str)
        end
        return t
end

local function cwd()
    dir = os.getenv("PWD") or io.popen("cd"):read()
    folders = mysplit(dir, "/")

    return folders[#folders+1-2] .. "/" .. folders[#folders]
end

require('lualine').setup {
  options = {
    icons_enabled = true,
    theme = 'OceanicNext',
    component_separators = { left = '', right = ''},
    section_separators = { left = '', right = ''},
    disabled_filetypes = {},
    always_divide_middle = true,
  },
  sections = {
    lualine_a = {'branch'},
    lualine_b = {'filename'},
    lualine_c = { cwd },
    lualine_x = {'filetype'},
    lualine_y = {'location'},
    lualine_z = {}
  },
inactive_sections = {
    lualine_a = {},
    lualine_b = {},
    lualine_c = {},
    lualine_x = {},
    lualine_y = {},
    lualine_z = {}
  },
  tabline = {},
  extensions = {}
}

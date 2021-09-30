-- heavily inspired by: https://github.com/LoydAndrew/nvim/blob/main/evilline.lua
local gl = require('galaxyline')
local gls = gl.section
local fileinfo = require('galaxyline.provider_fileinfo')
local vcs = require('galaxyline.provider_vcs')
local colors = {
    bg = '#282c34',
    line_bg = '#353644',
    fg = '#8FBCBB',
    fg_green = '#65a380',
    yellow = '#fabd2f',
    cyan = '#008080',
    darkblue = '#081633',
    green = '#afd700',
    orange = '#FF8800',
    purple = '#5d4d7a',
    magenta = '#c678dd',
    blue = '#51afef';
    red = '#ec5f67'
}

local buffer_not_empty = function()
  if vim.fn.empty(vim.fn.expand('%:t')) ~= 1 then
    return true
  end
  return false
end

local spacer = {
  Space = {
    provider = function() return ' ' end,
    condition = vcs.check_git_workspace,
  }
}


gls.left[1] = spacer

gls.left[2] ={
  FileIcon = {
    provider = 'FileIcon',
    condition = buffer_not_empty,
    highlight = {fileinfo.get_file_icon_color},
  },
}

gls.left[3] = {
  FileName = {
    provider = {'FileName'},
    condition = buffer_not_empty,
    highlight = {colors.fg, 'bold'}
  }
}

-- RIGHT SIDE
gls.right[1] = {
  GitBranch = {
    provider = 'GitBranch',
    condition = vcs.check_git_workspace,
    highlight = {'#8FBCBB', 'bold'},
  }
}
gls.right[2] = {
  LinePercent = {
    separator = ' ',
    provider = 'LinePercent',
    highlight = {'#8FBCBB', 'bold'},
  }
}
gls.right[3] = {
  LineInfo = {
    provider = 'LineColumn',
    highlight = { colors.fg, colors.section_bg },
    separator = ' | ',
    separator_highlight = { colors.bg, colors.section_bg },
  },
}
gls.right[4] = spacer 

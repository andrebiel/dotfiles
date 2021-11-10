-- heavily inspired by: https://github.com/LoydAndrew/nvim/blob/main/evilline.lua
local gl = require('galaxyline')
local gls = gl.section
local fileinfo = require('galaxyline.provider_fileinfo')
local vcs = require('galaxyline.provider_vcs')
local diagnostic = require('galaxyline.provider_diagnostic')
local lspclient = require('galaxyline.provider_lsp')
local colors = {
    bg = '#0D151A',
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

-- ----------------------------------------------------------------
-- Provider
-- ----------------------------------------------------------------
DiagnosticError = diagnostic.get_diagnostic_error
DiagnosticWarn = diagnostic.get_diagnostic_warn
DiagnosticHint = diagnostic.get_diagnostic_hint
DiagnosticInfo = diagnostic.get_diagnostic_info
GetLspClient = lspclient.get_lsp_client

-- ----------------------------------------------------------------
-- Conditions
-- ----------------------------------------------------------------
local buffer_not_empty = function()
  if vim.fn.empty(vim.fn.expand('%:t')) ~= 1 then
    return true
  end
  return false
end

-- ----------------------------------------------------------------
-- Icons
-- ----------------------------------------------------------------
local Whitespace = {
    Space = {
        provider = function () return ' ' end,
        highlight = { colors.bg, colors.bg },
    }
}

local GitIcon = {
    GitIcon = {
        provider = function () return '  ' end,
        highlight = { colors.orange, colors.bg },
        condition = vcs.check_git_workspace,
    }
}

local WarnIcon = {
    WarnIcon = {
        provider = function () return '  ' end,
        highlight = { colors.yellow, colors.bg },
        condition = buffer_not_empty
    }
}

local InfoIcon = {
    InfoIcon = {
        provider = function () return '  ' end,
        highlight = { colors.blue, colors.bg },
        condition = buffer_not_empty,
    }
}

local ErrorIcon = {
    ErrorIcon = {
        provider = function () return '  ' end,
        highlight = { colors.red, colors.bg },
        condition = buffer_not_empty,
    }
}
-- ----------------------------------------------------------------
-- Insert LEFT
-- ----------------------------------------------------------------

gls.left[1] = Whitespace

gls.left[2] = {
  FileIcon = {
    provider = 'FileIcon',
    condition = buffer_not_empty,
    highlight = {fileinfo.get_file_icon_color, colors.bg},
  },
}

gls.left[3] = {
  FileName = {
    provider = {'FileName'},
    condition = buffer_not_empty,
    highlight = {colors.fg, colors.bg}
  }
}

gls.left[4] = GitIcon

gls.left[5] = {
  GitBranch = {
    provider = 'GitBranch',
    condition = vcs.check_git_workspace,
    highlight = {'#8FBCBB', colors.bg},
  }
}

-- ----------------------------------------------------------------
-- Insert RIGHT
-- ----------------------------------------------------------------
gls.right[1] = ErrorIcon
gls.right[2] = {
  DiagnosticError  = {
    provider = DiagnosticError, 
    highlight = {colors.red, colors.bg},
    condition = buffer_not_empty,
  }
}

gls.right[3] = WarnIcon
gls.right[4] = {
  DiagnosticWarn  = {
    provider = DiagnosticWarn, 
    highlight = {colors.orange, colors.bg},
    condition = buffer_not_empty,
  }
}

gls.right[5] = InfoIcon
gls.right[6] = {
  DiagnosticHint  = {
    provider = DiagnosticHint, 
    highlight = {colors.blue, colors.bg},
    condition = buffer_not_empty,
  }
}

gls.right[7] = Whitespace

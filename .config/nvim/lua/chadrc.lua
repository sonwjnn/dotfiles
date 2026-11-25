---@type ChadrcConfig
local M = {}

M.base46 = {
  theme = "ayu_dark",
  theme_toggle = { "ayu_dark", "one_light" },
  transparency = true,

  hl_override = {
    Comment = {
      italic = true,
    },
  },

  hl_add = {
    NvimTreeOpenedFolderName = { fg = "green", bold = true },
  },
}

M.nvdash = {
  load_on_startup = true,
  buttons = {
    { txt = "  Find File", keys = "ff", cmd = "Telescope find_files" },
    { txt = "  Recent Files", keys = "fo", cmd = "Telescope oldfiles" },
    { txt = "󰈭  Find Word", keys = "fw", cmd = "Telescope live_grep" },
    { txt = "󱓻  Search & Replace", keys = "sr", cmd = "GrugFar" },
    { txt = "󱥚  Themes", keys = "th", cmd = ":lua require('nvchad.themes').open()" },
    { txt = "  Mappings", keys = "ch", cmd = "NvCheatsheet" },

    { txt = "─", hl = "NvDashFooter", no_gap = true, rep = true },

    {
      txt = function()
        local stats = require("lazy").stats()
        local ms = math.floor(stats.startuptime) .. " ms"
        return "  Loaded " .. stats.loaded .. "/" .. stats.count .. " plugins in " .. ms
      end,
      hl = "NvDashFooter",
      no_gap = true,
      content = "fit",
    },
  },
}

M.ui = {
  statusline = {
    theme = "minimal",
    separator_style = "round",
  },
}

return M

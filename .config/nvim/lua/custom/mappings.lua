---@type MappingsTable
local M = {}

M.disabled = {
  n = {
    ["<C-n>"] = "",
  },
}

M.general = {
  n = {
    ["<C-h>"] = { ":NvimTmuxNavigateLeft<CR>", opts = { nowait = true, silent = true } },
    ["<C-j>"] = { ":NvimTmuxNavigateDown<CR>", opts = { nowait = true, silent = true } },
    ["<C-k>"] = { ":NvimTmuxNavigateUp<CR>", opts = { nowait = true, silent = true } },
    ["<C-l>"] = { ":NvimTmuxNavigateRight<CR>", opts = { nowait = true, silent = true } },
    ["<C-\\>"] = { ":NvimTmuxNavigateLastActive<CR>", opts = { nowait = true, silent = true } },
    ["<C-Space>"] = { "NvimTmuxNavigateNavigateNext<CR>", opts = { nowait = true, silent = true } },

    [";"] = { ":", "enter command mode", opts = { nowait = true } },
    ["dw"] = { 'vb"_d', "remove back word", opts = { nowait = true } },
    ["<C-a>"] = { "gg<S-v>G", "copy all text", opts = { nowait = true } },
    -- New tab
    ["te"] = { ":tabedit", opts = { nowait = true } },
    -- Split window
    ["ss"] = { ":split<Return><C-w>w", opts = { nowait = true } },
    ["sv"] = { ":vsplit<Return><C-w>w", opts = { nowait = true } },
    -- Move window
    ["<Space>"] = { "<C-w>w", opts = { nowait = true } },
  },
  i = {
    ["<C-a>"] = { "<ESC>^i", "Move cursor beginning of line" },
    ["<C-e>"] = { "<End>", "Move cursor end of line" },
    ["<C-b>"] = { "<Left>", "Move cursor left" },
    ["<C-f>"] = { "<Right>", "Move cursor right" },
    ["<C-k>"] = { "<C-o>D", "Kill till to end of line" },
    ["<C-s>"] = { "<C-o><cmd> w <CR>", "save file" },
  },
}
M.nvimtree = {
  n = {
    ["ta"] = { "<cmd> NvimTreeToggle <CR>", "toggle nvimtree" },
    -- ["n"] = {
    --   function()
    --     require("nvim-tree.api").fs.create()
    --   end,
    --   "create file",
    -- },
  },
}

M.telescope = {
  n = {
    -- find
    ["<leader>ss"] = { "<cmd> Telescope grep_string <cr>", "Search under your cursor" },
  },
}
-- more keybinds!

return M

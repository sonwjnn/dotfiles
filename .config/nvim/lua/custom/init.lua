-- Auto resize panes when resizing nvim window
-- autocmd("VimResized", {
--   pattern = "*",
--   command = "tabdo wincmd =",
-- })
local autocmd = vim.api.nvim_command

if vim.g.neovide then
  vim.o.guifont = "CaskaydiaCove Nerd Font Mono:h12"
  vim.g.neovide_input_use_logo = true
  vim.g.neovide_cursor_trail_length = 0.05
  vim.g.neovide_remember_window_size = true
  vim.g.neovide_cursor_animation_length = 0.05
  vim.g.neovide_cursor_vfx_mode = "pixiedust"
  vim.g.neovide_floating_shadow = false
  vim.g.neovide_padding_top = 10
  vim.g.neovide_padding_bottom = 10
  vim.g.neovide_padding_right = 10
  vim.g.neovide_padding_left = 10
end

vim.loader.enable()

vim.opt.list = true
vim.opt.relativenumber = true
-- vim.filetype.add {
--   pattern = {
--     [".*%.blade%.php"] = "blade",
--   },
-- }
--
--local api = require "nvim-tree.api"
--
--vim.keymap.set("n", "n", api.tree.create)

for i = 1, 9, 1 do
  -- Move to desired buffer line using Alt + 1-9 keys
  vim.keymap.set("n", string.format("<A-%s>", i), function()
    vim.api.nvim_set_current_buf(vim.t.bufs[i])
  end, { desc = "which_key_ignore" })
  -- Move to desired tab group instantly using Leader + 1-9 keys
  vim.keymap.set("n", string.format("<leader>%s", i), function()
    vim.api.nvim_set_current_tabpage(i)
  end, { desc = "which_key_ignore" })
end

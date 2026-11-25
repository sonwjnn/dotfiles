require("nvchad.mappings")

local map = vim.keymap.set
local nomap = vim.keymap.del

local paste = vim.paste
vim.paste = function(lines, phase)
  if not vim.bo.modifiable or vim.bo.readonly then
    return false
  end

  local registers = {
    ['"'] = vim.fn.getreginfo '"',
    ['+'] = vim.fn.getreginfo '+',
    ['*'] = vim.fn.getreginfo '*',
  }

  local result = paste(lines, phase)

  vim.fn.setreg('+', registers['+'])
  vim.fn.setreg('*', registers['*'])
  vim.fn.setreg('"', registers['"'])

  return result
end

nomap("n", "<C-n>")

-- normal mode
map("n", ";", ":", { desc = "enter command mode" })
map("n", "z", "u", { desc = "undo" })
map("n", "dw", 'vb"_d', { desc = "delete word without yank" })
map({ "n", "x" }, "de", '"_de', { desc = "delete to end without yank" })
map({ "n", "x" }, "d$", '"_d$', { desc = "delete to end without yank" })
map("n", "te", ":tabedit", { desc = "new tab" })
map("n", "ss", ":split<Return><C-w>w", { desc = "horizontal split" })
map("n", "sv", ":vsplit<Return><C-w>w", { desc = "vertical split" })
-- window navigation (herdr panes + nvim splits)
-- also maps <D-h>/<D-l>; keep them here so nothing re-binds them to plain <C-w>
require("herdr_nav")
-- nvimtree
map("n", "ta", "<cmd>NvimTreeToggle<CR>", { desc = "toggle nvimtree" })

-- telescope
map("n", "<leader>ss", "<cmd>Telescope grep_string<cr>", { desc = "search under cursor" })

-- clipboard (macOS style)
map("n", "<D-a>", "gg<S-v>G", { desc = "select all" })
map("i", "<D-a>", "<Esc>ggVG", { desc = "select all" })
map("n", "<D-c>", "yy", { desc = "copy current line" })
map("v", "<D-c>", function()
  local start = vim.fn.getpos("'<")
  local cur = vim.fn.getpos(".")
  if start[2] == cur[2] and start[3] == cur[3] then
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>yy", true, false, true), "n", false)
  else
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('"+y', true, false, true), "n", false)
  end
end, { desc = "copy: line if no selection, else selection" })
map("v", "<D-v>", '"_dP', { desc = "paste without overwriting register" })
map("x", "<D-v>", '"_dP', { desc = "paste without overwriting register" })
map("x", "p", '"_dP', { desc = "paste without overwriting register" })
map("x", "P", '"_dP', { desc = "paste without overwriting register" })
map("n", "<D-v>", '"+gP', { desc = "paste from clipboard" })
map("i", "<D-v>", "<C-r>+", { desc = "paste from clipboard" })
map({ "n", "i", "v" }, "<D-s>", "<cmd>w<CR>", { desc = "save file" })
map("i", "<D-c>", function()
  vim.fn.setreg("+", vim.api.nvim_get_current_line())
end, { desc = "copy current line" })

-- insert mode navigation
map("i", "<C-e>", "<End>", { desc = "move to line end" })
map("i", "<C-b>", "<Left>", { desc = "move left" })
map("i", "<C-f>", "<Right>", { desc = "move right" })
map("i", "<C-k>", "<C-o>D", { desc = "kill to line end" })
map("i", "<C-s>", "<C-o><cmd>w<CR>", { desc = "save file" })

-- Alt+1-9 -> switch buffer
for i = 1, 9 do
  map("n", string.format("<A-%s>", i), function()
    vim.api.nvim_set_current_buf(vim.t.bufs[i])
  end, { desc = "which_key_ignore" })
end

-- Leader+1-9 -> switch tab
for i = 1, 9 do
  map("n", string.format("<leader>%s", i), function()
    vim.api.nvim_set_current_tabpage(i)
  end, { desc = "which_key_ignore" })
end

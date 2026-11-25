return {
  {
    "nvim-tree/nvim-tree.lua",
    opts = {
      on_attach = function(bufnr)
        local api = require("nvim-tree.api")
        api.map.on_attach.default(bufnr)
        vim.keymap.set("n", "bc", function()
          api.fs.copy.node(api.marks.list())
        end, {
          buffer = bufnr,
          desc = "nvim-tree: Copy Bookmarked",
          nowait = true,
        })
        vim.keymap.set("n", "<D-v>", api.fs.paste, {
          buffer = bufnr,
          desc = "nvim-tree: Paste",
        })
        vim.keymap.set("n", "<Esc>", api.marks.clear, {
          buffer = bufnr,
          desc = "nvim-tree: Clear Bookmarks",
          nowait = true,
        })
      end,
      view = {
        side = "right",
      },
      git = {
        enable = true,
        ignore = false,
      },
      renderer = {
        highlight_git = true,
        icons = {
          show = {
            git = true,
          },
        },
      },
    },
  },
}

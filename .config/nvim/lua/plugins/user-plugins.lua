return {

  {
    "lewis6991/gitsigns.nvim",
    opts = {
      current_line_blame = true,
    },
  },

  {
    "kylechui/nvim-surround",
    version = "*",
    event = "VeryLazy",
    config = function()
      require("nvim-surround").setup()
    end,
  },

  {
    "mg979/vim-visual-multi",
    lazy = false,
  },

  {
    "cappyzawa/trim.nvim",
    lazy = false,
    config = function()
      require("trim").setup {}
    end,
  },

  {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = { "markdown", "quarto" },
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-tree/nvim-web-devicons",
    },
    opts = {},
  },

  {
    "windwp/nvim-ts-autotag",
    event = "InsertEnter",
    config = function()
      require("nvim-ts-autotag").setup()
    end,
    lazy = false,
  },

  {
    "folke/zen-mode.nvim",
    cmd = "ZenMode",
    keys = {
      { "<leader>z", "<cmd>ZenMode<cr>", desc = "Toggle Zen Mode" },
    },
    opts = {},
  },

  {
    "xiyaowong/transparent.nvim",
    lazy = false,
    config = function()
      require("transparent").setup {
        extra_groups = {
          "NormalFloat",
          "NvimTreeNormal",
          "NvimTreeNormalNC",
          "NvimTreeEndOfBuffer",
        },
      }
      require("transparent").toggle(true)
    end,
  },

  {
    "andweeb/presence.nvim",
    lazy = false,
    config = function()
      require("presence").setup()
    end,
  },

  {
    "RRethy/vim-illuminate",
    event = "User FileOpened",
    lazy = false,
    config = function()
      require("illuminate").configure()
    end,
  },

  {
    "dlyongemallo/diffview-plus.nvim",
    cmd = {
      "DiffviewOpen",
      "DiffviewClose",
      "DiffviewFileHistory",
      "DiffviewFocusFiles",
      "DiffviewToggleFiles",
    },
    keys = {
      { "<leader>dv", "<cmd>DiffviewOpen<cr>", desc = "Open diffview" },
    },
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {},
    config = function(_, opts)
      local actions = require("diffview.actions")
      opts.keymaps = {
        file_panel = {
          { "n", "<space>", actions.toggle_stage_entry, { desc = "Stage / unstage selected entry" } },
          { "n", "a", actions.stage_all, { desc = "Stage all entries" } },
          { "n", "d", actions.restore_entry, { desc = "Discard (restore) selected entry" } },
          { "n", "r", actions.refresh_files, { desc = "Refresh files" } },
          { "n", "o", actions.open_file_external, { desc = "Open file in default application" } },
          { "n", "e", actions.goto_file_edit, { desc = "Edit file" } },
          { "n", "`", actions.listing_style, { desc = "Toggle list / tree view" } },
        },
      }
      require("diffview").setup(opts)
      local group = vim.api.nvim_create_augroup("DiffviewAutoSelect", { clear = true })
      vim.api.nvim_create_autocmd({ "FileType", "BufNew" }, {
        group = group,
        pattern = { "DiffviewFiles", "DiffviewFileHistory" },
        callback = function(event)
          local buf = event.buf
          local last = { line = -1, path = nil }
          local function auto_open()
            local view = require("diffview.lib").get_current_view()
            if not view or not view.panel or not view.panel:is_open() then
              return
            end
            local item = view.panel:get_item_at_cursor()
            if not item or type(item.collapsed) == "boolean" then
              return
            end
            local path = item.path
            local line = vim.api.nvim_win_get_cursor(0)[1]
            if line == last.line and path == last.path then
              return
            end
            last.line, last.path = line, path
            pcall(function()
              view:set_file(item, false)
            end)
          end
          vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
            group = group,
            buffer = buf,
            callback = auto_open,
          })
          vim.keymap.set("n", "<LeftMouse>", auto_open, { buffer = buf, silent = true })
        end,
      })
    end,
  },

  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    event = "VeryLazy",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
  },

  {
    "MagicDuck/grug-far.nvim",
    cmd = "GrugFar",
    keys = {
      { "<leader>sr", "<cmd>GrugFar<cr>", desc = "Search & Replace" },
    },
    opts = {
      engine = "ripgrep",
    },
  },
}

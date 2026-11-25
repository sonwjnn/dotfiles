local options = {
  formatters = {
    prettierd = { require_config = true },
    prettier = { require_config = true },
    biome = { require_config = true },
  },

  formatters_by_ft = {
    lua = { "stylua" },
    javascript = { "biome", "prettierd", stop_after_first = true },
    javascriptreact = { "biome", "prettierd", stop_after_first = true },
    typescript = { "biome", "prettierd", stop_after_first = true },
    typescriptreact = { "biome", "prettierd", stop_after_first = true },
    json = { "biome" },
    jsonc = { "biome" },
    html = { "prettier" },
    css = { "biome", "prettier" },
    markdown = { "prettier" },
    c = { "clang_format" },
    cpp = { "clang_format" },
  },

  format_on_save = {
    timeout_ms = 500,
    lsp_format = "fallback",
  },
}

return options

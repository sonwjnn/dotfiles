local null_ls = require "null-ls"

local b = null_ls.builtins

local augroup = vim.api.nvim_create_augroup("LspFormatting", {})

local lsp_formatting = function(bufnr)
  vim.lsp.buf.format {
    filter = function(client)
      return client.name == "null-ls"
    end,
    bufnr = bufnr,
  }
end

local sources = {
  -- b.formatting.prettierd,
  b.diagnostics.eslint_d.with {
    diagnostics_format = "[eslint] #{m}\n(#{c})",
  },

  -- webdev stuff

  b.formatting.deno_fmt, -- choosed deno for ts/js files cuz its very fast!
  b.formatting.prettier.with { filetypes = { "html", "markdown", "css" } }, -- so prettier works only on these filetypes

  -- Lua
  b.formatting.stylua,

  -- cpp
  b.formatting.clang_format,

  -- php
  b.formatting.blade_formatter,
  b.formatting.phpcsfixer,

  -- typescript code action
  require "typescript.extensions.null-ls.code-actions",
}

local on_attach = function(client, bufnr)
  if client.supports_method "textDocument/formatting" then
    vim.api.nvim_clear_autocmds { group = augroup, buffer = bufnr }
    vim.api.nvim_create_autocmd("BufWritePre", {
      group = augroup,
      buffer = bufnr,
      callback = function()
        lsp_formatting(bufnr)
      end,
    })
  end
end

null_ls.setup {
  debug = true,
  sources = sources,
  on_attach = on_attach,
}

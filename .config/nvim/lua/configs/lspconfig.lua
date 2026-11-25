require("nvchad.configs.lspconfig").defaults()

vim.env.PATH = vim.fn.stdpath("data") .. "/mason/bin:" .. vim.env.PATH

local servers = { "emmet_ls", "html", "cssls", "tailwindcss", "biome", "ts_ls", "clangd" }
vim.lsp.enable(servers)

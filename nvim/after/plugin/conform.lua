local conform = require("conform")

conform.setup({
  -- Define formatters for filetypes
  formatters_by_ft = {
    lua = { "stylua" },
    -- Prioritize prettierd, fallback to prettier
    javascript = { "prettierd", "prettier" },
    typescript = { "prettierd", "prettier" },
    javascriptreact = { "prettierd", "prettier" },       -- JSX
    typescriptreact = { "prettierd", "prettier" },       -- TSX
    svelte = { "prettierd", "prettier" },
    css = { "prettierd", "prettier" },
    html = { "prettierd", "prettier" },
    json = { "prettierd", "prettier" },
    yaml = { "prettierd", "prettier" },
    markdown = { "prettierd", "prettier" },
    graphql = { "prettierd", "prettier" },
    -- Add other languages
    python = { "ruff_format", "black" },       -- Try ruff first
    sh = { "shfmt" },
  },

  -- Configure format-on-save
  -- format_on_save = {
  --   timeout_ms = 500,
  --   lsp_fallback = true,       -- Try LSP formatter if conform fails
  -- },

  -- Optional: Run async (recommended)
  -- format_after_save = false, -- Use if format_on_save is problematic

  -- Optional: Logging/Debugging
  log_level = vim.log.levels.WARN,
  notify_on_error = true,
})

-- Optional: User command for manual formatting
-- Allows formatting visual selections e.g. V G :Format
vim.api.nvim_create_user_command("Format", function(args)
  conform.format({
    async = true,
    lsp_fallback = true,
    range = args.range,
  })
end, { range = true })
local map = vim.keymap.set
local opt = { noremap = true, silent = true }

-- ADD THIS KEYMAP:
-- Format current buffer or range (visual mode) using Conform
map({ "n", "v" }, "<leader>ff", function() -- Choose your keys, e.g., <leader>gf
  require("conform").format({ async = true, lsp_fallback = true })
end, { desc = "Format buffer or range [Conform]" })

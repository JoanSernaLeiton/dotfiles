-- UI consistency configuration for LSP and Telescope
local border_style = "rounded"
local float_alpha = 10

-- Set consistent border style for all floating windows
vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(
  vim.lsp.handlers.hover, {
    border = border_style,
  }
)

vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(
  vim.lsp.handlers.signature_help, {
    border = border_style,
  }
)

-- Diagnostic display configuration
vim.diagnostic.config({
  float = {
    border = border_style,
    source = "always",
    header = "",
    prefix = "",
  },
  virtual_text = {
    prefix = '●',
    source = "if_many",
    spacing = 4,
  },
  signs = true,
  underline = true,
  update_in_insert = false,
  severity_sort = true,
})

-- Floating window appearance
vim.opt.pumblend = float_alpha
vim.opt.winblend = float_alpha
vim.opt.termguicolors = true

-- Diagnostic icons
local signs = {
  Error = "✘",
  Warn = "▲",
  Hint = "⚑",
  Info = "»",
}

for type, icon in pairs(signs) do
  local hl = "DiagnosticSign" .. type
  vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
end

-- CMP styling (completion menu)
local cmp_available, cmp = pcall(require, "cmp")
if cmp_available then
  cmp.setup({
    window = {
      completion = {
        border = border_style,
        winhighlight = "Normal:CmpPmenu,FloatBorder:CmpPmenuBorder,CursorLine:PmenuSel",
      },
      documentation = {
        border = border_style,
      },
    },
  })
end

-- Enhanced telescope highlighting
vim.api.nvim_set_hl(0, "TelescopePromptTitle", { link = "Title" })
vim.api.nvim_set_hl(0, "TelescopeResultsTitle", { link = "Title" })
vim.api.nvim_set_hl(0, "TelescopePreviewTitle", { link = "Title" })

-- Consistent telescope UI settings
require('telescope').setup({
  defaults = {
    winblend = float_alpha,
    borderchars = { "─", "│", "─", "│", "╭", "╮", "╯", "╰" },
  }
})

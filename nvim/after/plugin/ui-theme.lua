-- UI consistency configuration for LSP and Telescope
local border_style = "rounded"
local float_alpha = 10

-- Hover/signature borders are passed directly in the LSP keymaps (lsp-zero.lua):
-- since Neovim 0.11 vim.lsp.buf.hover() no longer goes through vim.lsp.handlers.

-- Diagnostic icons
local signs = {
  [vim.diagnostic.severity.ERROR] = "✘",
  [vim.diagnostic.severity.WARN] = "▲",
  [vim.diagnostic.severity.HINT] = "⚑",
  [vim.diagnostic.severity.INFO] = "»",
}
local sign_numhl = {
  [vim.diagnostic.severity.ERROR] = "DiagnosticSignError",
  [vim.diagnostic.severity.WARN] = "DiagnosticSignWarn",
  [vim.diagnostic.severity.HINT] = "DiagnosticSignHint",
  [vim.diagnostic.severity.INFO] = "DiagnosticSignInfo",
}

-- Diagnostic display configuration (the single source of truth: loads after
-- lsp-zero.lua, so it wins over any earlier vim.diagnostic.config call)
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
  signs = { text = signs, numhl = sign_numhl },
  underline = true,
  update_in_insert = false,
  severity_sort = true,
})

-- Floating window appearance
vim.opt.pumblend = float_alpha
vim.opt.winblend = float_alpha
vim.opt.termguicolors = true

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

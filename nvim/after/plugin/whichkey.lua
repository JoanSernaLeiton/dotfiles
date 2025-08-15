-- whichkey.lua

local wk = require("which-key")

-- Basic WhichKey setup with the corrected 'win' option
wk.setup({
  plugins = {
    marks = true,
    registers = true,
    presets = {
      operators = true,
      motions = true,
      text_objects = true,
      windows = true,
      nav = true,
      z = true,
      g = true,
    },
  },
  -- The 'position' key has been removed as it's no longer valid
  win = {
    border = "rounded",
  },
  triggers = {
    { "<leader>", mode = { "n", "v" } },
  },
})

-- Register all keymaps in a single call for clarity
wk.add({
  -- Avante AI Group
  { "<leader>a", group = "AI (Avante)" },
  { "<leader>aa", "<cmd>AvanteAsk<CR>", desc = "Ask Avante" },
  { "<leader>at", "<cmd>AvanteToggle<CR>", desc = "Toggle Avante Sidebar" },
  { "<leader>ap", "<cmd>AvanteSwitchProvider<CR>", desc = "Switch Provider" },
  -- LSP Group
  { "<leader>l", group = "LSP" },
  { "<leader>lf", "<cmd>LspZeroFormat<CR>", desc = "Format Buffer" },
  { "<leader>lr", "<cmd>LspRestart<CR>", desc = "Restart LSP" },
  { "<leader>lS", "<cmd>LspStop<CR>", desc = "Stop LSP" },
  { "<leader>li", "<cmd>LspInfo<CR>", desc = "LSP Info" },
  { "<leader>lv", "<cmd>LspZeroViewConfigSource<CR>", desc = "View Config Source" },

  -- Code Actions
  { "<leader>lc", group = "Code" },
  { "<leader>lca", "<cmd>lua vim.lsp.buf.code_action()<CR>", desc = "Code Actions" },
  { "<leader>lcr", "<cmd>lua vim.lsp.buf.rename()<CR>", desc = "Rename Symbol" },
  { "<leader>lcf", "<cmd>lua vim.lsp.buf.format({async = true})<CR>", desc = "Format" },

  -- Diagnostics
  { "<leader>ld", group = "Diagnostics" },
  { "<leader>ldd", "<cmd>Telescope diagnostics<CR>", desc = "All Diagnostics (Telescope)" },
  { "<leader>ldc", "<cmd>lua vim.diagnostic.open_float()<CR>", desc = "Current Diagnostics" },
  { "<leader>ldl", "<cmd>lua vim.diagnostic.setloclist()<CR>", desc = "List All" },
  { "<leader>ldb", "<cmd>Telescope diagnostics bufnr=0<CR>", desc = "Buffer Diagnostics (Telescope)" },

  -- Symbols/References
  { "<leader>ls", group = "Symbols" },
  { "<leader>lsd", "<cmd>Telescope lsp_document_symbols<CR>", desc = "Document Symbols" },
  { "<leader>lsw", "<cmd>Telescope lsp_dynamic_workspace_symbols<CR>", desc = "Workspace Symbols" },
  { "<leader>lsr", "<cmd>Telescope lsp_references<CR>", desc = "References" },
  { "<leader>lsi", "<cmd>Telescope lsp_implementations<CR>", desc = "Implementations" },
  { "<leader>lst", "<cmd>Telescope lsp_type_definitions<CR>", desc = "Type Definitions" },

  -- Jump
  { "<leader>lj", group = "Jump" },
  { "<leader>ljd", "<cmd>Telescope lsp_definitions<CR>", desc = "Jump to Definition" },
  { "<leader>ljD", "<cmd>lua vim.lsp.buf.declaration()<CR>", desc = "Jump to Declaration" },

  -- Navigation mappings using 'g' prefix
  { "gd", "<cmd>Telescope lsp_definitions<CR>", desc = "Go to Definition" },
  { "gr", "<cmd>Telescope lsp_references<CR>", desc = "Find References" },
  { "gi", "<cmd>Telescope lsp_implementations<CR>", desc = "Go to Implementation" },
  { "gt", "<cmd>Telescope lsp_type_definitions<CR>", desc = "Go to Type Definition" },
  { "gs", "<cmd>lua vim.lsp.buf.signature_help()<CR>", desc = "Show Signature Help" },

  -- Diagnostics navigation
  { "[d", "<cmd>lua vim.diagnostic.goto_prev()<CR>", desc = "Previous Diagnostic" },
  { "]d", "<cmd>lua vim.diagnostic.goto_next()<CR>", desc = "Next Diagnostic" },

  -- Documentation hover
  { "K", "<cmd>lua vim.lsp.buf.hover()<CR>", desc = "Show Documentation" },
})

-- Make WhichKey available globally
_G.which_key = wk

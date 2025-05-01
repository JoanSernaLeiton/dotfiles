-- WhichKey configuration with Telescope integration for LSP functionality
local wk = require("which-key")

-- Basic WhichKey setup
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
  window = {
    border = "rounded",
    position = "bottom",
  },
})

-- Register LSP structure with Telescope integration
wk.register({
  ["<leader>l"] = {
    name = "LSP",
    -- Top-level commands
    f = { "<cmd>LspZeroFormat<CR>", "Format Buffer" },
    r = { "<cmd>LspRestart<CR>", "Restart LSP" },
    S = { "<cmd>LspStop<CR>", "Stop LSP" },
    s = { "<cmd>LspStart<CR>", "Start LSP" },
    i = { "<cmd>LspInfo<CR>", "LSP Info" },
    v = { "<cmd>LspZeroViewConfigSource<CR>", "View Config Source" },

    -- Code actions submenu
    c = {
      name = "Code",
      a = { "<cmd>lua vim.lsp.buf.code_action()<CR>", "Code Actions" },
      r = { "<cmd>lua vim.lsp.buf.rename()<CR>", "Rename Symbol" },
      f = { "<cmd>lua vim.lsp.buf.format({async = true})<CR>", "Format" },
    },

    -- Diagnostics submenu with Telescope integration
    d = {
      name = "Diagnostics",
      -- Use Telescope for global diagnostics
      d = { "<cmd>Telescope diagnostics<CR>", "All Diagnostics (Telescope)" },
      -- Use native LSP for current buffer diagnostics
      c = { "<cmd>lua vim.diagnostic.open_float()<CR>", "Current Diagnostics" },
      l = { "<cmd>lua vim.diagnostic.setloclist()<CR>", "List All" },
      -- Buffer-specific diagnostics via Telescope
      b = { "<cmd>Telescope diagnostics bufnr=0<CR>", "Buffer Diagnostics (Telescope)" },
    },

    -- Symbols/References submenu with Telescope
    s = {
      name = "Symbols",
      d = { "<cmd>Telescope lsp_document_symbols<CR>", "Document Symbols" },
      w = { "<cmd>Telescope lsp_dynamic_workspace_symbols<CR>", "Workspace Symbols" },
      r = { "<cmd>Telescope lsp_references<CR>", "References" },
      i = { "<cmd>Telescope lsp_implementations<CR>", "Implementations" },
      t = { "<cmd>Telescope lsp_type_definitions<CR>", "Type Definitions" },
    },

    -- Jump to definition/declaration with Telescope
    j = {
      name = "Jump",
      d = { "<cmd>Telescope lsp_definitions<CR>", "Jump to Definition" },
      D = { "<cmd>lua vim.lsp.buf.declaration()<CR>", "Jump to Declaration" },
    },
  }
})

-- Navigation mappings using 'g' prefix with Telescope integration
wk.register({
  g = {
    d = { "<cmd>Telescope lsp_definitions<CR>", "Go to Definition" },
    r = { "<cmd>Telescope lsp_references<CR>", "Find References" },
    i = { "<cmd>Telescope lsp_implementations<CR>", "Go to Implementation" },
    t = { "<cmd>Telescope lsp_type_definitions<CR>", "Go to Type Definition" },
    s = { "<cmd>lua vim.lsp.buf.signature_help()<CR>", "Show Signature Help" },
  }
})

-- Diagnostics navigation
wk.register({
  ["[d"] = { "<cmd>lua vim.diagnostic.goto_prev()<CR>", "Previous Diagnostic" },
  ["]d"] = { "<cmd>lua vim.diagnostic.goto_next()<CR>", "Next Diagnostic" },
})

-- Documentation hover
wk.register({
  K = { "<cmd>lua vim.lsp.buf.hover()<CR>", "Show Documentation" },
})

-- Make WhichKey available globally
_G.which_key = wk

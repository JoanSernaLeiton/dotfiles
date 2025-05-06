-- Core requirements
local lsp_zero = require('lsp-zero')
local mason_lspconfig = require('mason-lspconfig')
local cmp = require('cmp')
local cmp_action = lsp_zero.cmp_action()
local mason = require('mason')

-- Get WhichKey - either from global or by requiring it
local wk = _G.which_key or require("which-key")

-----------------------------------
-- LSP Attach Configuration
-----------------------------------
local function get_lsp_attach_config()
  return function(client, bufnr)
    -- Set up buffer-specific keymaps
    local opts = { buffer = bufnr, noremap = true, silent = true }

    -- Register LSP keymaps with WhichKey
    wk.register({
      -- Navigation mappings (g prefix)
      g = {
        name = "LSP Navigation",
        d = { vim.lsp.buf.definition, "Go to Definition" },
        D = { vim.lsp.buf.declaration, "Go to Declaration" },
        i = { vim.lsp.buf.implementation, "Go to Implementation" },
        t = { vim.lsp.buf.type_definition, "Go to Type Definition" },
        r = { vim.lsp.buf.references, "Find References" },
        s = { vim.lsp.buf.signature_help, "Show Signature Help" },
      },

      -- Documentation hover
      K = { vim.lsp.buf.hover, "Show Documentation" },

      -- Diagnostics navigation
      ["["] = { d = { vim.diagnostic.goto_prev, "Previous Diagnostic" } },
      ["]"] = { d = { vim.diagnostic.goto_next, "Next Diagnostic" } },

      -- Leader mappings
      ["<leader>l"] = {
        -- Code actions - add to the existing structure registered in whichkey.lua
        c = {
          name = "Code",
          a = { vim.lsp.buf.code_action, "Code Actions" },
          r = { vim.lsp.buf.rename, "Rename Symbol" },
          f = { function() vim.lsp.buf.format({ async = true }) end, "Format" },
        },

        -- Diagnostics - add to the existing structure registered in whichkey.lua
        d = {
          name = "Diagnostics",
          d = { vim.diagnostic.open_float, "Show Details" },
          l = { vim.diagnostic.setloclist, "List All" },
          x = {
            function()
              local opts = {
                focusable = true,
                close_events = { "BufLeave", "CursorMoved", "InsertEnter", "FocusLost" },
                border = 'rounded',
                source = 'always',
                prefix = ' ',
                scope = 'cursor',
              }
              vim.diagnostic.open_float(opts)
            end,
            "Show Focused Floating Diagnostic"
          },
        },
      },

      -- Workspace
      ["<leader>w"] = {
        name = "Workspace",
        a = { vim.lsp.buf.add_workspace_folder, "Add Folder" },
        r = { vim.lsp.buf.remove_workspace_folder, "Remove Folder" },
        l = { function() print(vim.inspect(vim.lsp.buf.list_workspace_folders())) end, "List Folders" },
      },

      -- TypeScript specific
      ["<leader>t"] = {
        name = "TypeScript",
        i = { "<cmd>TypescriptAddMissingImports<CR>", "Add Missing Imports" },
        o = { "<cmd>TypescriptOrganizeImports<CR>", "Organize Imports" },
        u = { "<cmd>TypescriptRemoveUnused<CR>", "Remove Unused" },
        f = { "<cmd>TypescriptFixAll<CR>", "Fix All" },
      },
    }, { buffer = bufnr })

    -- Visual mode mappings
    wk.register({
      ["<leader>l"] = {
        c = {
          name = "Code",
          a = { vim.lsp.buf.code_action, "Code Actions" },
          f = { function() vim.lsp.buf.format({ async = true }) end, "Format Selection" },
        }
      },
    }, { mode = "v", buffer = bufnr })

    -- Insert mode mappings
    wk.register({
      ["<C-k>"] = { vim.lsp.buf.signature_help, "Show Signature Help" },
    }, { mode = "i", buffer = bufnr })

    -- Inlay hints toggle (if supported)
    if client:supports_method("textDocument/inlayHint") and vim.lsp.inlay_hint then
      wk.register({
        ["<leader>u"] = {
          name = "UI",
          h = { function()
            vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
          end, "Toggle Inlay Hints" },
        }
      }, { buffer = bufnr })
    end

    -- Format on save if supported
    -- if client:supports_method("textDocument/formatting") then
    --   vim.api.nvim_create_autocmd("BufWritePre", {
    --     buffer = bufnr,
    --     callback = function()
    --       vim.lsp.buf.format({ bufnr = bufnr })
    --     end,
    --   })
    -- end

    -- Highlight symbol references
    lsp_zero.highlight_symbol(client, bufnr)

    -- Set omnifunc
    vim.bo[bufnr].omnifunc = 'v:lua.vim.lsp.omnifunc'
  end
end

-----------------------------------
-- Completion Configuration
-----------------------------------
cmp.setup({
  preselect = 'item',
  completion = {
    completeopt = 'menu,menuone,noinsert'
  },
  mapping = cmp.mapping.preset.insert({
    ['<C-Space>'] = cmp.mapping.complete(),
    ['<C-f>'] = cmp_action.luasnip_jump_forward(),
    ['<C-b>'] = cmp_action.luasnip_jump_backward(),
    ['<C-u>'] = cmp.mapping.scroll_docs(-4),
    ['<C-d>'] = cmp.mapping.scroll_docs(4),
    ['<CR>'] = cmp.mapping.confirm({ select = true }),
    ['<Tab>'] = cmp_action.luasnip_supertab(),
    ['<S-Tab>'] = cmp_action.luasnip_shift_supertab(),
    ['<C-n>'] = cmp.mapping.select_next_item(),
    ['<C-p>'] = cmp.mapping.select_prev_item(),
  }),
  sources = {
    { name = 'nvim_lsp', priority = 1000 },
    { name = 'luasnip',  priority = 750 },
    { name = 'buffer',   priority = 500 },
    { name = 'path',     priority = 250 },
  },
  formatting = lsp_zero.cmp_format({ details = true }),
})

-----------------------------------
-- Diagnostics Configuration
-----------------------------------
vim.diagnostic.config({
  signs = true,
  virtual_text = {
    prefix = '●',
    source = "if_many",
    spacing = 4,
  },
  float = {
    source = "always",
    border = "rounded",
    header = "",
    prefix = "",
  },
  underline = true,
  update_in_insert = false,
  severity_sort = true,
})

-----------------------------------
-- LSP Core Configuration
-----------------------------------
lsp_zero.extend_lspconfig({
  sign_text = {
    error = '✘',
    warn = '▲',
    hint = '⚑',
    info = '»',
  },
  float_border = 'rounded',
  lsp_attach = get_lsp_attach_config(),
  capabilities = require('cmp_nvim_lsp').default_capabilities()
})

-----------------------------------
-- Mason Configuration
-----------------------------------
mason.setup({
  ui = {
    border = 'rounded',
    icons = {
      package_installed = "✓",
      package_pending = "➜",
      package_uninstalled = "✗"
    }
  }
})

-----------------------------------
-- Server Configuration
-----------------------------------
-- Determine which servers to install
local base_servers = {
  'ts_ls',    -- TypeScript
  'html',     -- HTML
  'cssls',    -- CSS
  'emmet_ls', -- Emmet
  'pyright',  -- Python
  'gopls',    -- Go
  'jsonls',   -- JSON
  'prettierd'
}

local conditional_servers = {}
local project_files = {
  { 'eslint',       { '.eslintrc.js', '.eslintrc.json', '.eslintrc', '.eslintrc.yml', '.eslintrc.yaml' } },
  { 'angularls',    { 'angular.json' } },
  { 'astro',        { 'astro.config.mjs', 'astro.config.js' } },
  { 'intelephense', { 'composer.json', 'artisan', '.php-version' } },
}

-- Check for files that indicate specific servers are needed
for _, server_info in ipairs(project_files) do
  local server_name = server_info[1]
  local files = server_info[2]
  for _, file in ipairs(files) do
    if vim.fn.filereadable(file) == 1 then
      table.insert(conditional_servers, server_name)
      break
    end
  end
end

-- Combine servers
local ensure_installed = vim.tbl_extend('force', base_servers, conditional_servers)

-----------------------------------
-- Server Setup
-----------------------------------
mason_lspconfig.setup({
  ensure_installed = ensure_installed,
  handlers = {
    lsp_zero.default_setup,

    -- TypeScript Server Configuration
    ['ts_ls'] = function()
      local common_inlay_hints = {
        includeInlayParameterNameHints = "all", -- 'none', 'literals', 'all'
        includeInlayFunctionParameterTypeHints = true,
        includeInlayVariableTypeHints = true, -- Recommended: true
        includeInlayPropertyDeclarationTypeHints = true,
        includeInlayFunctionLikeReturnTypeHints = true,
        includeInlayEnumMemberValueHints = true,
      }
      require('lspconfig').ts_ls.setup({
        on_attach = get_lsp_attach_config(),
        settings = {
          tsserver_max_ts_server_memory = 4096, -- e.g., 4GB
          typescript = {
            inlayHints = common_inlay_hints
          },
          javascript = {
            inlayHints = common_inlay_hints
          }
        }
      })
    end,

    -- Golang Configuration
    ['gopls'] = function()
      require('lspconfig').gopls.setup({
        on_attach = get_lsp_attach_config(),
        settings = {
          gopls = {
            analyses = { unusedparams = true },
            staticcheck = true,
            gofumpt = true,
          },
        }
      })
    end,

    -- PHP/Laravel Configuration
    ['intelephense'] = function()
      require('lspconfig').intelephense.setup({
        on_attach = get_lsp_attach_config(),
        settings = {
          intelephense = {
            files = { maxSize = 1000000 },
          },
        }
      })
    end,
  }
})

-- Add custom filetypes
vim.filetype.add({
  extension = {
    astro = "astro",
  }
})

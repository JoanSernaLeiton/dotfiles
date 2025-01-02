local lsp_zero = require('lsp-zero')
local mason_lspconfig = require('mason-lspconfig')
local cmp = require('cmp')
local cmp_action = lsp_zero.cmp_action()
local mason = require('mason')

-- Configure Mason
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

-- Configure diagnostic signs
vim.fn.sign_define("DiagnosticSignError", { text = "✘", texthl = "DiagnosticSignError" })
vim.fn.sign_define("DiagnosticSignWarn", { text = "▲", texthl = "DiagnosticSignWarn" })
vim.fn.sign_define("DiagnosticSignInfo", { text = "»", texthl = "DiagnosticSignInfo" })
vim.fn.sign_define("DiagnosticSignHint", { text = "⚑", texthl = "DiagnosticSignHint" })

-- Configure diagnostics display
vim.diagnostic.config({
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
  signs = true,
  underline = true,
  update_in_insert = false,
  severity_sort = true,
})
lsp_zero.extend_lspconfig()

-- Helper function to check if a file exists
local function file_exists(file)
  local f = io.open(file, "rb")
  if f then f:close() end
  return f ~= nil
end

-- Helper function to check if any of the files exist in the current directory
local function any_file_exists(files)
  for _, file in ipairs(files) do
    if file_exists(vim.fn.getcwd() .. '/' .. file) then
      return true
    end
  end
  return false
end

-- Simplified root pattern function that doesn't rely on unpack
local function root_pattern(...)
  local patterns = { ... }
  return function(startpath)
    local util = require('lspconfig.util')
    for _, pattern in ipairs(patterns) do
      local matcher = util.root_pattern(pattern)
      local root = matcher(startpath)
      if root then
        return root
      end
    end
    return startpath
  end
end


-- Define lsp_attach function
local lsp_attach = function(client, bufnr)
  local opts = { buffer = bufnr }

  -- Basic mappings
  vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
  vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
  vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)
  vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, opts)
  vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, opts)
  vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, opts)
  vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
  vim.keymap.set('n', '<leader>f', vim.lsp.buf.format, opts)


  -- TypeScript specific keymaps
  if client.name == "ts_ls" then
    vim.keymap.set('n', '<leader>o', '<cmd>OrganizeImports<CR>', opts)
    vim.keymap.set('n', '<leader>ru', '<cmd>TypescriptRemoveUnused<CR>', opts)
    vim.keymap.set('n', '<leader>ri', '<cmd>TypescriptAddMissingImports<CR>', opts)
  end


  -- Enable inlay hints if available
  if client.server_capabilities.inlayHintProvider then
    if vim.lsp.inlay_hint then
      vim.keymap.set('n', '<leader>uh', function()
        print(bufnr)
        vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
      end, { desc = 'Toggle Inlay Hints' })
    end
  end
  -- Format on save if formatting is supported
  if client.supports_method("textDocument/formatting") then
    vim.api.nvim_create_autocmd("BufWritePre", {
      buffer = bufnr,
      callback = function()
        vim.lsp.buf.format({ bufnr = bufnr })
      end,
    })
  end

  vim.bo[bufnr].omnifunc = 'v:lua.vim.lsp.omnifunc'
  lsp_zero.highlight_symbol(client, bufnr)
end

-- Base list of servers that don't need special checks
local ensure_installed = {
  'ts_ls',    -- typescript, javascript
  'html',     -- html
  'cssls',    -- css
  'emmet_ls', -- emmet
  'pyright',  -- python
  'gopls',    -- golang
  'jsonls',   -- json
}

-- Conditional server installations based on project files
if any_file_exists({ '.eslintrc.js', '.eslintrc.json', '.eslintrc', '.eslintrc.yml', '.eslintrc.yaml' }) then
  table.insert(ensure_installed, 'eslint')
end

if any_file_exists({ 'angular.json' }) then
  table.insert(ensure_installed, 'angularls')
end

if any_file_exists({ 'astro.config.mjs', 'astro.config.js' }) then
  table.insert(ensure_installed, 'astro')
end

if any_file_exists({ 'tailwind.config.js', 'tailwind.config.cjs' }) then
  table.insert(ensure_installed, 'tailwindcss')
end

if any_file_exists({ 'composer.json', 'artisan', '.php-version' }) then
  table.insert(ensure_installed, 'intelephense')
end

-- Setup Mason with conditional installations
mason_lspconfig.setup({
  ensure_installed = ensure_installed,
  handlers = {
    lsp_zero.default_setup,

    -- TypeScript/JavaScript
    ['ts_ls'] = function()
      require('lspconfig').ts_ls.setup({
        on_attach = lsp_attach,
        root_dir = root_pattern("package.json", "tsconfig.json", "tsconfig.base.json", "jsconfig.json"),
        init_options = {
          hostInfo = 'neovim',
          preferences = {
            importModuleSpecifierPreference = 'relative', -- Important for Angular
            importModuleSpecifierEnding = 'minimal',
            includeInlayParameterNameHints = 'all',
            includeInlayParameterNameHintsWhenArgumentMatchesName = true,
            includeInlayFunctionParameterTypeHints = true,
            includeInlayVariableTypeHints = true,
            includeInlayPropertyDeclarationTypeHints = true,
            includeInlayFunctionLikeReturnTypeHints = true,
            includeInlayEnumMemberValueHints = true,
          }
        },
        settings = {
          typescript = {
            inlayHints = {
              includeInlayParameterNameHints = "all",
              includeInlayParameterNameHintsWhenArgumentMatchesName = true,
              includeInlayFunctionParameterTypeHints = true,
              includeInlayVariableTypeHints = true,
              includeInlayPropertyDeclarationTypeHints = true,
              includeInlayFunctionLikeReturnTypeHints = true,
              includeInlayEnumMemberValueHints = true,
              includeInlayVariableTypeHintsWhenTypeMatchesName = true
            },
            implementationsCodeLens = {
              enabled = true
            },
            referencesCodeLens = {
              enabled = true,
              showOnAllFunctions = true
            }
          },
          javascript = {
            format = {
              indentSize = 2,
              convertTabsToSpaces = true,
              tabSize = 2
            },
            inlayHints = {
              includeInlayParameterNameHints = "all",
              includeInlayParameterNameHintsWhenArgumentMatchesName = true,
              includeInlayFunctionParameterTypeHints = true,
              includeInlayVariableTypeHints = true,
              includeInlayPropertyDeclarationTypeHints = true,
              includeInlayFunctionLikeReturnTypeHints = true,
              includeInlayEnumMemberValueHints = true,
              includeInlayVariableTypeHintsWhenTypeMatchesName = true
            },
            implementationsCodeLens = {
              enabled = true
            },
            referencesCodeLens = {
              enabled = true,
              showOnAllFunctions = true
            }
          }
        },
        preferences = {
          importModuleSpecifierPreference = "non-relative",
          importModuleSpecifier = "non-relative",
          preferTypeOnlyAutoImports = false,
          includePackageJsonAutoImports = "on",
          allowIncompleteCompletions = true,
          allowRenameOfImportPath = true,
        },
        -- Enable code lens for references and implementations
        codeLens = {
          enable = true,
        },
      })
    end,

    -- ESLint
    eslint = function()
      if any_file_exists({ '.eslintrc.js', '.eslintrc.json', '.eslintrc', '.eslintrc.yml', '.eslintrc.yaml' }) then
        require('lspconfig').eslint.setup({
          -- on_attach = function(client, bufnr)
          --   lsp_attach(client, bufnr)
          --   -- Auto fix on save
          --   vim.api.nvim_create_autocmd("BufWritePre", {
          --     buffer = bufnr,
          --     command = "EslintFixAll",
          --   })
          -- end,
          settings = {
            format = true,
          },
          root_dir = root_pattern(
            '.eslintrc',
            '.eslintrc.js',
            '.eslintrc.json',
            '.eslintrc.yaml',
            '.eslintrc.yml',
            'package.json'
          )
        })
      end
    end,

    -- Angular
    angularls = function()
      if any_file_exists({ 'angular.json' }) then
        require('lspconfig').angularls.setup({
          on_attach = lsp_attach,
          root_dir = root_pattern('angular.json', 'project.json', 'nx.json'),
          capabilities = lsp_zero.get_capabilities(),
          filetypes = { 'typescript', 'html', 'typescriptreact', 'typescript.tsx', 'angular.html' }
        })
      end
    end,

    -- Astro
    astro = function()
      if any_file_exists({ 'astro.config.mjs', 'astro.config.js' }) then
        require('lspconfig').astro.setup({
          on_attach = lsp_attach,
          root_dir = root_pattern('astro.config.mjs', 'astro.config.js', 'package.json')
        })
      end
    end,

    -- PHP/Laravel
    intelephense = function()
      if any_file_exists({ 'composer.json', 'artisan', '.php-version' }) then
        require('lspconfig').intelephense.setup({
          on_attach = lsp_attach,
          root_dir = root_pattern('composer.json', 'artisan'),
          settings = {
            intelephense = {
              files = {
                maxSize = 1000000,
              },
            },
          }
        })
      end
    end,

    -- Python
    pyright = function()
      require('lspconfig').pyright.setup({
        on_attach = lsp_attach,
        root_dir = root_pattern('pyproject.toml', 'setup.py', 'requirements.txt', 'manage.py'),
        settings = {
          python = {
            analysis = {
              typeCheckingMode = "basic",
              autoSearchPaths = true,
              useLibraryCodeForTypes = true
            }
          }
        }
      })
    end,

    -- Golang
    gopls = function()
      if any_file_exists({ 'go.mod', 'go.work' }) then
        require('lspconfig').gopls.setup({
          on_attach = lsp_attach,
          root_dir = root_pattern('go.mod', 'go.work'),
          settings = {
            gopls = {
              analyses = {
                unusedparams = true,
              },
              staticcheck = true,
              gofumpt = true,
            },
          }
        })
      end
    end,
  }
})

-- Configure completion

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
  formatting = lsp_zero.cmp_format({ details = true })
})
vim.lsp.handlers["textDocument/publishDiagnostics"] = vim.lsp.with(
  vim.lsp.diagnostic.on_publish_diagnostics,
  {
    virtual_text = true,
  }
)

-- Set up custom filetypes
vim.filetype.add({
  extension = {
    astro = "astro",
  },
})

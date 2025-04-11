-- Core requirements
local lsp_zero = require('lsp-zero')
local mason_lspconfig = require('mason-lspconfig')
local cmp = require('cmp')
local cmp_action = lsp_zero.cmp_action()
local mason = require('mason')

-----------------------------------
-- Utility Functions
-----------------------------------
local Utils = {}

Utils.file_exists = function(file)
  local f = io.open(file, "rb")
  if f then f:close() end
  return f ~= nil
end

Utils.any_file_exists = function(files)
  for _, file in ipairs(files) do
    local filepath = vim.fn.getcwd() .. '/' .. file
    if Utils.file_exists(filepath) then
      return true
    end
  end
  return false
end

Utils.root_pattern = function(...)
  local patterns = { ... }
  return function(startpath)
    local util = require('lspconfig.util')
    for _, pattern in ipairs(patterns) do
      local matcher = util.root_pattern(pattern)
      local root = matcher(startpath)
      if root then return root end
    end
    return startpath
  end
end

-----------------------------------
-- Mason Configuration
-----------------------------------
local function setup_mason()
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
end

-----------------------------------
-- Diagnostic Configuration
-----------------------------------
local function setup_diagnostics()
  -- Configure diagnostic signs properly without using deprecated sign_define
  vim.diagnostic.config({
    signs = {
      text = {
        [vim.diagnostic.severity.ERROR] = "✘",
        [vim.diagnostic.severity.WARN] = "▲",
        [vim.diagnostic.severity.INFO] = "»",
        [vim.diagnostic.severity.HINT] = "⚑",
      },
      numhl = {
        [vim.diagnostic.severity.ERROR] = "DiagnosticSignError",
        [vim.diagnostic.severity.WARN] = "DiagnosticSignWarn",
        [vim.diagnostic.severity.INFO] = "DiagnosticSignInfo",
        [vim.diagnostic.severity.HINT] = "DiagnosticSignHint",
      },
      texthl = {
        [vim.diagnostic.severity.ERROR] = "DiagnosticSignError",
        [vim.diagnostic.severity.WARN] = "DiagnosticSignWarn",
        [vim.diagnostic.severity.INFO] = "DiagnosticSignInfo",
        [vim.diagnostic.severity.HINT] = "DiagnosticSignHint",
      },
    },
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
end

-----------------------------------
-- LSP Attach Configuration
-----------------------------------
local function get_lsp_attach_config()
  return function(client, bufnr)
    local opts = { buffer = bufnr, desc = '' }

    -- Navigation keymaps
    local navigation_maps = {
      { mode = 'n', key = 'gd', action = vim.lsp.buf.definition,      desc = 'Go to Definition' },
      { mode = 'n', key = 'gr', action = vim.lsp.buf.references,      desc = 'Go to References' },
      { mode = 'n', key = 'gi', action = vim.lsp.buf.implementation,  desc = 'Go to Implementation' },
      { mode = 'n', key = 'gt', action = vim.lsp.buf.type_definition, desc = 'Go to Type Definition' },
      { mode = 'n', key = 'gD', action = vim.lsp.buf.declaration,     desc = 'Go to Declaration' },
    }

    -- Documentation & Info keymaps
    local info_maps = {
      { mode = 'n', key = 'K',     action = vim.lsp.buf.hover,          desc = 'Show Hover Documentation' },
      { mode = 'n', key = '<C-k>', action = vim.lsp.buf.signature_help, desc = 'Show Signature Help' },
      { mode = 'i', key = '<C-k>', action = vim.lsp.buf.signature_help, desc = 'Show Signature Help' },
    }

    -- Code action keymaps
    local action_maps = {
      { mode = 'n', key = '<leader>ca', action = vim.lsp.buf.code_action, desc = 'Code Actions' },
      { mode = 'n', key = '<leader>rn', action = vim.lsp.buf.rename,      desc = 'Rename Symbol' },
      { mode = 'n', key = '<leader>f',  action = vim.lsp.buf.format,      desc = 'Format Document' },
    }

    -- Diagnostic keymaps
    local diagnostic_maps = {
      { mode = 'n', key = '[d',         action = vim.diagnostic.goto_prev,  desc = 'Previous Diagnostic' },
      { mode = 'n', key = ']d',         action = vim.diagnostic.goto_next,  desc = 'Next Diagnostic' },
      { mode = 'n', key = '<leader>d',  action = vim.diagnostic.open_float, desc = 'Show Diagnostic Float' },
      { mode = 'n', key = '<leader>dl', action = vim.diagnostic.setloclist, desc = 'Diagnostic List' },
    }

    -- Workspace keymaps
    local workspace_maps = {
      { mode = 'n', key = '<leader>wa', action = vim.lsp.buf.add_workspace_folder,    desc = 'Add Workspace Folder' },
      { mode = 'n', key = '<leader>wr', action = vim.lsp.buf.remove_workspace_folder, desc = 'Remove Workspace Folder' },
      {
        mode = 'n',
        key = '<leader>wl',
        action = function()
          print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
        end,
        desc = 'List Workspace Folders'
      },
    }

    -- TypeScript specific keymaps
    local typescript_maps = {
      { mode = 'n', key = '<leader>ti', action = '<cmd>TypescriptAddMissingImports<CR>', desc = 'Add Missing Imports' },
      { mode = 'n', key = '<leader>to', action = '<cmd>TypescriptOrganizeImports<CR>',   desc = 'Organize Imports' },
      { mode = 'n', key = '<leader>tu', action = '<cmd>TypescriptRemoveUnused<CR>',      desc = 'Remove Unused' },
      { mode = 'n', key = '<leader>tr', action = '<cmd>TypescriptRenameFile<CR>',        desc = 'Rename File' },
      { mode = 'n', key = '<leader>tf', action = '<cmd>TypescriptFixAll<CR>',            desc = 'Fix All' },
    }

    -- Set all basic keymaps
    local all_maps = {
      navigation_maps,
      info_maps,
      action_maps,
      diagnostic_maps,
      workspace_maps,
    }

    for _, map_group in ipairs(all_maps) do
      for _, map in ipairs(map_group) do
        opts.desc = map.desc
        vim.keymap.set(map.mode, map.key, map.action, opts)
      end
    end

    -- Set TypeScript specific keymaps if applicable
    if client.name == "tsserver" then
      for _, map in ipairs(typescript_maps) do
        opts.desc = map.desc
        vim.keymap.set(map.mode, map.key, map.action, opts)
      end
    end

    -- Inlay hints toggle - use updated method signature
    if client:supports_method("textDocument/inlayHint") and vim.lsp.inlay_hint then
      vim.keymap.set('n', '<leader>uh', function()
        vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
      end, { buffer = bufnr, desc = 'Toggle Inlay Hints' })
    end

    -- Format on save if supported - use updated method signature
    if client:supports_method("textDocument/formatting") then
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
end

-----------------------------------
-- Server Configurations
-----------------------------------
local ServerConfigs = {
  get_base_servers = function()
    return {
      'ts_ls',    -- typescript, javascript
      'html',     -- html
      'cssls',    -- css
      'emmet_ls', -- emmet
      'pyright',  -- python
      'gopls',    -- golang
      'jsonls',   -- json
    }
  end,

  get_conditional_servers = function()
    local servers = {}

    local server_conditions = {
      { files = { '.eslintrc.js', '.eslintrc.json', '.eslintrc', '.eslintrc.yml', '.eslintrc.yaml' }, server = 'eslint' },
      { files = { 'angular.json' },                                                                   server = 'angularls' },
      { files = { 'astro.config.mjs', 'astro.config.js' },                                            server = 'astro' },
      { files = { 'composer.json', 'artisan', '.php-version' },                                       server = 'intelephense' },
    }

    for _, condition in ipairs(server_conditions) do
      if Utils.any_file_exists(condition.files) then
        table.insert(servers, condition.server)
      end
    end

    return servers
  end,

  setup_handlers = function()
    return {
      lsp_zero.default_setup,

      ['ts_ls'] = function()
        local capabilities = lsp_zero.get_capabilities()
        require('lspconfig').ts_ls.setup({
          on_attach = get_lsp_attach_config(),
          capabilities = capabilities,
          root_dir = Utils.root_pattern("package.json", "tsconfig.json", "tsconfig.base.json", "jsconfig.json"),
          init_options = {
            hostInfo = 'neovim',
            preferences = {
              importModuleSpecifierPreference = 'no-relative',
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
              implementationsCodeLens = { enabled = true },
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
              implementationsCodeLens = { enabled = true },
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
          codeLens = { enable = true },
        })
      end,
      -- ESLint
      eslint = function()
        local eslint_config_files = {
          '.eslintrc.js',
          '.eslintrc.json',
          '.eslintrc',
          '.eslintrc.yml',
          '.eslintrc.yaml'
        }
        if Utils.any_file_exists(eslint_config_files) then
          if Utils.root_pattern(eslint_config_files) then
            require('lspconfig').eslint.setup({
              root_dir = Utils.root_pattern(
                '.eslintrc',
                '.eslintrc.js',
                '.eslintrc.json',
                '.eslintrc.yaml',
                '.eslintrc.yml',
                'package.json'
              ),
              on_attach = get_lsp_attach_config(),
              capabilities = lsp_zero.get_capabilities(),
              settings = {
                format = true,
                workingDirectory = { mode = 'auto' },
              },
              handlers = {
                ["window/showMessageRequest"] = function(_, result)
                  return result
                end
              }
            })
          end
        end
      end,
      -- Angular
      angularls = function()
        if Utils.root_pattern({ 'angular.json', 'project.json', 'nx.json' }) then
          require('lspconfig').angularls.setup({
            on_attach = get_lsp_attach_config(),
            root_dir = Utils.root_pattern('angular.json', 'project.json', 'nx.json'),
            filetypes = { 'typescript', 'html', 'angular.html' },
            capabilities = lsp_zero.get_capabilities(),
            cmd = {
              "ngserver",
              "--stdio",
              "--tsProbeLocations",
              vim.fn.getcwd() .. "/node_modules/typescript",
              "--ngProbeLocations",
              vim.fn.getcwd() .. "/node_modules/@angular/language-service"
            },
          })
        end
      end,
      -- Astro
      astro = function()
        if Utils.root_pattern({ 'astro.config.mjs', 'astro.config.js' }) then
          require('lspconfig').astro.setup({
            on_attach = get_lsp_attach_config(),
            root_dir = Utils.root_pattern('astro.config.mjs', 'astro.config.js', 'package.json')
          })
        end
      end,
      -- PHP/Laravel
      intelephense = function()
        if Utils.root_pattern({ 'composer.json', 'artisan', '.php-version' }) then
          require('lspconfig').intelephense.setup({
            on_attach = get_lsp_attach_config(),
            root_dir = Utils.root_pattern('composer.json', 'artisan'),
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
          on_attach = get_lsp_attach_config(),
          root_dir = Utils.root_pattern('pyproject.toml', 'setup.py', 'requirements.txt', 'manage.py'),
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
        if Utils.root_pattern({ 'go.mod', 'go.work' }) then
          require('lspconfig').gopls.setup({
            on_attach = get_lsp_attach_config(),
            root_dir = Utils.root_pattern('go.mod', 'go.work'),
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
      tailwindcss = function()
        require('lspconfig').tailwindcss.setup({
          filetypes = {
            "typescript",
            "typescriptreact",
            "javascript",
            "javascriptreact",
            "html",
            "css"
          },
          root_dir = Utils.root_pattern(
            'tailwind.config.js',
            'tailwind.config.ts',
            'postcss.config.js',
            'postcss.config.ts'
          ),
          settings = {
            tailwindCSS = {
              experimental = {
                classRegex = {
                  "tw`([^`]*)",
                  "tw\\.[^`]+`([^`]*)`",
                  "tw\\(.*?\\).*?`([^`]*)"
                }
              }
            }
          }
        })
      end,
    }
  end
}

-----------------------------------
-- Completion Configuration
-----------------------------------
local function setup_completion()
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
      { name = 'nvim_lsp',   priority = 1000 },
      { name = 'luasnip',    priority = 750 },
      { name = 'buffer',     priority = 500 },
      { name = 'path',       priority = 250 },
    },
    formatting = lsp_zero.cmp_format({ details = true }),
  })
end

-----------------------------------
-- Main Setup
-----------------------------------
local function main()
  -- Initialize core components
  setup_mason()
  setup_diagnostics()
  lsp_zero.extend_lspconfig()

  -- Setup LSP
  local ensure_installed = vim.tbl_extend('force',
    ServerConfigs.get_base_servers(),
    ServerConfigs.get_conditional_servers()
  )

  mason_lspconfig.setup({
    ensure_installed = ensure_installed,
    handlers = ServerConfigs.setup_handlers()
  })

  -- Setup completion
  setup_completion()

  -- Setup handlers with proper signatures
  vim.lsp.handlers["textDocument/publishDiagnostics"] = vim.lsp.with(
    vim.lsp.diagnostic.on_publish_diagnostics,
    { virtual_text = true }
  )

  -- Setup filetypes
  vim.filetype.add({
    extension = {
      astro = "astro",
    }
  })
end

-- Initialize everything
main()

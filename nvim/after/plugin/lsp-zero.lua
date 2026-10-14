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
    -- Note: Workspace/TypeScript/UI toggles live under <leader>l* (not their
    -- own top-level <leader>w/<leader>t/<leader>u) to avoid clashing with the
    -- global Window/Terminal/Undo Tree groups defined in whichkey.lua.
    wk.add({
      -- Navigation mappings (g prefix)
      { "g", group = "LSP Navigation", buffer = bufnr },
      { "gd", vim.lsp.buf.definition, desc = "Go to Definition", buffer = bufnr },
      { "gD", vim.lsp.buf.declaration, desc = "Go to Declaration", buffer = bufnr },
      { "gi", vim.lsp.buf.implementation, desc = "Go to Implementation", buffer = bufnr },
      { "gt", vim.lsp.buf.type_definition, desc = "Go to Type Definition", buffer = bufnr },
      { "gs", function() vim.lsp.buf.signature_help({ border = "rounded" }) end, desc = "Show Signature Help", buffer = bufnr },
      -- "gr" (Find References) intentionally not bound here: Neovim 0.11+
      -- already maps "grr" to vim.lsp.buf.references by default, and a bare
      -- "gr" would be an ambiguous prefix of "gra"/"gri"/"grn"/"grr"/"grt"/"grx".

      -- Documentation hover
      { "K", function() vim.lsp.buf.hover({ border = "rounded" }) end, desc = "Show Documentation", buffer = bufnr },

      -- Diagnostics navigation
      { "[d", vim.diagnostic.goto_prev, desc = "Previous Diagnostic", buffer = bufnr },
      { "]d", vim.diagnostic.goto_next, desc = "Next Diagnostic", buffer = bufnr },

      -- Code actions - add to the existing structure registered in whichkey.lua
      { "<leader>lc", group = "Code", buffer = bufnr },
      { "<leader>lca", vim.lsp.buf.code_action, desc = "Code Actions", buffer = bufnr },
      { "<leader>lcr", vim.lsp.buf.rename, desc = "Rename Symbol", buffer = bufnr },
      { "<leader>lcf", function() vim.lsp.buf.format({ async = true }) end, desc = "Format", buffer = bufnr },

      -- Diagnostics - add to the existing structure registered in whichkey.lua
      { "<leader>ld", group = "Diagnostics", buffer = bufnr },
      { "<leader>ldd", vim.diagnostic.open_float, desc = "Show Details", buffer = bufnr },
      { "<leader>ldl", vim.diagnostic.setloclist, desc = "List All", buffer = bufnr },
      {
        "<leader>ldx",
        function()
          vim.diagnostic.open_float({
            focusable = true,
            close_events = { "BufLeave", "CursorMoved", "InsertEnter", "FocusLost" },
            border = 'rounded',
            source = 'always',
            prefix = ' ',
            scope = 'cursor',
          })
        end,
        desc = "Show Focused Floating Diagnostic",
        buffer = bufnr,
      },

      -- Workspace
      { "<leader>lw", group = "Workspace", buffer = bufnr },
      { "<leader>lwa", vim.lsp.buf.add_workspace_folder, desc = "Add Folder", buffer = bufnr },
      { "<leader>lwr", vim.lsp.buf.remove_workspace_folder, desc = "Remove Folder", buffer = bufnr },
      {
        "<leader>lwl",
        function() print(vim.inspect(vim.lsp.buf.list_workspace_folders())) end,
        desc = "List Folders",
        buffer = bufnr,
      },

      -- TypeScript specific
      { "<leader>lt", group = "TypeScript", buffer = bufnr },
      { "<leader>lti", "<cmd>TypescriptAddMissingImports<CR>", desc = "Add Missing Imports", buffer = bufnr },
      { "<leader>lto", "<cmd>TypescriptOrganizeImports<CR>", desc = "Organize Imports", buffer = bufnr },
      { "<leader>ltu", "<cmd>TypescriptRemoveUnused<CR>", desc = "Remove Unused", buffer = bufnr },
      { "<leader>ltf", "<cmd>TypescriptFixAll<CR>", desc = "Fix All", buffer = bufnr },
    })

    -- Visual mode mappings
    wk.add({
      { "<leader>lc", group = "Code", mode = "v", buffer = bufnr },
      { "<leader>lca", vim.lsp.buf.code_action, desc = "Code Actions", mode = "v", buffer = bufnr },
      {
        "<leader>lcf",
        function() vim.lsp.buf.format({ async = true }) end,
        desc = "Format Selection",
        mode = "v",
        buffer = bufnr,
      },
    })

    -- Insert mode mappings
    wk.add({
      { "<C-k>", function() vim.lsp.buf.signature_help({ border = "rounded" }) end, desc = "Show Signature Help", mode = "i", buffer = bufnr },
    })

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
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = '✘',
      [vim.diagnostic.severity.WARN] = '▲',
      [vim.diagnostic.severity.HINT] = '⚑',
      [vim.diagnostic.severity.INFO] = '»',
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

-----------------------------------
-- LSP Core Configuration
-----------------------------------
-- mason-lspconfig no longer supports the old `setup({ handlers = ... })`
-- API; it auto-enables installed servers via vim.lsp.enable() instead.
-- Capabilities/settings are layered on via vim.lsp.config(), and keymaps
-- are wired through a plain LspAttach autocmd so they apply no matter how
-- a server gets started.
vim.lsp.config('*', {
  capabilities = require('cmp_nvim_lsp').default_capabilities(),
})

vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if client then
      get_lsp_attach_config()(client, args.buf)
    end
  end,
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
  'jsonls'   -- JSON
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
-- list_extend, not tbl_extend: tbl_extend merges list tables by index, so
-- conditional servers would overwrite base servers instead of appending.
local ensure_installed = vim.list_extend(vim.deepcopy(base_servers), conditional_servers)

-----------------------------------
-- Server Setup
-----------------------------------
mason_lspconfig.setup({
  ensure_installed = ensure_installed,
})

-- TypeScript Server Configuration
local common_inlay_hints = {
  includeInlayParameterNameHints = "all", -- 'none', 'literals', 'all'
  includeInlayFunctionParameterTypeHints = true,
  includeInlayVariableTypeHints = true, -- Recommended: true
  includeInlayPropertyDeclarationTypeHints = true,
  includeInlayFunctionLikeReturnTypeHints = true,
  includeInlayEnumMemberValueHints = true,
}

vim.lsp.config('ts_ls', {
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

-- Golang Configuration
vim.lsp.config('gopls', {
  settings = {
    gopls = {
      analyses = { unusedparams = true },
      staticcheck = true,
      gofumpt = true,
    },
  }
})

-- PHP/Laravel Configuration
vim.lsp.config('intelephense', {
  settings = {
    intelephense = {
      files = { maxSize = 1000000 },
    },
  }
})

-- Add custom filetypes
vim.filetype.add({
  extension = {
    astro = "astro",
    pug = "pug",
    templ = "templ",
    go = "go",
    gowork = "gowork",
    gotmpl = "gotmpl",
  },
  filename = {
    ["docker-compose.yaml"] = "yaml.docker-compose",
    ["docker-compose.yml"] = "yaml.docker-compose",
    ["compose.yaml"] = "yaml.docker-compose",
    ["compose.yml"] = "yaml.docker-compose",
    [".gitlab-ci.yml"] = "yaml.gitlab",
    ["values.yaml"] = "yaml.helm-values",
  },
  pattern = {
    [".gitlab/.*%.yml$"] = "yaml.gitlab",
    ["helm/.*/values%.yml$"] = "yaml.helm-values",
  },
})

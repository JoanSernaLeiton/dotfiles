require('mason').setup()
require('mason.settings').set({
  ui = {
    border = 'rounded'
  }
})

local lsp = require('lsp-zero')
local masonLsp = require('mason-lspconfig')
lsp.preset('recommended')
lsp.set_preferences({
  suggest_lsp_servers = true
})
lsp.setup()
masonLsp.setup({
  ensure_installed = {
    "tsserver",
    "html",
    "cssls",
    "eslint",
    "lua_ls",
    "angularls",
  },
  handlers = {
    lsp.default_setup,
  }
})

lsp.configure("lua_ls", {
  settings = {
    Lua = {
      diagnostics = {
        globals = { "vim" }
      },
    },
  },

})
local cmp = require("cmp")

cmp.setup({

  sources = {
    { name = 'nvim_lsp' },
  },
  window = {
    completion = cmp.config.window.bordered(),
    documentation = cmp.config.window.bordered(),
  },
  mapping = cmp.mapping.preset.insert({
    ['<C-Space>'] = cmp.mapping.complete(),
    ['<C-u>'] = cmp.mapping.scroll_docs(-4),
    ['<C-d>'] = cmp.mapping.scroll_docs(4),
    ["<C-p>"] = cmp.mapping.select_prev_item(cmp_select),
    ["<C-n>"] = cmp.mapping.select_next_item(cmp_select),
    ["<C-y>"] = cmp.mapping.confirm({ select = true }),
    ["<S-Tab>"] = cmp.mapping(function()
      if cmp.visible() then
        cmp.select_prev_item()
      elseif vim.fn["vsnip#jumpable"](-1) == 1 then
        feedkey("<Plug>vsnip-jump-prev", "")
      end
    end, { "i", "s" })
  })
})
local cmp_select = { behavior = cmp.SelectBehavior.Select }
lsp.on_attach(function(client, bufnr)
  local opts = { buffer = bufnr, remap = false }

  if client.name == "eslint" then
    vim.cmd.LspStop('eslint')
    return
  end

  vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
  vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
  vim.keymap.set("n", "<leader>vws", vim.lsp.buf.workspace_symbol, opts)
  vim.keymap.set("n", "<leader>vd", vim.diagnostic.open_float, opts)
  vim.keymap.set("n", "[d", vim.diagnostic.goto_next, opts)
  vim.keymap.set("n", "]d", vim.diagnostic.goto_prev, opts)
  vim.keymap.set("n", "<leader>vca", vim.lsp.buf.code_action, opts)
  vim.keymap.set("n", "<leader>vrr", vim.lsp.buf.references, opts)
  vim.keymap.set("n", "<leader>vrn", vim.lsp.buf.rename, opts)
  vim.keymap.set('n', '<leader>wa', vim.lsp.buf.add_workspace_folder, bufopts)
  vim.keymap.set('n', '<leader>wr', vim.lsp.buf.remove_workspace_folder, bufopts)
  vim.keymap.set('n', '<leader>wl', function()
    print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
  end, bufopts)
  vim.keymap.set("i", "<C-h>", vim.lsp.buf.signature_help, opts)
end)
local util = require "lspconfig".util

-- = util.root_pattern("angular.json","decorate-angular-cli.js")

require 'lspconfig'.angularls.setup {
  root_dir = util.root_pattern("angular.json", "project.json", 'nx.json'),
}
require 'lspconfig'.eslint.setup {
  filetypes = { "javascript", "typescript" },
  root_dir = function(fname)
    return util.root_pattern(".eslintrc.json")(fname) or
        util.root_pattern("tsconfig.json")(fname) or
        util.root_pattern(".eslintrc.js")(fname);
  end,
  init_options = {
    linters = {
      eslint_lsp = {
        command = "eslint",
        rootPatterns = { ".eslintrc.json", ".eslintrc.js", ".git" },
        debounce = 100,
        args = {
          "--stdin",
          "--stdin-filename",
          "%filepath",
          "--format",
          "json"
        },
        sourceName = "eslint",
        parseJson = {
          errorsRoot = "[0].messages",
          line = "line",
          column = "column",
          endLine = "endLine",
          endColumn = "endColumn",
          message = "[eslint] ${message} [${ruleId}]",
          security = "severity"
        },
        securities = {
          [2] = "error",
          [1] = "warning"
        }
      },
    }
  }
}

vim.lsp.handlers["textDocument/publishDiagnostics"] = vim.lsp.with(
  vim.lsp.diagnostic.on_publish_diagnostics,
  {
    virtual_text = true,
  }
)

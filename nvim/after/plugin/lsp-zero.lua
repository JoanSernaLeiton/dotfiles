require('mason.settings').set({
  ui = {
    border = 'rounded'
  }
})

local lsp_zero = require('lsp-zero')
lsp_zero.extend_lspconfig()
lsp_zero.preset('recommended')
lsp_zero.set_preferences({
  suggest_lsp_servers = true
})
lsp_zero.setup()
local mason = require('mason')
mason.setup({})
local masonLsp = require('mason-lspconfig')
local util = require "lspconfig".util
masonLsp.setup({
  ensure_installed = {
    "angularls",
    "tsserver",
    "html",
    "cssls",
    "eslint",
    "lua_ls"
  },
  handlers = {
    eslint = function ()
      require('lspconfig').eslint.setup({
        filetypes = { "javascript", "typescript", "angular.html", "html" },
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
      })
    end
  }
})

lsp_zero.configure("lua_ls", {
  settings = {
    Lua = {
      diagnostics = {
        globals = { "vim" }
      },
    },
  },

})
local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities = require('cmp_nvim_lsp').default_capabilities(capabilities)
local cmp = require("cmp")
local luasnip = require 'luasnip'
local cmp_action = require('lsp-zero').cmp_action()
local cmp_select = { behavior = cmp.SelectBehavior.Select }
cmp.setup{
  window = {
    completion = cmp.config.window.bordered(),
    documentation = cmp.config.window.bordered(),
  },
  mapping = cmp.mapping.preset.insert({
    ["<C-p>"] = cmp.mapping.select_prev_item(cmp_select),
    ["<C-n>"] = cmp.mapping.select_next_item(cmp_select),
    ["<Enter>"] = cmp.mapping.confirm({ select = true }),
    ['<C-Space>'] = cmp.mapping.complete(),
    ['<C-f>'] = cmp_action.luasnip_jump_forward(),
    ['<C-b>'] = cmp_action.luasnip_jump_backward(),
    ['<C-u>'] = cmp.mapping.scroll_docs(-4),
    ['<C-d>'] = cmp.mapping.scroll_docs(4),
    ['<Tab>'] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_next_item()
      elseif luasnip.expand_or_jumpable() then
        luasnip.expand_or_jump()
      else
        fallback()
      end
    end, { 'i', 's' }),
    ['<S-Tab>'] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_prev_item()
      elseif luasnip.jumpable(-1) then
        luasnip.jump(-1)
      else
        fallback()
      end
    end, { 'i', 's' }),
  }),
  sources = {
    {name = "nvim_lsp"}
  }
}
lsp_zero.on_attach(function(client, bufnr)
  local opts = { buffer = bufnr, remap = false }
  if client.name == "eslint" then
    -- vim.cmd.LspStop('eslint')
    return
  end
  vim.keymap.set('n', 'gr', '<cmd>Telescope lsp_references<cr>', {buffer = bufnr, desc = "Shows LSP references using Telescope"})
  vim.keymap.set("n", "gd", vim.lsp.buf.definition, {buffer = bufnr, remap = false, desc = "Jumps to definition using LSP"})
  vim.keymap.set("n", "K", vim.lsp.buf.hover, {buffer = bufnr, remap = false, desc = "Displays hover information using LSP"})
  vim.keymap.set("n", "<leader>vws", vim.lsp.buf.workspace_symbol, {buffer = bufnr, remap = false, desc = "Searches workspace symbols using LSP"})
  vim.keymap.set("n", "<leader>vd", vim.diagnostic.open_float, {buffer = bufnr, remap = false, desc = "Displays diagnostic float window"})
  vim.keymap.set("n", "[d", vim.diagnostic.goto_next, {buffer = bufnr, remap = false, desc = "Navigates to next diagnostic"})
  vim.keymap.set("n", "]d", vim.diagnostic.goto_prev, {buffer = bufnr, remap = false, desc = "Navigates to previous diagnostic"})
  vim.keymap.set("n", "<leader>vca", vim.lsp.buf.code_action, {buffer = bufnr, remap = false, desc = "Displays code actions using LSP"})
  vim.keymap.set("n", "<leader>vrr", vim.lsp.buf.references, {buffer = bufnr, remap = false, desc = "Shows references using LSP"})
  vim.keymap.set("n", "<leader>vrn", vim.lsp.buf.rename, {buffer = bufnr, remap = false, desc = "Renames symbol using LSP"})
  vim.keymap.set('n', '<leader>wa', vim.lsp.buf.add_workspace_folder, {buffer = bufnr, remap = false, desc = "Adds folder to LSP workspace"})
  vim.keymap.set('n', '<leader>wr', vim.lsp.buf.remove_workspace_folder, {buffer = bufnr, remap = false, desc = "Removes folder from LSP workspace"})
  vim.keymap.set('n', '<leader>wl', function()
    print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
  end, {buffer = bufnr, remap = false, desc = "Lists all LSP workspace folders"})
  vim.keymap.set("n", "<C-h>", vim.lsp.buf.signature_help, {buffer = bufnr, remap = false, desc = "Displays signature help using LSP"})
  vim.keymap.set('n', 'so', require('telescope.builtin').lsp_references, {buffer = bufnr, remap = false, desc = "Shows LSP references using Telescope"})
end)


-- = util.root_pattern("angular.json","decorate-angular-cli.js")


require 'lspconfig'.angularls.setup {
  root_dir = util.root_pattern("angular.json", "project.json", 'nx.json'),
  filetypes = { 'typescript', 'html', 'typescriptreact', 'typescript.tsx', 'angular.html' }
}

require 'lspconfig'.tsserver.setup({})
vim.lsp.handlers["textDocument/publishDiagnostics"] = vim.lsp.with(
  vim.lsp.diagnostic.on_publish_diagnostics,
  {
    virtual_text = true,
  }
)

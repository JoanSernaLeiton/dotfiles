local wk = require("which-key")

require('Comment').setup({
  -- Performance optimization - reduce pre-hook overhead
  pre_hook = function(ctx)
    -- Only execute this hook when necessary (for special files)
    local filetype = vim.bo.filetype

    -- Special handling for multi-language files
    if vim.tbl_contains({ 'html', 'vue', 'tsx', 'jsx', 'svelte', 'php' }, filetype) then
      local ok, ts_comment = pcall(require, 'ts_context_commentstring.integrations.comment_nvim')
      if ok then
        return ts_comment.create_pre_hook()(ctx)
      end
    end

    -- Special handling for .env files and configs (# comments)
    if vim.tbl_contains({ 'env', 'dockerfile', 'yaml', 'toml' }, filetype) then
      return '#%s'
    end

    -- For other files, use default behavior
    return nil
  end,

  -- Faster post-hook
  post_hook = function(ctx)
    -- Only execute for LSP-capable files
    if vim.tbl_contains({ 'typescript', 'javascript', 'lua', 'go', 'rust', 'php' }, vim.bo.filetype) then
      -- Refresh LSP diagnostics after commenting
      vim.schedule(function()
        vim.diagnostic.hide()
        vim.diagnostic.show()
      end)
    end
  end,

  -- Optimize padding behavior
  padding = true,

  -- Keep cursor position for better workflow
  sticky = true,

  -- Ignore empty lines to improve UX
  ignore = '^$',

  -- Optimized mappings
  toggler = {
    line = 'gcc',
    block = 'gbc'
  },

  opleader = {
    line = 'gc',
    block = 'gb'
  },

  -- Additional mappings with descriptive names
  extra = {
    above = 'gcO',
    below = 'gco',
    eol = 'gcA'
  },

  -- Enable all mappings
  mappings = {
    basic = true,
    extra = true
  }
})

-- Register WhichKey keybindings with better descriptions and organization
wk.register({
  ["gcc"] = { "Comment toggle current line", mode = "n" },
  ["gbc"] = { "Comment toggle current block", mode = "n" },
  ["gc"] = { "Comment toggle selection", mode = { "n", "o" } },
  ["gb"] = { "Block comment toggle selection", mode = { "n", "o" } },

  -- Visual mode mappings
  ["gc"] = { "Comment toggle selection", mode = "v" },
  ["gb"] = { "Block comment toggle selection", mode = "v" },

  -- Extra mappings with smart descriptions
  ["gco"] = { "Comment insert below", mode = "n" },
  ["gcO"] = { "Comment insert above", mode = "n" },
  ["gcA"] = { "Comment insert end of line", mode = "n" },

  -- Add leader prefix mappings for semantic organization
  ["<leader>c"] = {
    name = "Comments",
    c = { "<cmd>lua require('Comment.api').toggle.linewise.current()<CR>", "Toggle comment current line" },
    v = { "<cmd>lua require('Comment.api').toggle.blockwise.current()<CR>", "Toggle block comment" },

    -- Line operations
    l = {
      name = "Line comments",
      j = { "<cmd>lua require('Comment.api').toggle.linewise.count(vim.v.count1)<CR>", "Toggle comment next N lines" },
      a = { "<cmd>lua require('Comment.api').insert.linewise.eol()<CR>", "Add comment at line end" },
      o = { "<cmd>lua require('Comment.api').insert.linewise.below()<CR>", "Add comment below" },
      O = { "<cmd>lua require('Comment.api').insert.linewise.above()<CR>", "Add comment above" },
    },

    -- Block operations
    b = {
      name = "Block comments",
      j = { "<cmd>lua require('Comment.api').toggle.blockwise.count(vim.v.count1)<CR>", "Toggle block comment next N lines" },
      a = { "<cmd>lua require('Comment.api').insert.blockwise.eol()<CR>", "Add block comment at line end" },
      o = { "<cmd>lua require('Comment.api').insert.blockwise.below()<CR>", "Add block comment below" },
      O = { "<cmd>lua require('Comment.api').insert.blockwise.above()<CR>", "Add block comment above" },
    }
  }
})

-- Add visual mode which-key mappings specifically
wk.register({
  ["<leader>c"] = {
    name = "Comments",
    c = { "<ESC><cmd>lua require('Comment.api').toggle.linewise(vim.fn.visualmode())<CR>", "Toggle comment region" },
    b = { "<ESC><cmd>lua require('Comment.api').toggle.blockwise(vim.fn.visualmode())<CR>", "Toggle block comment region" },
  }
}, { mode = "v" })

-- Optimize for common IDE-like shortcuts
vim.keymap.set('n', '<C-_>', '<cmd>lua require("Comment.api").toggle.linewise.current()<CR>',
  { silent = true, desc = "Toggle comment" })                                                                                                                       -- Ctrl+/
vim.keymap.set('v', '<C-_>', '<ESC><cmd>lua require("Comment.api").toggle.linewise(vim.fn.visualmode())<CR>',
  { silent = true, desc = "Toggle comment selection" })                                                                                                             -- Ctrl+/

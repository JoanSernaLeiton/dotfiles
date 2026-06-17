require('nvim-treesitter').install({
  "javascript", "typescript",
  "python",
  "html", "css", "scss",
  "go", "gomod", "gowork",
  "lua",
})

vim.api.nvim_create_autocmd('FileType', {
  pattern = {
    'javascript', 'typescript',
    'python',
    'html', 'css', 'scss',
    'go', 'gomod', 'gowork',
    'lua',
  },
  callback = function() vim.treesitter.start() end,
})

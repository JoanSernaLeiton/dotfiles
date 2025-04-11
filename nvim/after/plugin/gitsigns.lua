-- Gitsigns configuration
-- Optimized for performance and UI integration

-- Load common git config
local git_config = require('joanserna.git_config')

require('gitsigns').setup({
  signs = {
    add = { text = '┃' },
    change = { text = '┃' },
    delete = { text = '_' },
    topdelete = { text = '‾' },
    changedelete = { text = '~' },
    untracked = { text = '┆' },
  },

  signs_staged = {
    add = { text = '┃' },
    change = { text = '┃' },
    delete = { text = '_' },
    topdelete = { text = '‾' },
    changedelete = { text = '~' },
    untracked = { text = '┆' },
  },

  -- Performance settings
  signs_staged_enable = true,
  signcolumn = true,
  numhl = true,
  linehl = false,
  word_diff = false,
  watch_gitdir = {
    follow_files = true,
    interval = 1000,
  },
  attach_to_untracked = true,

  -- Blame visualization
  current_line_blame = true,
  current_line_blame_opts = {
    virt_text = true,
    virt_text_pos = 'eol',
    delay = 300, -- Reduced from 1000 for better responsiveness
    ignore_whitespace = false,
    virt_text_priority = 100,
  },
  current_line_blame_formatter = '<author>, <author_time:%Y-%m-%d> - <summary>',

  -- System settings
  sign_priority = 6,
  update_debounce = 100,
  max_file_length = 8000, -- Increased for better handling of large files

  -- Preview configuration
  preview_config = {
    border = 'rounded',
    style = 'minimal',
    relative = 'cursor',
    row = 0,
    col = 1,
  },

  -- Auto-navigation on hunk operations
  on_attach = function(bufnr)
    -- Don't override keys set in the common Git config
  end,
})

-- Return the module
return {
  -- Add any Gitsigns-specific functions here that other plugins might need
  enhance_blame_line = function()
    require('gitsigns').blame_line({ full = true })
  end
}

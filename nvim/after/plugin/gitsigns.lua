require('gitsigns').setup {
    signcolumn = true,  -- Toggle with `:Gitsigns toggle_signs`
    numhl      = true, -- Toggle with `:Gitsigns toggle_numhl`
    linehl     = false, -- Toggle with `:Gitsigns toggle_linehl`
    word_diff  = false, -- Toggle with `:Gitsigns toggle_word_diff`
    watch_gitdir = {
      interval = 1000,
      follow_files = true
    },
    attach_to_untracked = true,
    current_line_blame = true, -- Toggle with `:Gitsigns toggle_current_line_blame`
    current_line_blame_opts = {
      virt_text = true,
      virt_text_pos = 'eol', -- 'eol' | 'overlay' | 'right_align'
      delay = 1000,
      ignore_whitespace = false,
    },
    current_line_blame_formatter = '<author>, <author_time:%Y-%m-%d> - <summary>',
    sign_priority = 6,
    update_debounce = 100,
    status_formatter = nil, -- Use default
    max_file_length = 5000, -- Disable if file is longer than this (in lines)
    preview_config = {
      -- Options passed to nvim_open_win
      border = 'single',
      style = 'minimal',
      relative = 'cursor',
      row = 0,
      col = 1
    }
  }
local gitsigns = require('gitsigns')
local function map(mode, l, r, opts)
  opts = opts or {}
  opts.buffer = bufnr
  vim.keymap.set(mode, l, r, opts)
end
require('gitsigns').setup{
    -- Navigation
    map('n', ']c', function()
      if vim.wo.diff then
        vim.cmd.normal({']c', bang = true})
      else
        gitsigns.nav_hunk('next')
      end
    end, {desc = "Moves to next hunk."}),

    map('n', '[c', function()
      if vim.wo.diff then
        vim.cmd.normal({'[c', bang = true})
      else
        gitsigns.nav_hunk('prev')
      end
    end, {desc = "Moves to previous hunk."}),

    -- Actions
    map('n', '<leader>gs', gitsigns.stage_hunk, { desc = "Stage changes in current hunk" }),
    map('n', '<leader>gr', gitsigns.reset_hunk, { desc = "Reset changes in current hunk" }),
    map('v', '<leader>gs', function() gitsigns.stage_hunk { vim.fn.line("."), vim.fn.line("v") } end, { desc = "Stage selected changes" }),
    map('v', '<leader>gr', function() gitsigns.reset_hunk { vim.fn.line("."), vim.fn.line("v") } end, { desc = "Reset selected changes" }),
    map('n', '<leader>gS', gitsigns.stage_buffer, { desc = "Stage all changes in buffer" }),
    map('n', '<leader>gu', gitsigns.undo_stage_hunk, { desc = "Unstage last staged hunk" }),
    map('n', '<leader>gR', gitsigns.reset_buffer, { desc = "Reset all changes in buffer" }),
    map('n', '<leader>gp', gitsigns.preview_hunk, { desc = "Preview current hunk" }),
    map('n', '<leader>gj', gitsigns.next_hunk, { desc = "Jump to next hunk" }),
    map('n', '<leader>gk', gitsigns.prev_hunk, { desc = "Jump to previous hunk" }),
    map('n', '<leader>gb', function() gitsigns.blame_line { full = true } end, { desc = "Show detailed blame for line" }),
    map('n', '<leader>gB', gitsigns.toggle_current_line_blame, { desc = "Toggle blame for current line" }),
    map('n', '<leader>gd', gitsigns.diffthis, { desc = "Show diff for current buffer" }),
    map('n', '<leader>gD', function() gitsigns.diffthis("~") end, { desc = "Show diff with HEAD" }),
    map('n', '<leader>gt', gitsigns.toggle_deleted, { desc = "Toggle deleted lines visibility" }),

    -- Text object
    map({ 'o', 'x' }, 'ih', ':<C-U>Gitsigns select_hunk<CR>', { desc = "Select current hunk" })
}

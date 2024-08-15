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
    map('n', '<leader>hs', gitsigns.stage_hunk, {desc = "Stages partial changes in Git."}),
    map('n', '<leader>hr', gitsigns.reset_hunk, {desc = "Reverts partial changes in Git."}),
    map('v', '<leader>hs', function() gitsigns.stage_hunk {vim.fn.line('.'), vim.fn.line('v')} end, {desc = "Stages selected changes in Git"}),
    map('v', '<leader>hr', function() gitsigns.reset_hunk {vim.fn.line('.'), vim.fn.line('v')} end, {desc = "Reverts selected changes in Git"}),
    map('n', '<leader>hS', gitsigns.stage_buffer, {desc = "Stages all changes in buffer."}),
    map('n', '<leader>hu', gitsigns.undo_stage_hunk, {desc = "Unstages previously staged hunk."}),
    map('n', '<leader>hR', gitsigns.reset_buffer, {desc = "Reverts all changes in buffer"}),
    map('n', '<leader>hp', gitsigns.preview_hunk, {desc = "Previews changes in hunk."}),
    map('n', '<leader>hn', gitsigns.next_hunk, {desc = "Next changes in hunk."}),
    map('n', '<leader>hb', function() gitsigns.blame_line{full=true} end, {desc = "Shows detailed blame for line."}),
    map('n', '<leader>tb', gitsigns.toggle_current_line_blame, {desc = "Toggles blame display for current line."}),
    map('n', '<leader>hd', gitsigns.diffthis, {desc = "Shows diff for current buffer."}),
    map('n', '<leader>hD', function() gitsigns.diffthis('~') end, {desc = "Shows diff between current and HEAD."}),
    map('n', '<leader>td', gitsigns.toggle_deleted, {desc = "Toggles visibility of deleted lines."}),

    -- Text object
    map({'o', 'x'}, 'ih', ':<C-U>Gitsigns select_hunk<CR>', {desc = "Selects current hunk in modes"})
}

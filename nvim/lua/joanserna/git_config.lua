-- In /lua/joanserna/git_config.lua

local wk = require("which-key")
local M = {}

-- Set up colors for consistent UI
vim.api.nvim_command('highlight GitSignsAdd guifg=#98c379 guibg=NONE')
vim.api.nvim_command('highlight GitSignsChange guifg=#e5c07b guibg=NONE')
vim.api.nvim_command('highlight GitSignsDelete guifg=#e06c75 guibg=NONE')

M.setup_keymaps = function()
  wk.register({
    g = {
      name = "Git",
      s = { "<cmd>Git<CR>", "Status (Fugitive)" },
      V = { name = "View/Diff" },
      x = { name = "Conflicts" },
      t = { name = "Toggle" },
      j = { function() require('gitsigns').nav_hunk('next') end, "Next Hunk" },
      k = { function() require('gitsigns').nav_hunk('prev') end, "Previous Hunk" },
      v = { function() require('gitsigns').preview_hunk() end, "Preview Hunk" },
      r = { function() require('gitsigns').reset_hunk() end, "Reset Hunk" },
      S = { function() require('gitsigns').stage_hunk() end, "Stage Hunk" },
      u = { function() require('gitsigns').undo_stage_hunk() end, "Undo Stage Hunk" },
      R = { function() require('gitsigns').reset_buffer() end, "Reset Buffer" },
      b = { function() require('gitsigns').blame_line({ full = true }) end, "Blame Line" },
      B = { function() require('gitsigns').toggle_current_line_blame() end, "Toggle Blame" },
      m = { "<cmd>Git commit<CR>", "Make Commit" },
      l = { "<cmd>LazyGit<CR>", "LazyGit" },
      a = { function() require('gitsigns').stage_buffer() end, "Stage All" },
      P = { "<cmd>Git push<CR>", "Push" },
      f = { "<cmd>Git pull<CR>", "Pull" },
    }
  }, { prefix = "<leader>" })

  wk.register({
    V = {
      name = "View/Diff",
      v = { "<cmd>DiffviewOpen<CR>", "Open Diffview" },
      c = { "<cmd>DiffviewClose<CR>", "Close Diffview" },
      f = { "<cmd>DiffviewFileHistory %<CR>", "File History (current)" },
      p = { "<cmd>DiffviewFileHistory<CR>", "Project History" },
      r = { "<cmd>DiffviewRefresh<CR>", "Refresh Diff" },
      h = { "<cmd>Gitsigns diffthis<CR>", "Diff This (Gitsigns)" },
      H = { function() require('gitsigns').diffthis("~") end, "Diff with HEAD" },
    }
  }, { prefix = "<leader>g" })

  vim.keymap.set('n', ']h', function()
    if vim.wo.diff then
      vim.cmd.normal({ ']c', bang = true })
    else
      require('gitsigns').nav_hunk('next')
    end
  end, { desc = "Next hunk" })

  vim.keymap.set('n', '[h', function()
    if vim.wo.diff then
      vim.cmd.normal({ '[c', bang = true })
    else
      require('gitsigns').nav_hunk('prev')
    end
  end, { desc = "Previous hunk" })
end

M.setup = function()
  M.setup_keymaps()
  return M
end

return M

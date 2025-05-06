-- In /lua/joanserna/git_config.lua

local wk = require("which-key")
local M = {}
local builtin = require('telescope.builtin')

-- Set up colors for consistent UI
vim.api.nvim_command('highlight GitSignsAdd guifg=#98c379 guibg=NONE')
vim.api.nvim_command('highlight GitSignsChange guifg=#e5c07b guibg=NONE')
vim.api.nvim_command('highlight GitSignsDelete guifg=#e06c75 guibg=NONE')

-- In gitconfig.lua
M.setup_keymaps = function()
  -- Main git commands
  wk.register({
    g = {
      name = "Git",
      -- Status commands
      s = { "<cmd>Git<CR>", "Status (Fugitive)" },
      S = { builtin.git_status, "Telescope Status" }, -- Was <leader>gs in telescope.lua

      -- Navigation
      j = { function() require('gitsigns').nav_hunk('next') end, "Next Hunk" },
      k = { function() require('gitsigns').nav_hunk('prev') end, "Previous Hunk" },

      -- Viewing changes
      v = { function() require('gitsigns').preview_hunk() end, "Preview Hunk" },

      -- History commands
      h = { name = "History" },

      -- Branch operations
      b = { builtin.git_branches, "Branches" }, -- Was <leader>gb in telescope.lua

      -- Staging and committing
      a = { function() require('gitsigns').stage_buffer() end, "Stage All" },
      r = { function() require('gitsigns').reset_hunk() end, "Reset Hunk" },
      R = { function() require('gitsigns').reset_buffer() end, "Reset Buffer" },
      u = { function() require('gitsigns').undo_stage_hunk() end, "Undo Stage Hunk" },
      m = { "<cmd>Git commit<CR>", "Make Commit" },

      -- Sync operations
      P = { "<cmd>Git push<CR>", "Push" },
      f = { "<cmd>Git pull<CR>", "Pull" },

      -- Blame operations
      B = { name = "Blame" },

      -- Tools and views
      l = { "<cmd>LazyGit<CR>", "LazyGit" },
      V = { name = "View/Diff" },
      x = { name = "Conflicts" },
      t = { builtin.git_stash, "Stash" },     -- Was <leader>gt in telescope.lua
      c = { builtin.git_commits, "Commits" }, -- Was <leader>gc in telescope.lua
    }
  }, { prefix = "<leader>" })

  -- View/Diff submenu
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

  -- History submenu (new)
  wk.register({
    h = {
      name = "History",
      c = { builtin.git_commits, "Commit History" },
      f = { "<cmd>DiffviewFileHistory %<CR>", "File History" },
      p = { "<cmd>DiffviewFileHistory<CR>", "Project History" },
    }
  }, { prefix = "<leader>g" })

  -- Blame submenu (restructured)
  wk.register({
    B = {
      name = "Blame",
      b = { function() require('gitsigns').blame_line({ full = true }) end, "Blame Line" },
      t = { function() require('gitsigns').toggle_current_line_blame() end, "Toggle Blame" },
    }
  }, { prefix = "<leader>g" })

  -- Keep bracket navigation for hunks (these are common in plugins and won't conflict)
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

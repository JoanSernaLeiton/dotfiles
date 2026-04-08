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
  -- Main git commands using new flat-list format
  wk.add({
    -- Git group
    { "<leader>g", group = "Git" },
    
    -- Status commands
    { "<leader>gs", "<cmd>Git<CR>", desc = "Status (Fugitive)" },
    { "<leader>gS", builtin.git_status, desc = "Telescope Status" },

    -- Navigation
    { "<leader>gj", function() require('gitsigns').nav_hunk('next') end, desc = "Next Hunk" },
    { "<leader>gk", function() require('gitsigns').nav_hunk('prev') end, desc = "Previous Hunk" },

    -- Viewing changes
    { "<leader>gv", function() require('gitsigns').preview_hunk() end, desc = "Preview Hunk" },

    -- Branch operations
    { "<leader>gb", builtin.git_branches, desc = "Branches" },

    -- Staging and committing
    { "<leader>ga", function() require('gitsigns').stage_buffer() end, desc = "Stage All" },
    { "<leader>gr", function() require('gitsigns').reset_hunk() end, desc = "Reset Hunk" },
    { "<leader>gR", function() require('gitsigns').reset_buffer() end, desc = "Reset Buffer" },
    { "<leader>gu", function() require('gitsigns').undo_stage_hunk() end, desc = "Undo Stage Hunk" },
    { "<leader>gm", "<cmd>Git commit<CR>", desc = "Make Commit" },

    -- Sync operations
    { "<leader>gP", "<cmd>Git push<CR>", desc = "Push" },
    { "<leader>gf", "<cmd>Git pull<CR>", desc = "Pull" },

    -- LazyGit
    { "<leader>gl", "<cmd>LazyGit<CR>", desc = "LazyGit" },

    -- Stash
    { "<leader>gt", builtin.git_stash, desc = "Stash" },

    -- Commits
    { "<leader>gc", builtin.git_commits, desc = "Commits" },

    -- History group
    { "<leader>gh", group = "History" },
    { "<leader>ghc", builtin.git_commits, desc = "Commit History" },
    { "<leader>ghf", "<cmd>DiffviewFileHistory %<CR>", desc = "File History" },
    { "<leader>ghp", "<cmd>DiffviewFileHistory<CR>", desc = "Project History" },

    -- Blame group
    { "<leader>gB", group = "Blame" },
    { "<leader>gBb", function() require('gitsigns').blame_line({ full = true }) end, desc = "Blame Line" },
    { "<leader>gBt", function() require('gitsigns').toggle_current_line_blame() end, desc = "Toggle Blame" },

    -- View/Diff group
    { "<leader>gV", group = "View/Diff" },
    { "<leader>gVv", "<cmd>DiffviewOpen<CR>", desc = "Open Diffview" },
    { "<leader>gVc", "<cmd>DiffviewClose<CR>", desc = "Close Diffview" },
    { "<leader>gVf", "<cmd>DiffviewFileHistory %<CR>", desc = "File History (current)" },
    { "<leader>gVp", "<cmd>DiffviewFileHistory<CR>", desc = "Project History" },
    { "<leader>gVr", "<cmd>DiffviewRefresh<CR>", desc = "Refresh Diff" },
    { "<leader>gVh", "<cmd>Gitsigns diffthis<CR>", desc = "Diff This (Gitsigns)" },
    { "<leader>gVH", function() require('gitsigns').diffthis("~") end, desc = "Diff with HEAD" },
  })

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

-- Fugitive configuration
-- Optimized for performance and integration with other git plugins

-- Load common git config
local git_config = require('joanserna.git_config')
local wk = require('which-key')

-- Basic fugitive setup
vim.keymap.set("n", "<leader>gs", vim.cmd.Git, { desc = "Git status (Fugitive)" })

-- Enhanced fugitive commands with better descriptions
local function setup_fugitive_commands()
  -- Register additional Fugitive-specific commands using new flat-list format
  wk.add({
    -- Commit workflow
    { "<leader>gca", "<cmd>Git commit --amend<CR>", desc = "Amend Commit" },
    { "<leader>gcv", "<cmd>Git commit --verbose<CR>", desc = "Verbose Commit" },

    -- Log commands
    { "<leader>gl", "<cmd>Git log<CR>", desc = "View Log" },
    { "<leader>glp", "<cmd>Git log -p<CR>", desc = "Log with Patches" },
    { "<leader>glg", "<cmd>Git log --graph --oneline<CR>", desc = "Graph Log" },

    -- Branch management
    { "<leader>gbc", "<cmd>Git checkout -b ", desc = "Create Branch" },
    { "<leader>gbs", "<cmd>Git checkout ", desc = "Switch Branch" },

    -- Remote operations
    { "<leader>gP", "<cmd>Git push -u origin HEAD<CR>", desc = "Push Upstream" },
    { "<leader>gF", "<cmd>Git fetch<CR>", desc = "Fetch" },

    -- Stash operations
    { "<leader>gz", "<cmd>Git stash<CR>", desc = "Stash" },
    { "<leader>gzp", "<cmd>Git stash pop<CR>", desc = "Stash Pop" },
    { "<leader>gza", "<cmd>Git stash apply<CR>", desc = "Stash Apply" },
    { "<leader>gzl", "<cmd>Git stash list<CR>", desc = "Stash List" },

    -- Blame
    { "<leader>gB", "<cmd>Git blame<CR>", desc = "Blame" },

    -- Misc
    { "<leader>gm", "<cmd>Git merge<CR>", desc = "Merge" },
    { "<leader>gw", "<cmd>Gwrite<CR>", desc = "Write & Stage" },
    { "<leader>gd", "<cmd>Gdiffsplit<CR>", desc = "Diff Split" },
  })
end

-- Set up autocmds for fugitive buffers
local function setup_fugitive_autocmds()
  local group = vim.api.nvim_create_augroup("FugitiveConfig", { clear = true })

  -- Better navigation in fugitive status buffer
  vim.api.nvim_create_autocmd("FileType", {
    group = group,
    pattern = "fugitive",
    callback = function()
      -- Make navigation more intuitive in fugitive windows
      vim.keymap.set("n", "q", "<cmd>close<CR>", { buffer = true, desc = "Close fugitive window" })

      -- Status buffer key mappings for common actions
      vim.keymap.set("n", "cc", "<cmd>Git commit<CR>", { buffer = true, desc = "Create commit" })
      vim.keymap.set("n", "ca", "<cmd>Git commit --amend<CR>", { buffer = true, desc = "Amend commit" })
      vim.keymap.set("n", "p", "<cmd>Git pull<CR>", { buffer = true, desc = "Pull" })
      vim.keymap.set("n", "P", "<cmd>Git push<CR>", { buffer = true, desc = "Push" })

      -- Navigation
      vim.keymap.set("n", "<Tab>", "=", { buffer = true, remap = true, desc = "Toggle diff" })

      -- Visual improvements
      vim.opt_local.number = false
      vim.opt_local.relativenumber = false
      vim.opt_local.signcolumn = "no"
      vim.opt_local.cursorline = true
    end
  })

  -- Commit buffer enhancements
  vim.api.nvim_create_autocmd("FileType", {
    group = group,
    pattern = "gitcommit",
    callback = function()
      -- Set textwidth for proper commit message formatting
      vim.opt_local.textwidth = 72
      vim.opt_local.colorcolumn = "51,73"
      vim.opt_local.spell = true

      -- Quick mappings for commit buffer
      vim.keymap.set("n", "<leader>wq", "<cmd>wq<CR>", { buffer = true, desc = "Save and quit" })
      vim.keymap.set("n", "<leader>cq", "<cmd>cq<CR>", { buffer = true, desc = "Abort commit" })
    end
  })
end

-- Initialize everything
local function init()
  setup_fugitive_commands()
  setup_fugitive_autocmds()
end

init()

-- Return the module
return {
  -- Expose any functions that might be needed by other plugins
  open_status = function()
    vim.cmd.Git()
  end,

  -- Add functions to run git commands in a more controlled way
  commit = function(args)
    vim.cmd("Git commit " .. (args or ""))
  end,

  push = function(args)
    vim.cmd("Git push " .. (args or ""))
  end,

  pull = function(args)
    vim.cmd("Git pull " .. (args or ""))
  end
}

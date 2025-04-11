-- Fugitive configuration
-- Optimized for performance and integration with other git plugins

-- Load common git config
local git_config = require('joanserna.git_config')
local wk = require('which-key')

-- Basic fugitive setup
vim.keymap.set("n", "<leader>gs", vim.cmd.Git, { desc = "Git status (Fugitive)" })

-- Enhanced fugitive commands with better descriptions
local function setup_fugitive_commands()
  -- Register additional Fugitive-specific commands
  wk.register({
    g = {
      name = "Git",
      -- Commit workflow
      c = {
        name = "Commit",
        c = { "<cmd>Git commit<CR>", "Create commit" },
        a = { "<cmd>Git commit --amend<CR>", "Amend commit" },
        v = { "<cmd>Git commit --verbose<CR>", "Commit verbose" },
      },

      -- Log commands
      l = {
        name = "Log",
        l = { "<cmd>Git log<CR>", "View log" },
        p = { "<cmd>Git log -p<CR>", "View log with patches" },
        g = { "<cmd>Git log --graph --oneline<CR>", "View graph log" },
      },

      -- Branch management
      b = {
        name = "Branch",
        l = { "<cmd>Git branch<CR>", "List branches" },
        c = { "<cmd>Git checkout -b ", "Create branch" },
        s = { "<cmd>Git checkout ", "Switch branch" },
      },

      -- Remote operations
      r = {
        name = "Remote",
        p = { "<cmd>Git push<CR>", "Push" },
        P = { "<cmd>Git push -u origin HEAD<CR>", "Push set upstream" },
        f = { "<cmd>Git pull<CR>", "Pull" },
        F = { "<cmd>Git fetch<CR>", "Fetch" },
      },

      -- Stash operations
      z = {
        name = "Stash",
        s = { "<cmd>Git stash<CR>", "Stash changes" },
        p = { "<cmd>Git stash pop<CR>", "Pop stash" },
        a = { "<cmd>Git stash apply<CR>", "Apply stash" },
        l = { "<cmd>Git stash list<CR>", "List stashes" },
      },

      -- Blame (complementing gitsigns blame)
      B = { "<cmd>Git blame<CR>", "Blame (Fugitive)" },

      -- Misc
      m = { "<cmd>Git merge<CR>", "Merge" },
      w = { "<cmd>Gwrite<CR>", "Write & stage file" },
      d = { "<cmd>Gdiffsplit<CR>", "Diff split" },
    }
  }, { prefix = "<leader>f" }) -- Using f-prefix to avoid conflicts
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

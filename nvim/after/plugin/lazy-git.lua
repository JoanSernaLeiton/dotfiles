-- LazyGit configuration
-- Optimized for performance and UI integration

-- Load common git config
local git_config = require('joanserna.git_config')
local wk = require('which-key')

-- Set up LazyGit with performance optimizations
local function setup()
  -- Configure lazygit options
  vim.g.lazygit_floating_window_winblend = 0 -- Better visibility
  vim.g.lazygit_floating_window_scaling_factor = 0.9 -- Almost full screen

  vim.g.lazygit_use_neovim_remote = 0 -- Better performance without nvr

  -- Configure floating window border style for consistency with other plugins
  vim.g.lazygit_floating_window_border_chars = {
    '╭', '─', '╮', '│', '╯', '─', '╰', '│'
  }

  -- Register additional keymaps specifically for LazyGit integration
  wk.add({
    { "<leader>g", group = "Git" },
    { "<leader>gL", group = "LazyGit" },
    { "<leader>gLl", "<cmd>LazyGit<CR>", desc = "Open LazyGit" },
    { "<leader>gLc", "<cmd>LazyGitConfig<CR>", desc = "LazyGit Config" },
    { "<leader>gLf", "<cmd>LazyGitFilter<CR>", desc = "LazyGit Filter" },
    { "<leader>gLb", "<cmd>LazyGitFilterCurrentFile<CR>", desc = "LazyGit Current File" },
  })

  -- Quick access keybinding
end

-- Set up autocommands for LazyGit integration
local function setup_autocmds()
  local augroup = vim.api.nvim_create_augroup("LazyGitConfig", { clear = true })

  -- Update git signs after lazygit operation
  vim.api.nvim_create_autocmd("User", {
    group = augroup,
    pattern = "LazyGitExitPre",
    callback = function()
      -- Refresh gitsigns
      if package.loaded["gitsigns"] then
        require("gitsigns").refresh()
      end

      -- Refresh buffers
      vim.cmd("checktime")
    end
  })
end

-- Initialize
setup()
setup_autocmds()

-- Return the module
return {
  -- Expose functions that might be useful for other plugins
  open = function()
    vim.cmd("LazyGit")
  end,

  open_file_history = function()
    vim.cmd("LazyGitFilterCurrentFile")
  end
}

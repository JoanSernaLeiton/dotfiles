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
  vim.g.lazygit_floating_window_corner_chars = { '╭', '╮', '╰', '╯' } -- Nicer corners
  vim.g.lazygit_use_neovim_remote = 0 -- Better performance without nvr

  -- Configure floating window border style for consistency with other plugins
  vim.g.lazygit_floating_window_border_chars = {
    '╭', '─', '╮', '│', '╯', '─', '╰', '│'
  }

  -- Register additional keymaps specifically for LazyGit integration
  wk.register({
    g = {
      name = "Git",
      -- LazyGit commands
      L = {
        name = "LazyGit",
        l = { "<cmd>LazyGit<CR>", "Open LazyGit" },
        c = { "<cmd>LazyGitConfig<CR>", "LazyGit Config" },
        f = { "<cmd>LazyGitFilter<CR>", "LazyGit Filter" },
        b = { function()
          -- Get current file path relative to git root
          local file = vim.fn.expand('%:p')
          vim.cmd('LazyGitFilter ' .. file)
        end, "LazyGit Current File" },
      },
    },
  }, { prefix = "<leader>" })

  -- Quick access keybinding
  vim.keymap.set('n', '<leader>lg', '<cmd>LazyGit<CR>', { desc = "Open LazyGit" })
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

  open_file_history = function(file)
    if file then
      vim.cmd("LazyGitFilter " .. file)
    else
      -- Current file
      local current_file = vim.fn.expand('%:p')
      vim.cmd("LazyGitFilter " .. current_file)
    end
  end
}

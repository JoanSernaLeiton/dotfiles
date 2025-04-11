-- Diffview configuration
-- Optimized for better performance and UI integration

-- Load common git config
local git_config = require('joanserna.git_config')
local actions = require("diffview.actions")

require("diffview").setup({
  -- Performance optimizations
  git_cmd = { "git" },
  use_icons = true,

  -- UI settings
  show_help_hints = true,
  enhanced_diff_hl = true, -- Better diff highlighting

  -- File panel configuration
  file_panel = {
    listing_style = "tree", -- More compact file display
    win_config = {          -- Configured for better visibility
      width = 35,
      position = "left",
    },
    tree_options = { -- Optimize tree view
      flatten_dirs = true,
      folder_statuses = "only_folded",
    },
  },

  -- File history panel configuration
  file_history_panel = {
    win_config = {
      width = 35,
      position = "left",
    },
    log_options = {
      git = {
        single_file = {
          max_count = 256,
          follow = true,
        },
        multi_file = {
          max_count = 128,
        },
      },
    },
  },

  -- Advanced merge tool settings
  merge_tool = {
    layout = "diff3_mixed", -- More intuitive layout for conflict resolution
    disable_diagnostics = true,
    winbar_info = true,
  },

  -- Hooks
  hooks = {
    diff_buf_read = function(bufnr)
      -- Apply better performance settings for diff buffers
      vim.opt_local.foldenable = false
      vim.opt_local.wrap = false
      vim.opt_local.list = false

      -- Integrate with LSP if available (minimally)
      if vim.lsp.buf_is_attached(bufnr) then
        -- Disable some heavy LSP features in diff views
        local client_ids = vim.lsp.get_active_clients({ bufnr = bufnr })
        for _, client_id in ipairs(client_ids) do
          local client = vim.lsp.get_client_by_id(client_id)
          if client then
            client.server_capabilities.semanticTokensProvider = nil
          end
        end
      end
    end,
  },

  -- Key mappings (minimal here, most defined in integrated-git-config.lua)
  keymaps = {
    disable_defaults = false,
    view = {
      -- Essential view mappings (others in the shared config)
      { "n", "q",          actions.close,             { desc = "Close" } },
      { "n", "<esc>",      actions.close,             { desc = "Close" } },
      { "n", "<tab>",      actions.select_next_entry, { desc = "Next file" } },
      { "n", "<s-tab>",    actions.select_prev_entry, { desc = "Previous file" } },

      -- Layout control
      { "n", "<leader>dl", actions.cycle_layout,      { desc = "Cycle layout" } },

      -- Navigation between conflict markers
      { "n", "]x",         actions.next_conflict,     { desc = "Next conflict" } },
      { "n", "[x",         actions.prev_conflict,     { desc = "Previous conflict" } },
    },
    file_panel = {
      -- File navigation
      { "n", "j",       actions.next_entry,         { desc = "Next entry" } },
      { "n", "k",       actions.prev_entry,         { desc = "Previous entry" } },
      { "n", "<cr>",    actions.select_entry,       { desc = "Open diff" } },
      { "n", "s",       actions.toggle_stage_entry, { desc = "Stage/unstage" } },

      -- Folds
      { "n", "za",      actions.toggle_fold,        { desc = "Toggle fold" } },
      { "n", "zo",      actions.open_fold,          { desc = "Open fold" } },
      { "n", "zc",      actions.close_fold,         { desc = "Close fold" } },

      -- Selection
      { "n", "<space>", actions.toggle_stage_entry, { desc = "Stage/unstage" } },
      { "n", "X",       actions.restore_entry,      { desc = "Restore entry" } },
    },
    file_history_panel = {
      -- History navigation
      { "n", "g!",   actions.options,      { desc = "Options" } },
      { "n", "y",    actions.copy_hash,    { desc = "Copy commit hash" } },
      { "n", "<cr>", actions.select_entry, { desc = "Open diff" } },
      { "n", "o",    actions.select_entry, { desc = "Open diff" } },
    },
    option_panel = {
      { "n", "<cr>",  actions.select_entry, { desc = "Change option" } },
      { "n", "<tab>", actions.select_entry, { desc = "Change option" } },
    },
  },
})

-- Return the module
return {
  -- Add any Diffview-specific functions here that other plugins might need
  open_file_history = function(file)
    local cmd = file and ("DiffviewFileHistory " .. file) or "DiffviewFileHistory"
    vim.cmd(cmd)
  end
}

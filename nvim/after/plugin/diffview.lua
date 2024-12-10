local actions = require("diffview.actions")
require("diffview").setup({
  git_cmd = { "git" },      -- The git executable followed by default args.
  use_icons = true,         -- Requires nvim-web-devicons
  show_help_hints = true,   -- Show hints for how to open the help panel
  watch_index = true,       -- Update views and index buffers when the git index changes.
  keymaps = {
    disable_defaults = false, -- Disable the default keymaps
    view = {
      -- The `view` bindings are active in the diff buffers, only when the current
      -- tabpage is a Diffview.
      { "n", "<leader>dvn", actions.select_next_entry, { desc = "Open the diff for the next file" } },
      { "n", "<leader>dvp", actions.select_prev_entry, { desc = "Open the diff for the previous file" } },
      { "n", "<leader>dvf", actions.goto_file_edit, { desc = "Open the file in the previous tabpage" } },
      { "n", "<leader>dvsv", actions.goto_file_split, { desc = "Open the file in a new vertical split" } },
      { "n", "<leader>dvst", actions.goto_file_tab, { desc = "Open the file in a new tabpage" } },
      { "n", "<leader>dvF", actions.focus_files, { desc = "Bring focus to the file panel" } },
      { "n", "<leader>dvT", actions.toggle_files, { desc = "Toggle the file panel" } },
      { "n", "<leader>dvl", actions.cycle_layout, { desc = "Cycle through available layouts" } },
      { "n", "<leader>dv[", actions.prev_conflict, { desc = "Jump to the previous conflict in merge-tool" } },
      { "n", "<leader>dv]", actions.next_conflict, { desc = "Jump to the next conflict in merge-tool" } },
      { "n", "<leader>dvco", actions.conflict_choose("ours"), { desc = "Choose the OURS version of a conflict" } },
      { "n", "<leader>dvct", actions.conflict_choose("theirs"), { desc = "Choose the THEIRS version of a conflict" } },
      { "n", "<leader>dvcb", actions.conflict_choose("base"), { desc = "Choose the BASE version of a conflict" } },
      { "n", "<leader>dvca", actions.conflict_choose("all"), { desc = "Choose all versions of a conflict" } },
      { "n", "<leader>dvx", actions.conflict_choose("none"), { desc = "Delete the conflict region" } },
      { "n", "<leader>dvCo", actions.conflict_choose_all("ours"), { desc = "Choose the OURS version for the entire file" } },
      { "n", "<leader>dvCt", actions.conflict_choose_all("theirs"), { desc = "Choose the THEIRS version for the entire file" } },
      { "n", "<leader>dvCb", actions.conflict_choose_all("base"), { desc = "Choose the BASE version for the entire file" } },
      { "n", "<leader>dvCa", actions.conflict_choose_all("all"), { desc = "Choose all versions for the entire file" } },
      { "n", "<leader>dvX", actions.conflict_choose_all("none"), { desc = "Delete all conflict regions for the entire file" } },
    },
  }
})


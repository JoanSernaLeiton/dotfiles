local builtin = require("telescope.builtin")
local telescope = require('telescope')
local lga_actions = require("telescope-live-grep-args.actions")
require('telescope').load_extension 'fzf'
telescope.setup {
  defaults = {
    file_ignore_patterns = { '.git/*', 'node_modules', 'env/*' },
    color_devicons = true,
    winblend = 20,
    wrap_results = true,
    sorting_strategy = "descending",
    mappings = {
      i = {
        ["<C-j>"] = "move_selection_next",
        ["<C-k>"] = "move_selection_previous",
        ["<C-u>"] = "preview_scrolling_up",
        ["<C-d>"] = "preview_scrolling_down",
        ["<esc>"] = "close",
      },
    },
  },
  pickers = {
    -- Make frequently used pickers faster with dropdown theme
    find_files = {
      theme = "dropdown",
      previewer = false,
    },
    buffers = {
      theme = "dropdown",
      previewer = false,
      sort_lastused = true,
    },
    -- Keep your existing LSP references config
    lsp_references = {
      -- theme = "dropdown",
      path_display = { "smart" },
      fname_width = 80,
      layout_config = {
        width = 0.95,
        horizontal = {
          preview_width = 0.3,
          results_width = 0.7,
        }
      },
      show_line = true,
    },
    -- Add configuration for git pickers
    git_status = {
      layout_strategy = "vertical",
      layout_config = {
        preview_height = 0.6,
      },
    },
  }
}
builtin.project_files = function()
  local opts = {
    show_untracked = true
  } -- Define here if you want to define something
  vim.fn.system("git rev-parse --is-inside-work-tree")
  if vim.v.shell_error == 0 then
    builtin.git_files(opts)
  else
    builtin.find_files(opts)
  end
end

vim.keymap.set("n", "<C-p>", builtin.project_files, { desc = "List project files using Telescope" })
vim.keymap.set("n", "<C-e>", builtin.oldfiles, { desc = "List recently opened files using Telescope" })
vim.keymap.set("n", "<leader>bb", function()
  require('telescope.builtin').buffers({
    sort_lastused = true,
    previewer = false,
    theme = "dropdown"
  })
end, { desc = "List buffers" })
vim.keymap.set("n", "<leader>tf", function() require('telescope.builtin').find_files { previewer = false } end,
  { desc = "Find files without preview" })
vim.keymap.set("n", "<leader>bf", function()
  require('telescope.builtin').current_buffer_fuzzy_find({
    previewer = false,
    theme = "dropdown"
  })
end, { desc = "Fuzzy find in buffer" })
vim.keymap.set("n", "<leader>tfw", function()
  require('telescope.builtin').grep_string({
    word_match = "-w",
    only_sort_text = true,
    layout_strategy = 'vertical',
    search = vim.fn.expand("<cword>")
  })
end, { desc = "Search word under cursor" })
vim.keymap.set("n", "<leader>/", function()
  require('telescope.builtin').current_buffer_fuzzy_find({
    previewer = true,
    theme = "dropdown"
  })
end, { desc = "Search in current buffer" })
vim.keymap.set("n", "<leader>th", function() require('telescope.builtin').help_tags() end, { desc = "List help tags" })
vim.keymap.set("n", "<leader>tt", function() require('telescope.builtin').tags() end, { desc = "List tags in project" })
vim.keymap.set("n", "<leader>ts", function() require('telescope.builtin').grep_string() end,
  { desc = "Search for string in files" })
vim.keymap.set("n", "<leader>tp", function() require('telescope.builtin').live_grep() end,
  { desc = "Search for text interactively" })
vim.keymap.set("n", "<leader>to", function() require('telescope.builtin').oldfiles() end,
  { desc = "List recently opened files" })
vim.keymap.set("n", "<leader>tg", function() require('telescope.builtin').git_status() end, { desc = "Show Git status" })
vim.keymap.set("n", "<leader>tc", function() require('telescope.builtin').git_commits() end,
  { desc = "Show Git commits" })
vim.keymap.set("n", "<leader>tm", function() require('telescope.builtin').mason() end,
  { desc = "Manage LSP servers and tools" })
vim.keymap.set("n", "<leader>td", function() require('telescope.builtin').diagnostics() end,
  { desc = "Show LSP diagnostics" })
vim.keymap.set("n", "<leader>tw", function() require('telescope.builtin').lsp_dynamic_workspace_symbols() end,
  { desc = "Find workspace symbols" })
vim.keymap.set("n", "<leader>th", function() require('telescope.builtin').command_history() end,
  { desc = "Browse command history" })
vim.keymap.set("n", "<leader>tr", function() require('telescope.builtin').registers() end, { desc = "Show registers" })
vim.keymap.set("n", "<leader>tb", function() require('telescope.builtin').buffers() end, { desc = "List open buffers" })
vim.keymap.set("n", "<leader>tc", function()
  require('telescope.builtin').git_commits({
    previewer = require('telescope.previewers').vim_buffer_cat.new,
    layout_strategy = 'vertical'
  })
end, { desc = "Search Git commits with preview" })
vim.keymap.set("n", "<C-f>", telescope.extensions.live_grep_args.live_grep_args,
  { noremap = true, desc = "Search with arguments using Live Grep" })


require('telescope').load_extension('fzf')

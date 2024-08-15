local builtin = require("telescope.builtin")
local telescope = require('telescope')
local lga_actions = require("telescope-live-grep-args.actions")
require('telescope').load_extension 'fzf'
telescope.setup {
	defaults = {
		layout_strategy = 'horizontal',
		layout_config = {
				vertical = { width = 0.95, anchor=2 }
		},
		file_ignore_patterns = { '.git/*', 'node_modules', 'env/*' },
		color_devicons = true,
		winblend = 20,
		wrap_results = true, 
	},

        extensions = {
          live_grep_args = {
            auto_quoting = true, -- enable/disable auto-quoting
            -- define mappings, e.g.
            mappings = { -- extend mappings
              i = {
                ["<C-k>"] = lga_actions.quote_prompt(),
                ["<C-i>"] = lga_actions.quote_prompt({ postfix = " --iglob " }),
              },
            },
            -- ... also accepts theme settings, for example:
            -- theme = "dropdown", -- use dropdown theme
            -- theme = { }, -- use own theme spec
            -- layout_config = { mirror=true }, -- mirror preview pane
          }
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

vim.keymap.set("n","<C-p>",builtin.project_files,{desc = "Lists project files using Telescope"})
vim.keymap.set("n","<C-e>",builtin.oldfiles,{desc = "Lists recently opened files using Telescope"})
vim.keymap.set('n', '<leader><space>', function() require('telescope.builtin').buffers { sort_lastused = true } end, {desc = "Lists open buffers sorted by last usage using Telescope"})
vim.keymap.set('n', '<leader>sf', function() require('telescope.builtin').find_files { previewer = false } end, {desc = "Finds files without preview using Telescope"})
vim.keymap.set('n', '<leader>sb', function() require('telescope.builtin').current_buffer_fuzzy_find() end, {desc = "Fuzzy finds text in current buffer using Telescope"})
vim.keymap.set('n', '<leader>sh', function() require('telescope.builtin').help_tags() end, {desc = "Lists help tags using Telescope"})
vim.keymap.set('n', '<leader>st', function() require('telescope.builtin').tags() end, {desc = "Lists tags in project using Telescope"})
vim.keymap.set('n', '<leader>sd', function() require('telescope.builtin').grep_string() end, {desc = "Searches for string in files using Telescope"})
vim.keymap.set('n', '<leader>sp', function() require('telescope.builtin').live_grep() end, {desc = "Searches for text interactively using Telescope"})
vim.keymap.set('n', '<leader>?', function() require('telescope.builtin').oldfiles() end, {desc = "Lists recently opened files using Telescope"})
vim.keymap.set('n', '<leader>gs', function() require('telescope.builtin').git_status() end, {desc = "Show Git status using Telescope"})
vim.keymap.set('n', '<leader>gc', function() require('telescope.builtin').git_commits() end, {desc = "Show Git commits using Telescope"})
vim.keymap.set('n', '<leader>m', function() require('telescope.builtin').mason() end, {desc = "Manage LSP servers, linters, etc. using Telescope"})
vim.keymap.set('n', '<leader>ld', function() require('telescope.builtin').diagnostics() end, {desc = "Show LSP diagnostics using Telescope"})
vim.keymap.set('n', '<leader>fs', function() require('telescope.builtin').lsp_dynamic_workspace_symbols() end, {desc = "Find symbols in workspace using Telescope"})
vim.keymap.set('n', '<leader>ch', function() require('telescope.builtin').command_history() end, {desc = "Browse command history using Telescope"})
vim.keymap.set('n', '<leader>rg', function() require('telescope.builtin').registers() end, {desc = "Show registers using Telescope"})
vim.keymap.set('n', '<leader>bb', function() require('telescope.builtin').buffers() end, {desc = "List open buffers using Telescope"})
vim.keymap.set('n', '<leader>gcp', function()
  require('telescope.builtin').git_commits({
    previewer = require('telescope.previewers').vim_buffer_cat.new,
    layout_strategy = 'vertical'
  })
end, {desc = "Search Git commits with detailed preview using Telescope"})
--[[ vim.keymap.set("n","<C-f>",function()
	builtin.grep_string({search = vim.fn.input("Ag ")})
end) ]]
vim.keymap.set("n","<C-f>",telescope.extensions.live_grep_args.live_grep_args,{noremap = true, desc = "Searches for text with arguments using Telescope Live Grep"})

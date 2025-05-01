--[[ -- telescope-commands-browser.lua
local pickers = require('telescope.pickers')
local finders = require('telescope.finders')
local conf = require('telescope.config').values
local actions = require('telescope.actions')
local action_state = require('telescope.actions.state')

-- Define commands by category
local commands = {
  -- Files category
  { desc = "Find Files", action = "require('telescope.builtin').find_files()", category = "Files" },
  { desc = "Git Files", action = "require('telescope.builtin').git_files()", category = "Files" },
  { desc = "Recent Files", action = "require('telescope.builtin').oldfiles()", category = "Files" },
  
  -- Buffers category
  { desc = "List Buffers", action = "require('telescope.builtin').buffers()", category = "Buffers" },
  { desc = "Search in Buffer", action = "require('telescope.builtin').current_buffer_fuzzy_find()", category = "Buffers" },
  
  -- Search category
  { desc = "Live Grep", action = "require('telescope.builtin').live_grep()", category = "Search" },
  { desc = "Grep String", action = "require('telescope.builtin').grep_string()", category = "Search" },
  { desc = "Live Grep Args", action = "require('telescope').extensions.live_grep_args.live_grep_args()", category = "Search" },
  
  -- Git category
  { desc = "Git Status", action = "require('telescope.builtin').git_status()", category = "Git" },
  { desc = "Git Commits", action = "require('telescope.builtin').git_commits()", category = "Git" },
  { desc = "Git Branches", action = "require('telescope.builtin').git_branches()", category = "Git" },
  
  -- LSP category
  { desc = "LSP References", action = "require('telescope.builtin').lsp_references()", category = "LSP" },
  { desc = "LSP Symbols", action = "require('telescope.builtin').lsp_dynamic_workspace_symbols()", category = "LSP" },
  { desc = "Diagnostics", action = "require('telescope.builtin').diagnostics()", category = "LSP" },
  
  -- General category
  { desc = "Help Tags", action = "require('telescope.builtin').help_tags()", category = "Help" },
  { desc = "Commands", action = "require('telescope.builtin').commands()", category = "General" },
  { desc = "Keymaps", action = "require('telescope.builtin').keymaps()", category = "General" },
}

local function browse_commands()
  -- Process commands for display
  local results = {}
  for _, cmd in ipairs(commands) do
    table.insert(results, {
      description = cmd.desc,
      action = cmd.action,
      category = cmd.category,
      display = string.format("%s: %s", cmd.category, cmd.desc),
    })
  end
  
  -- Sort by category
  table.sort(results, function(a, b)
    if a.category == b.category then
      return a.description < b.description
    else
      return a.category < b.category
    end
  end)
  
  -- Create the picker
  pickers.new(conf, {
    prompt_title = "Telescope Commands",
    finder = finders.new_table({
      results = results,
      entry_maker = function(entry)
        return {
          value = entry,
          ordinal = entry.category .. " " .. entry.description,
          display = entry.display,
        }
      end
    }),
    sorter = conf.generic_sorter({}),
    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        local selection = action_state.get_selected_entry()
        actions.close(prompt_bufnr)
        local cmd = selection.value
        -- Execute the command
        vim.cmd("lua " .. cmd.action)
      end)
      return true
    end,
  }):find()
end

-- Set up the keybinding
vim.keymap.set("n", "<leader>fx", function()
  browse_commands()
end, { desc = "Browse all Telescope commands" }) ]]

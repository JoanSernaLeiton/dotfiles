local telescope = require('telescope')
local builtin = require('telescope.builtin')
local actions = require('telescope.actions')
local wk = require('which-key')

telescope.load_extension('fzf')

-- fd command: native filtering is ~10x faster than Lua-side file_ignore_patterns
-- Used by <C-p>: respects .gitignore, excludes common noise
local fd_cmd = {
  "fd", "--type", "f", "--hidden", "--follow",
  "--exclude", ".git",
  "--exclude", "node_modules",
  "--exclude", "dist",
  "--exclude", "vendor",
  "--exclude", "*.lock",
}

-- Used by <leader>ff: shows ALL files in workspace (ignores .gitignore)
local fd_all_cmd = {
  "fd", "--type", "f", "--hidden", "--follow",
  "--no-ignore-vcs",
  "--exclude", ".git",
  "--exclude", "node_modules",
}

telescope.setup({
  defaults = {
    -- No file_ignore_patterns: offload filtering to fd/rg (avoids O(n×patterns) Lua overhead)
    path_display = { "truncate" },
    sorting_strategy = "ascending",
    layout_strategy = "horizontal",
    layout_config = {
      horizontal = {
        prompt_position = "top",
        preview_width = 0.55,
        width = 0.9,
        height = 0.85,
      },
      vertical = {
        prompt_position = "top",
        preview_height = 0.5,
        width = 0.85,
        height = 0.9,
      },
    },
    color_devicons = true,
    winblend = 10,
    border = true,
    borderchars = { "─", "│", "─", "│", "╭", "╮", "╯", "╰" },
    selection_caret = "❯ ",
    prompt_prefix = "   ",
    set_env = { ['COLORTERM'] = 'truecolor' },

    -- Cache recent pickers to avoid re-scanning on reopen
    cache_picker = {
      num_pickers = 5,
      limit_entries = 1000,
    },

    mappings = {
      i = {
        ["<C-j>"] = actions.move_selection_next,
        ["<C-k>"] = actions.move_selection_previous,
        ["<C-u>"] = actions.preview_scrolling_up,
        ["<C-d>"] = actions.preview_scrolling_down,
        ["<C-c>"] = actions.close,
        ["<ESC>"] = actions.close,
        ["<C-q>"] = actions.smart_send_to_qflist + actions.open_qflist,
        ["<Tab>"] = actions.toggle_selection + actions.move_selection_next,
        ["<S-Tab>"] = actions.toggle_selection + actions.move_selection_previous,
        ["<C-l>"] = actions.complete_tag,
      },
      n = {
        ["<C-c>"] = actions.close,
        ["q"] = actions.close,
        ["<C-u>"] = actions.preview_scrolling_up,
        ["<C-d>"] = actions.preview_scrolling_down,
        ["<C-q>"] = actions.smart_send_to_qflist + actions.open_qflist,
        ["?"] = actions.which_key,
      },
    },
  },

  pickers = {
    find_files = {
      theme = "dropdown",
      previewer = false,
      find_command = fd_cmd,
    },
    buffers = {
      theme = "dropdown",
      previewer = false,
      sort_lastused = true,
      mappings = {
        i = { ["<C-d>"] = actions.delete_buffer },
        n = { ["dd"] = actions.delete_buffer },
      },
    },

    lsp_references = {
      path_display = { "shorten" },
      layout_config = { preview_width = 0.55 },
      show_line = true,
      include_declaration = false,
    },
    lsp_definitions = {
      path_display = { "shorten" },
      layout_config = { preview_width = 0.55 },
    },
    lsp_document_symbols = {
      symbol_width = 40,
    },

    grep_string = {
      only_sort_text = true,
      layout_strategy = "vertical",
      layout_config = { preview_height = 0.5 },
    },
    live_grep = {
      layout_strategy = "vertical",
      layout_config = { preview_height = 0.5 },
      -- Debounce: wait 100ms after typing stops before firing grep
      debounce = 100,
      additional_args = { "--hidden", "--glob", "!.git" },
    },

    git_status = {
      layout_strategy = "vertical",
      layout_config = { preview_height = 0.6 },
    },
  },

  extensions = {
    fzf = {
      fuzzy = true,
      override_generic_sorter = true,
      override_file_sorter = true,
      case_mode = "smart_case",
    },
  },
})

-- Cache git-repo status per cwd to avoid a shell call on every picker open
local _git_cache = {}
local function is_git_repo()
  local cwd = vim.fn.getcwd()
  if _git_cache[cwd] == nil then
    vim.fn.system("git rev-parse --is-inside-work-tree")
    _git_cache[cwd] = vim.v.shell_error == 0
  end
  return _git_cache[cwd]
end

local function project_files()
  if is_git_repo() then
    builtin.git_files({})
  else
    builtin.find_files({})
  end
end

local function all_files()
  builtin.find_files({ find_command = fd_all_cmd })
end

local function smart_grep()
  if is_git_repo() then
    builtin.live_grep({})
  else
    builtin.live_grep({ additional_args = { "--no-require-git" } })
  end
end

wk.add({
  { "<C-p>", project_files, desc = "Project Files" },
  { "<C-f>", smart_grep, desc = "Live Grep" },
  { "<C-b>", builtin.buffers, desc = "Buffers" },
})

vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("UserLspTelescope", {}),
  callback = function(args)
    vim.keymap.set("n", "<leader>dd", function()
      builtin.diagnostics({ bufnr = 0 })
    end, { silent = true, desc = "Buffer Diagnostics", buffer = args.buf })
  end,
})

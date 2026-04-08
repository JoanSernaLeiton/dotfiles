-- telescope.lua

local telescope = require('telescope')
local builtin = require('telescope.builtin')
local actions = require('telescope.actions')
local wk = require('which-key')

-- Load extensions
telescope.load_extension('fzf')

-- Optimized Telescope configuration
telescope.setup({
  defaults = {
    file_ignore_patterns = {
      '.git/', 'node_modules', 'vendor/', 'dist/',
      '%.lock', '%.svg', '%.png'
    },
    wrap_results = true,
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

    -- Performance optimizations
    set_env = { ['COLORTERM'] = 'truecolor' },

    -- Mappings
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

  -- Picker configurations
  pickers = {
    -- Fast pickers without previews
    find_files = {
      theme = "dropdown",
      previewer = false,
      find_command = { "fd", "--type", "f", "--strip-cwd-prefix" },
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

    -- LSP pickers with enhanced previews
    lsp_references = {
      path_display = { "shorten" },
      layout_config = {
        preview_width = 0.55,
      },
      show_line = true,
      include_declaration = false,
    },
    lsp_definitions = {
      path_display = { "shorten" },
      layout_config = {
        preview_width = 0.55,
      },
    },
    lsp_document_symbols = {
      symbol_width = 40,
    },

    -- Search with preview
    grep_string = {
      only_sort_text = true,
      layout_strategy = "vertical",
      layout_config = {
        preview_height = 0.5,
      },
    },
    live_grep = {
      layout_strategy = "vertical",
      layout_config = {
        preview_height = 0.5,
      },
    },

    -- Git pickers
    git_status = {
      layout_strategy = "vertical",
      layout_config = {
        preview_height = 0.6,
      },
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

-- Smart project files function
local function project_files()
  vim.fn.system("git rev-parse --is-inside-work-tree")
  if vim.v.shell_error == 0 then
    builtin.git_files({})
  else
    builtin.find_files({})
  end
end


-- Only keep native keybindings (no leader prefix)
wk.add({
  { "<C-p>", project_files, desc = "Project Files" },
  { "<C-f>", builtin.live_grep, desc = "Live Grep" },
  { "<C-b>", builtin.buffers, desc = "Buffers" },
})

-- LSP keybindings (buffer-specific)
vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("UserLspTelescope", {}),
  callback = function(args)
    local bufnr = args.buf
    local opts = { silent = true, buffer = bufnr }

    -- Buffer-specific diagnostics
    vim.keymap.set("n", "<leader>dd", function() builtin.diagnostics({ bufnr = 0 }) end, { silent = true, desc = "Buffer Diagnostics" })
  end,
})

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
builtin.project_files = function()
  local opts = {}
  vim.fn.system("git rev-parse --is-inside-work-tree")
  if vim.v.shell_error == 0 then
    builtin.git_files(opts)
  else
    builtin.find_files(opts)
  end
end

-- Register keybindings with WhichKey
wk.register({
  -- Direct keybindings
  ["<C-p>"] = { builtin.project_files, "Project Files" },
  ["<C-f>"] = { builtin.live_grep, "Live Grep" },
  ["<C-b>"] = { builtin.buffers, "Buffers" },

  -- File Search (<leader>f prefix)
  ["<leader>f"] = {
    name = "Find",
    f = { builtin.find_files, "Find Files" },
    g = { builtin.git_files, "Git Files" },
    r = { builtin.oldfiles, "Recent Files" },
    w = { function() builtin.grep_string({ word_match = "-w" }) end, "Find Word Under Cursor" },
    s = { builtin.grep_string, "Grep String" },
    l = { builtin.live_grep, "Live Grep" },
    b = { builtin.current_buffer_fuzzy_find, "Buffer Fuzzy Find" },
  },

  -- LSP search via Telescope (<leader>s prefix)
  ["<leader>s"] = {
    name = "Symbols",
    d = { builtin.lsp_document_symbols, "Document Symbols" },
    w = { builtin.lsp_dynamic_workspace_symbols, "Workspace Symbols" },
    r = { builtin.lsp_references, "References" },
    i = { builtin.lsp_implementations, "Implementations" },
    t = { builtin.lsp_type_definitions, "Type Definitions" },
    c = { builtin.lsp_incoming_calls, "Incoming Calls" },
    o = { builtin.lsp_outgoing_calls, "Outgoing Calls" },
  },

  -- Git commands
  ["<leader>g"] = {
    name = "Git",
    c = { builtin.git_commits, "Commits" },
    b = { builtin.git_branches, "Branches" },
    s = { builtin.git_status, "Status" },
    t = { builtin.git_stash, "Stash" },
  },

  -- Help
  ["<leader>h"] = {
    name = "Help",
    k = { builtin.keymaps, "Keymaps" },
    h = { builtin.help_tags, "Help Tags" },
    m = { builtin.man_pages, "Man Pages" },
    c = { builtin.commands, "Commands" },
  },

  -- Renamed to "Telescope Diagnostics" to avoid confusion with LSP diagnostics
  ["<leader>t"] = {
    name = "Telescope",
    d = { builtin.diagnostics, "All Diagnostics" },
    p = { "<cmd>Telescope resume<CR>", "Resume Last Picker" },
  },
})

-- Override LSP keybindings to use Telescope
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    local bufnr = args.buf
    local opts = { noremap = true, silent = true, buffer = bufnr }

    -- Use telescope for LSP navigation
    vim.keymap.set("n", "gd", function() builtin.lsp_definitions() end, opts)
    vim.keymap.set("n", "gr", function() builtin.lsp_references({ include_declaration = false }) end, opts)
    vim.keymap.set("n", "gi", function() builtin.lsp_implementations() end, opts)
    vim.keymap.set("n", "gt", function() builtin.lsp_type_definitions() end, opts)

    -- Add buffer-specific diagnostics - now through Telescope namespace
    vim.keymap.set("n", "<leader>td", function() builtin.diagnostics({ bufnr = 0 }) end,
      { noremap = true, silent = true, desc = "Buffer Diagnostics" })

    -- Keep native LSP for these (better experience)
    vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
    vim.keymap.set("n", "<C-k>", vim.lsp.buf.signature_help, opts)
  end,
})

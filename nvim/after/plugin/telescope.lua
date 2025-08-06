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


-- Register keybindings with WhichKey using the new flat-list format
wk.add({
  { "<C-p>", project_files, desc = "Project Files" },
  { "<C-f>", builtin.live_grep, desc = "Live Grep" },
  { "<C-b>", builtin.buffers, desc = "Buffers" },

  { "<leader>f", group = "Find" },
  { "<leader>ff", builtin.find_files, desc = "Find Files" },
  { "<leader>fg", builtin.git_files, desc = "Git Files" },
  { "<leader>fr", builtin.oldfiles, desc = "Recent Files" },
  { "<leader>fw", function() builtin.grep_string({ word_match = "-w" }) end, desc = "Find Word Under Cursor" },
  { "<leader>fs", builtin.grep_string, desc = "Grep String" },
  { "<leader>fl", builtin.live_grep, desc = "Live Grep" },
  { "<leader>fb", builtin.current_buffer_fuzzy_find, desc = "Buffer Fuzzy Find" },

  { "<leader>h", group = "Help" },
  { "<leader>hk", builtin.keymaps, desc = "Keymaps" },
  { "<leader>hh", builtin.help_tags, desc = "Help Tags" },
  { "<leader>hm", builtin.man_pages, desc = "Man Pages" },
  { "<leader>hc", builtin.commands, desc = "Commands" },

  { "<leader>t", group = "Telescope" },
  { "<leader>td", builtin.diagnostics, desc = "All Diagnostics" },
  { "<leader>tp", "<cmd>Telescope resume<CR>", desc = "Resume Last Picker" },
})

-- Override LSP keybindings to use Telescope
vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("UserLspTelescope", {}),
  callback = function(args)
    local bufnr = args.buf
    local opts = { silent = true, buffer = bufnr }

    -- Use telescope for LSP navigation
    vim.keymap.set("n", "gd", builtin.lsp_definitions, opts)
    vim.keymap.set("n", "gr", function() builtin.lsp_references({ include_declaration = false }) end, opts)
    vim.keymap.set("n", "gi", builtin.lsp_implementations, opts)
    vim.keymap.set("n", "gt", builtin.lsp_type_definitions, opts)

    -- Add buffer-specific diagnostics - now through Telescope namespace
    vim.keymap.set("n", "<leader>tD", function() builtin.diagnostics({ bufnr = 0 }) end, { silent = true, desc = "Buffer Diagnostics" })

    -- Keep native LSP for these (better experience)
    vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
    vim.keymap.set("n", "<C-k>", vim.lsp.buf.signature_help, opts)
  end,
})

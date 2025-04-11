-- Disable netrw for better performance
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
vim.opt.termguicolors = true

local api = require("nvim-tree.api")
local wk = require("which-key")

local function on_attach(bufnr)
  local function opts(desc)
    return { desc = "nvim-tree: " .. desc, buffer = bufnr, noremap = true, silent = true, nowait = true }
  end

  -- WhichKey integration for NvimTree with prefix 'e' for explorer
  wk.register({
    -- File operations
    ["f"] = {
      name = "File Operations",
      c = { api.fs.create, "Create" },
      r = { api.fs.rename, "Rename" },
      m = { api.fs.rename_full, "Move (Rename Path)" },
      d = { api.fs.remove, "Delete" },
      t = { api.fs.trash, "Trash" },
      x = { api.fs.cut, "Cut" },
      p = { api.fs.paste, "Paste" },
      y = { api.fs.copy.node, "Copy" },
    },

    -- Copy paths (unified with Telescope patterns)
    ["y"] = {
      name = "Copy Path",
      a = { api.fs.copy.absolute_path, "Absolute Path" },
      r = { api.fs.copy.relative_path, "Relative Path" },
      n = { api.fs.copy.filename, "Filename" },
      b = { api.fs.copy.basename, "Basename" },
    },

    -- Open - similar style to LSP navigation
    ["o"] = {
      name = "Open",
      e = { api.node.open.edit, "Edit" },
      v = { api.node.open.vertical, "Vertical Split" },
      h = { api.node.open.horizontal, "Horizontal Split" },
      t = { api.node.open.tab, "Tab" },
      p = { api.node.open.preview, "Preview" },
    },

    -- Navigate (similar to LSP)
    ["g"] = {
      name = "Go To",
      p = { api.node.navigate.parent, "Parent" },
      n = { api.node.navigate.sibling.next, "Next Sibling" },
      N = { api.node.navigate.sibling.prev, "Previous Sibling" },
      f = { api.node.navigate.sibling.first, "First Sibling" },
      l = { api.node.navigate.sibling.last, "Last Sibling" },
    },

    -- Root management
    ["r"] = {
      name = "Root",
      c = { api.tree.change_root_to_node, "Change Root Here" },
      p = { api.tree.change_root_to_parent, "Go To Parent" },
    },

    -- Telescope integration
    ["s"] = {
      name = "Search with Telescope",
      f = { function()
        api.tree.close()
        require("telescope.builtin").find_files()
      end, "Find Files" },
      g = { function()
        api.tree.close()
        require("telescope.builtin").live_grep()
      end, "Grep" },
      b = { function()
        api.tree.close()
        require("telescope.builtin").buffers()
      end, "Buffers" },
    },

    -- Tree operations
    ["t"] = {
      name = "Tree",
      r = { api.tree.reload, "Refresh" },
      e = { api.tree.expand_all, "Expand All" },
      c = { api.tree.collapse_all, "Collapse All" },
      h = { api.tree.toggle_help, "Help" },
    },

    -- Filters
    ["F"] = {
      name = "Filter",
      h = { api.tree.toggle_hidden_filter, "Toggle Hidden Files" },
      g = { api.tree.toggle_gitignore_filter, "Toggle Git Ignored" },
      c = { api.tree.toggle_git_clean_filter, "Toggle Git Clean" },
      b = { api.tree.toggle_no_buffer_filter, "Toggle No Buffer" },
    },

    -- Git navigation
    ["["] = {
      name = "Previous",
      g = { api.node.navigate.git.prev, "Git Change" },
      d = { api.node.navigate.diagnostics.prev, "Diagnostic" },
    },
    ["]"] = {
      name = "Next",
      g = { api.node.navigate.git.next, "Git Change" },
      d = { api.node.navigate.diagnostics.next, "Diagnostic" },
    },

    -- Close
    ["q"] = { api.tree.close, "Close Tree" },
  }, { prefix = "<leader>e", buffer = bufnr })

  -- Direct mappings without leader prefix
  vim.keymap.set("n", "<CR>", api.node.open.edit, opts("Open"))
  vim.keymap.set("n", "o", api.node.open.edit, opts("Open"))
  vim.keymap.set("n", "<Tab>", api.node.open.preview, opts("Preview"))
  vim.keymap.set("n", "<BS>", api.node.navigate.parent_close, opts("Close Directory"))
  vim.keymap.set("n", "K", api.node.show_info_popup, opts("Show Info"))
  vim.keymap.set("n", "h", api.node.navigate.parent_close, opts("Close Directory"))
  vim.keymap.set("n", "l", api.node.open.edit, opts("Open"))

  -- Git navigation
  vim.keymap.set("n", "]c", api.node.navigate.git.next, opts("Next Git"))
  vim.keymap.set("n", "[c", api.node.navigate.git.prev, opts("Prev Git"))

  -- Diagnostic navigation (integration with LSP)
  vim.keymap.set("n", "]d", api.node.navigate.diagnostics.next, opts("Next Diagnostic"))
  vim.keymap.set("n", "[d", api.node.navigate.diagnostics.prev, opts("Prev Diagnostic"))
end

-- Global keymaps (outside tree buffer)
vim.keymap.set("n", "<leader>ee", api.tree.toggle, { desc = "Toggle Explorer" })
vim.keymap.set("n", "<leader>ef", api.tree.focus, { desc = "Focus Explorer" })
vim.keymap.set("n", "<leader>ec", function()
  api.tree.find_file({
    open = true,
    focus = true,
    update_root = true
  })
end, { desc = "Find Current File" })

-- Setup NvimTree with optimized configuration
require("nvim-tree").setup({
  on_attach = on_attach,

  -- Performance settings
  auto_reload_on_write = true,
  filesystem_watchers = {
    enable = true,
    debounce_delay = 100,
    ignore_dirs = {
      "node_modules", ".git", "dist", "build",
      "target", "vendor", ".cache"
    },
  },

  -- View settings
  view = {
    width = 35,
    side = "left",
    preserve_window_proportions = true,
    signcolumn = "yes",
  },

  -- UI rendering
  renderer = {
    add_trailing = true,
    group_empty = true,
    highlight_git = "icon",
    highlight_opened_files = "name",
    highlight_modified = "name",
    indent_markers = {
      enable = true,
      icons = {
        corner = "└",
        edge = "│",
        item = "│",
        none = " ",
      },
    },
    icons = {
      git_placement = "before",
      diagnostics_placement = "signcolumn",
      modified_placement = "after",
      padding = " ",
      show = {
        file = true,
        folder = true,
        folder_arrow = true,
        git = true,
        modified = true,
        diagnostics = true,
      },
      glyphs = {
        default = "󰈚",
        symlink = "",
        folder = {
          arrow_closed = "›",
          arrow_open = "⌄",
          default = "📁",
          open = "📂",
          empty = "📁",
          empty_open = "📂",
          symlink = "",
          symlink_open = "",
        },
        git = {
          unstaged = "✗",
          staged = "✓",
          unmerged = "",
          renamed = "➜",
          untracked = "★",
          deleted = "",
          ignored = "◌",
        },
      },
    },
  },

  -- LSP Zero integration for diagnostics
  diagnostics = {
    enable = true,
    show_on_dirs = true,
    show_on_open_dirs = true,
    debounce_delay = 50,
    severity = {
      min = vim.diagnostic.severity.HINT,
      max = vim.diagnostic.severity.ERROR,
    },
    icons = {
      hint = "",
      info = "",
      warning = "",
      error = "",
    },
  },

  -- Git integration
  git = {
    enable = true,
    show_on_dirs = true,
    timeout = 400,
  },

  -- Modified files tracking
  modified = {
    enable = true,
    show_on_dirs = true,
  },

  -- Actions
  actions = {
    use_system_clipboard = true,
    open_file = {
      quit_on_open = false,
      eject = true,
      resize_window = true,
      window_picker = {
        enable = true,
        exclude = {
          filetype = { "notify", "packer", "qf", "diff", "fugitive" },
          buftype = { "nofile", "terminal", "help" },
        },
      },
    },
  },

  -- Filtering
  filters = {
    dotfiles = false,
    git_ignored = true,
    custom = { "^.DS_Store$", "^.git$" },
    exclude = { ".gitignore" },
  },
})

-- Transparent background to match theme
vim.cmd([[highlight NvimTreeNormal guibg=NONE ctermbg=NONE]])
vim.cmd([[highlight NvimTreeEndOfBuffer guibg=NONE ctermbg=NONE]])
vim.cmd([[highlight NvimTreeWinSeparator guibg=NONE ctermbg=NONE guifg=#444444]])

-- Custom highlight enhancements
vim.cmd([[
  highlight NvimTreeGitNew guifg=#98c379
  highlight NvimTreeGitDirty guifg=#e5c07b
  highlight NvimTreeGitStaged guifg=#98c379
  highlight NvimTreeGitMerge guifg=#c678dd
  highlight NvimTreeGitRenamed guifg=#61afef
  highlight NvimTreeGitDeleted guifg=#e06c75
  highlight NvimTreeFolderName guifg=#61afef
  highlight NvimTreeOpenedFolderName guifg=#61afef gui=bold
  highlight NvimTreeEmptyFolderName guifg=#61afef
  highlight NvimTreeSymlinkFolderName guifg=#c678dd
]])

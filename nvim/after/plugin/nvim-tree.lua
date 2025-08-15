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

  -- WhichKey integration for NvimTree using the new flat-list format
  -- These mappings are buffer-local and will only activate in the nvim-tree window
  wk.add({
    -- File operations group, triggered by <leader>ef
    { "<leader>ef",  group = "File" },
    { "<leader>efc", api.fs.create,                                                              desc = "Create" },
    { "<leader>efr", api.fs.rename,                                                              desc = "Rename" },
    { "<leader>efm", api.fs.rename_full,                                                         desc = "Move (Rename Path)" },
    { "<leader>efd", api.fs.remove,                                                              desc = "Delete" },
    { "<leader>eft", api.fs.trash,                                                               desc = "Trash" },
    { "<leader>efx", api.fs.cut,                                                                 desc = "Cut" },
    { "<leader>efp", api.fs.paste,                                                               desc = "Paste" },
    { "<leader>efy", api.fs.copy.node,                                                           desc = "Copy" },

    { "<leader>ey",  group = "Copy Path" },
    { "<leader>eya", api.fs.copy.absolute_path,                                                  desc = "Absolute Path" },
    { "<leader>eyr", api.fs.copy.relative_path,                                                  desc = "Relative Path" },
    { "<leader>eyn", api.fs.copy.filename,                                                       desc = "Filename" },
    { "<leader>eyb", api.fs.copy.basename,                                                       desc = "Basename" },

    { "<leader>eo",  group = "Open" },
    { "<leader>eoe", api.node.open.edit,                                                         desc = "Edit" },
    { "<leader>eov", api.node.open.vertical,                                                     desc = "Vertical Split" },
    { "<leader>eoh", api.node.open.horizontal,                                                   desc = "Horizontal Split" },
    { "<leader>eot", api.node.open.tab,                                                          desc = "Tab" },
    { "<leader>eop", api.node.open.preview,                                                      desc = "Preview" },

    { "<leader>eg",  group = "Go To" },
    { "<leader>egp", api.node.navigate.parent,                                                   desc = "Parent" },
    { "<leader>egn", api.node.navigate.sibling.next,                                             desc = "Next Sibling" },
    { "<leader>egN", api.node.navigate.sibling.prev,                                             desc = "Previous Sibling" },
    { "<leader>egf", api.node.navigate.sibling.first,                                            desc = "First Sibling" },
    { "<leader>egl", api.node.navigate.sibling.last,                                             desc = "Last Sibling" },

    { "<leader>er",  group = "Root" },
    { "<leader>erc", api.tree.change_root_to_node,                                               desc = "Change Root Here" },
    { "<leader>erp", api.tree.change_root_to_parent,                                             desc = "Go To Parent" },

    { "<leader>es",  group = "Search with Telescope" },
    { "<leader>esf", function()
      api.tree.close(); require("telescope.builtin").find_files()
    end,                                                                                         desc = "Find Files" },
    { "<leader>esg", function()
      api.tree.close(); require("telescope.builtin").live_grep()
    end,                                                                                         desc = "Grep" },
    { "<leader>esb", function()
      api.tree.close(); require("telescope.builtin").buffers()
    end,                                                                                         desc = "Buffers" },

    { "<leader>et",  group = "Tree" },
    { "<leader>etr", api.tree.reload,                                                            desc = "Refresh" },
    { "<leader>ete", api.tree.expand_all,                                                        desc = "Expand All" },
    { "<leader>etc", api.tree.collapse_all,                                                      desc = "Collapse All" },
    { "<leader>eth", api.tree.toggle_help,                                                       desc = "Help" },

    { "<leader>eF",  group = "Filter" },
    { "<leader>eFh", api.tree.toggle_hidden_filter,                                              desc = "Toggle Hidden Files" },
    { "<leader>eFg", api.tree.toggle_gitignore_filter,                                           desc = "Toggle Git Ignored" },
    { "<leader>eFc", api.tree.toggle_git_clean_filter,                                           desc = "Toggle Git Clean" },
    { "<leader>eFb", api.tree.toggle_no_buffer_filter,                                           desc = "Toggle No Buffer" },

    { "<leader>e[",  group = "Previous" },
    { "<leader>e[g", api.node.navigate.git.prev,                                                 desc = "Git Change" },
    { "<leader>e[d", api.node.navigate.diagnostics.prev,                                         desc = "Diagnostic" },
    { "<leader>e]",  group = "Next" },
    { "<leader>e]g", api.node.navigate.git.next,                                                 desc = "Git Change" },
    { "<leader>e]d", api.node.navigate.diagnostics.next,                                         desc = "Diagnostic" },

    { "<leader>eq",  api.tree.close,                                                             desc = "Close Tree" },
  }, { buffer = bufnr })

  -- Direct mappings without leader prefix
  vim.keymap.set("n", "<CR>", api.node.open.edit, opts("Open"))
  vim.keymap.set("n", "o", api.node.open.edit, opts("Open"))
  vim.keymap.set("n", "<Tab>", api.node.open.preview, opts("Preview"))
  vim.keymap.set("n", "<BS>", api.node.navigate.parent_close, opts("Close Directory"))
  vim.keymap.set("n", "K", api.node.show_info_popup, opts("Show Info"))
  vim.keymap.set("n", "h", api.node.navigate.parent_close, opts("Close Directory"))
  vim.keymap.set("n", "l", api.node.open.edit, opts("Open"))
end

-- Global keymaps (outside tree buffer)
wk.add({
  { "<leader>ee", api.tree.toggle, desc = "Toggle Explorer" },
  { "<leader>ef", api.tree.focus,  desc = "Focus Explorer" },
  {
    "<leader>ec",
    function()
      api.tree.find_file({ open = true, focus = true, update_root = true })
    end,
    desc = "Find Current File"
  },
})

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
    adaptive_size = true,     -- This enables automatic width adjustment
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
      hint = "",
      info = "",
      warning = "",
      error = "",
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
    git_ignored = false,
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

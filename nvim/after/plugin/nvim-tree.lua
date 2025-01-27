-- Disable netrw
vim.g.loaded_newtrw = 1
vim.g.loaded_netrwPlugin = 1

-- Enable 24-bit colors
vim.opt.termguicolors = true

local function my_on_attach(bufnr)
  local api = require("nvim-tree.api")

  local function opts(desc)
    return { desc = "nvim-tree: " .. desc, buffer = bufnr, noremap = true, silent = true, nowait = true }
  end

  -- Root and Directory Navigation
  vim.keymap.set('n', '<leader>ntc', api.tree.change_root_to_node, opts('CD'))
  vim.keymap.set('n', '<leader>nt-', api.tree.change_root_to_parent, opts('Up'))

  -- Opening Files
  vim.keymap.set('n', '<leader>nto', api.node.open.replace_tree_buffer, opts('Open: In Place'))
  vim.keymap.set('n', '<leader>ntT', api.node.open.tab, opts('Open: New Tab'))
  vim.keymap.set('n', '<leader>ntv', api.node.open.vertical, opts('Open: Vertical Split'))
  vim.keymap.set('n', '<leader>nth', api.node.open.horizontal, opts('Open: Horizontal Split'))
  vim.keymap.set('n', '<leader>nte', api.node.open.edit, opts('Open'))
  vim.keymap.set('n', '<leader>ntw', api.node.open.preview, opts('Open Preview')) -- Changed from ntp to ntw
  vim.keymap.set('n', '<CR>', api.node.open.edit, opts('Open'))

  -- File Operations
  vim.keymap.set('n', '<leader>nta', api.fs.create, opts('Create File Or Directory'))
  vim.keymap.set('n', '<leader>ntC', api.fs.copy.node, opts('Copy'))
  vim.keymap.set('n', '<leader>ntd', api.fs.remove, opts('Delete'))
  vim.keymap.set('n', '<leader>ntD', api.fs.trash, opts('Trash'))
  vim.keymap.set('n', '<leader>ntr', api.fs.rename, opts('Rename'))
  vim.keymap.set('n', '<leader>ntR', api.fs.rename_basename, opts('Rename: Basename'))
  vim.keymap.set('n', '<leader>ntu', api.fs.rename_full, opts('Rename: Full Path'))
  vim.keymap.set('n', '<leader>ntx', api.fs.cut, opts('Cut'))
  vim.keymap.set('n', '<leader>ntp', api.fs.paste, opts('Paste'))

  -- Copy Operations
  vim.keymap.set('n', '<leader>ntya', api.fs.copy.absolute_path, opts('Copy Absolute Path'))
  vim.keymap.set('n', '<leader>ntyb', api.fs.copy.basename, opts('Copy Basename'))
  vim.keymap.set('n', '<leader>ntyf', api.fs.copy.filename, opts('Copy Name'))
  vim.keymap.set('n', '<leader>ntyr', api.fs.copy.relative_path, opts('Copy Relative Path'))

  -- Navigation
  vim.keymap.set('n', '<leader>ntj', api.node.navigate.sibling.next, opts('Next Sibling'))
  vim.keymap.set('n', '<leader>ntk', api.node.navigate.sibling.prev, opts('Previous Sibling'))
  vim.keymap.set('n', '<leader>ntJ', api.node.navigate.sibling.last, opts('Last Sibling'))
  vim.keymap.set('n', '<leader>ntK', api.node.navigate.sibling.first, opts('First Sibling'))
  vim.keymap.set('n', '<leader>ntP', api.node.navigate.parent, opts('Parent Directory'))

  -- Git Navigation
  vim.keymap.set('n', ']c', api.node.navigate.git.next, opts('Next Git'))
  vim.keymap.set('n', '[c', api.node.navigate.git.prev, opts('Prev Git'))

  -- Diagnostics Navigation
  vim.keymap.set('n', ']e', api.node.navigate.diagnostics.next, opts('Next Diagnostic'))
  vim.keymap.set('n', '[e', api.node.navigate.diagnostics.prev, opts('Prev Diagnostic'))

  -- Tree Operations
  vim.keymap.set('n', '<leader>ntE', api.tree.expand_all, opts('Expand All'))
  vim.keymap.set('n', '<leader>ntW', api.tree.collapse_all, opts('Collapse'))
  vim.keymap.set('n', '<leader>ntR', api.tree.reload, opts('Refresh'))
  vim.keymap.set('n', '<leader>ntq', api.tree.close, opts('Close'))
  vim.keymap.set('n', '<C-b>',
    function() api.tree.toggle({ path = "<args>", find_file = true, update_root = false, focus = true }) end,
    { desc = "NvimTree Toggle" })

  -- Filters
  vim.keymap.set('n', '<leader>ntfb', api.tree.toggle_no_buffer_filter, opts('Toggle Filter: No Buffer'))
  vim.keymap.set('n', '<leader>ntfc', api.tree.toggle_git_clean_filter, opts('Toggle Filter: Git Clean'))
  vim.keymap.set('n', '<leader>ntfd', api.tree.toggle_hidden_filter, opts('Toggle Filter: Dotfiles'))
  vim.keymap.set('n', '<leader>ntfi', api.tree.toggle_gitignore_filter, opts('Toggle Filter: Git Ignore'))
  vim.keymap.set('n', '<leader>ntfm', api.tree.toggle_no_bookmark_filter, opts('Toggle Filter: No Bookmark'))

  -- Other Features
  vim.keymap.set('n', '<leader>nti', api.node.show_info_popup, opts('Info'))
  vim.keymap.set('n', '<leader>nt?', api.tree.toggle_help, opts('Help'))
  vim.keymap.set('n', '<leader>nts', api.tree.search_node, opts('Search'))
  vim.keymap.set('n', '<leader>ntm', api.marks.toggle, opts('Toggle Bookmark'))
  vim.keymap.set('n', '<leader>nt!', api.node.run.system, opts('Run System'))
end

require("nvim-tree").setup({
  -- Keep your existing settings
  actions = {
    use_system_clipboard = true,
    open_file = {
      resize_window = true,
      quit_on_open = true -- You might want to change this to false if you prefer the tree to stay open
    }
  },
  view = {
    width = 30,
    -- Add these for better window handling
    preserve_window_proportions = true, -- Keeps window size consistent
    adaptive_size = true,               -- Automatically adjusts width based on content
  },
  git = {
    enable = true,
    ignore = false,
    -- Add these for better git integration
    timeout = 400,       -- Faster git status updates
    show_on_dirs = true, -- Shows git status on directories
  },
  renderer = {
    highlight_git = 'icon',
    highlight_diagnostics = 'icon',
    highlight_opened_files = 'name',
    highlight_modified = 'icon',
    highlight_bookmarks = 'icon',
    -- Add these for better visual experience
    indent_markers = {
      enable = true, -- Shows indent markers when folders are open
      icons = {
        corner = "└ ",
        edge = "│ ",
        none = "  ",
      },
    },
    icons = {
      show = {
        folder = true,
        folder_arrow = true,
        file = true,
        git = true,
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
          -- Clearer git status icons
          unstaged = "✗",
          staged = "✓",
          unmerged = "",
          renamed = "➜",
          untracked = "★",
          deleted = "",
          ignored = "◌",
        },
      }
    },
    special_files = {
      -- Files that get special highlighting
      "README.md",
      "Makefile",
      "MAKEFILE",
      "package.json",
      "package-lock.json"
    },
  },
  filters = {
    exclude = { "node_modules", "vendor" },
    -- Add these for better filtering
    custom = {
      -- Add any custom file patterns you want to hide
      "^.git$",
      "^.DS_Store$"
    },
    dotfiles = false
  },
  diagnostics = {
    -- Add diagnostics support
    enable = true,
    show_on_dirs = true, -- Shows diagnostic icons on folders
    icons = {
      hint = "",
      info = "",
      warning = "",
      error = "",
    },
  },
  modified = {
    -- Track modified files
    enable = true,
    show_on_dirs = true,
  },
  on_attach = my_on_attach
})

vim.cmd([[ highlight NvimTreeNormal guibg=NONE ctermbg=NONE ]])

-- Additional highlights for better visuals
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

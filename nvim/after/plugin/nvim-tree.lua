vim.g.loaded_newtrw = 1
vim.g.loaded_netrwPlugin = 1
vim.opt.termguicolors = true
local function my_on_attach(bufnr)
  local api = require "nvim-tree.api"

  local function opts(desc)
    return { desc = "nvim-tree: " .. desc, buffer = bufnr, noremap = true, silent = true, nowait = true }
  end

  -- default mapping
  -- api.config.mappings.default_on_attach(bufnr)

  -- Custom key mappings with <leader>f prefix
-- Custom key mappings with <leader>nt prefix for better usability
  vim.keymap.set('n', '<leader>ntc', api.tree.change_root_to_node, opts('Change Directory'))
  vim.keymap.set('n', '<leader>nto', api.node.open.replace_tree_buffer, opts('Open: In Place'))
  vim.keymap.set('n', '<leader>nti', api.node.show_info_popup, opts('Info'))
  vim.keymap.set('n', '<leader>ntr', api.fs.rename_sub, opts('Rename: Omit Filename'))
  vim.keymap.set('n', '<leader>ntT', api.node.open.tab, opts('Open: New Tab'))
  vim.keymap.set('n', '<leader>ntV', api.node.open.vertical, opts('Open: Vertical Split'))
  vim.keymap.set('n', '<leader>ntH', api.node.open.horizontal, opts('Open: Horizontal Split'))
  vim.keymap.set('n', '<leader>ntb', api.node.navigate.parent_close, opts('Close Directory'))
  vim.keymap.set('n', '<CR>', api.node.open.edit, opts('Open'))
  vim.keymap.set('n', '<leader>ntP', api.node.open.preview, opts('Open Preview'))
  vim.keymap.set('n', '<leader>ntj', api.node.navigate.sibling.next, opts('Next Sibling'))
  vim.keymap.set('n', '<leader>ntk', api.node.navigate.sibling.prev, opts('Previous Sibling'))
  vim.keymap.set('n', '<leader>ntC', api.fs.copy.node, opts('Copy'))
  vim.keymap.set('n', '<leader>ntF', api.tree.toggle_git_clean_filter, opts('Toggle Filter: Git Clean'))
  vim.keymap.set('n', '<leader>ntD', api.fs.remove, opts('Delete'))
  vim.keymap.set('n', '<leader>ntX', api.fs.trash, opts('Trash'))
  vim.keymap.set('n', '<leader>ntE', api.tree.expand_all, opts('Expand All'))
  vim.keymap.set('n', '<leader>ntR', api.fs.rename_basename, opts('Rename: Basename'))
  vim.keymap.set('n', '<leader>ntp', api.fs.paste, opts('Paste'))
  vim.keymap.set('n', '<leader>ntu', api.node.navigate.parent, opts('Parent Directory'))
  vim.keymap.set('n', '<leader>ntq', api.tree.close, opts('Close'))
  vim.keymap.set('n', '<leader>ntm', api.fs.rename, opts('Rename'))
  vim.keymap.set('n', '<leader>ntS', api.tree.reload, opts('Refresh'))
  vim.keymap.set('n', '<leader>nt!', api.node.run.system, opts('Run System'))
  vim.keymap.set('n', '<leader>nts', api.tree.search_node, opts('Search'))
  vim.keymap.set('n', '<leader>ntl', api.tree.collapse_all, opts('Collapse'))
  vim.keymap.set('n', '<leader>ntX', api.fs.cut, opts('Cut'))
  vim.keymap.set('n', '<leader>nty', api.fs.copy.filename, opts('Copy Name'))
  vim.keymap.set('n', '<leader>ntY', api.fs.copy.absolute_path, opts('Copy Absolute Path'))
  vim.keymap.set('n', '<leader>ntO', function() api.tree.open({ path = "<args>" }) end, { desc = "NvimTree Open" })
  vim.keymap.set('n', '<leader>ntQ', api.tree.close, { desc = "NvimTree Close" })
  vim.keymap.set('n', '<C-b>', function() api.tree.toggle({ path = "<args>", find_file = true, update_root = false, focus = true }) end, { desc = "NvimTree Toggle" })
  vim.keymap.set('n', '<leader>ntf', function() api.tree.open({}) end, { desc = "NvimTree Focus" })
  vim.keymap.set('n', '<leader>ntR', api.tree.reload, { desc = "NvimTree Refresh" })
  vim.keymap.set('n', '<leader>ntF', function() api.tree.find_file({ update_root = false, open = true, focus = true }) end, { desc = "NvimTree Find File" })
  vim.keymap.set('n', '<leader>ntFT', function() api.tree.toggle({ path = "<args>", update_root = false, find_file = true, focus = true }) end, { desc = "NvimTree Find File Toggle" })
  vim.keymap.set('n', '<leader>ntC', api.fs.print_clipboard, { desc = "NvimTree Clipboard" })
  vim.keymap.set('n', '<leader>ntZ', function(size) api.tree.resize(size) end, { desc = "NvimTree Resize" })
  vim.keymap.set('n', '<leader>ntL', function() api.tree.collapse_all(false) end, { desc = "NvimTree Collapse" })
  vim.keymap.set('n', '<leader>ntLB', function() api.tree.collapse_all(true) end, { desc = "NvimTree Collapse Keep Buffers" })
  vim.keymap.set('n', '<leader>ntht', api.diagnostics.hi_test, { desc = "NvimTree Highlight Test" })
end
require("nvim-tree").setup({
  actions = {
    use_system_clipboard = true,
    open_file = {
      resize_window = true,
      quit_on_open = true
    }
  },
  view = {
    width = 30
  },
  git = {
    enable = true,
  },
  renderer = {
    highlight_git = 'icon',
    highlight_diagnostics = 'icon',
    highlight_opened_files = 'name',
    highlight_modified = 'icon',
    highlight_bookmarks = 'icon',
    icons = {
      show = {
        folder = true,
        folder_arrow = true,
        file = true,
        git = true
      },
      glyphs = {
        folder = {}
      }
    }
  },
  filters = {
    exclude = { "node_modules", "vendor" },
  },
  on_attach = my_on_attach
})

-- vim.keymap.set("n", "<C-b>", ":NvimTreeFindFile<CR>")
-- vim.keymap.set("n", "<leader>bo", ":NvimTreeOpen<CR>")

vim.cmd([[ highlight NvimTreeNormal guibg=NONE ctermbg=NONE ]])

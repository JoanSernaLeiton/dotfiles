require 'nvim-treesitter.configs'.setup {
  ensure_installed = {
    "javascript",
    "typescript",
    "python",
    "html",
    "css",
    "scss",
    "angular",
    "go",         -- Add Go language support
    "gomod",      -- Add Go module support
    "gowork",     -- Add Go workspace support
  },
  sync_install = false,
  auto_install = true,
  highlight = {
    enable = true,
    additional_vim_regex_highlighting = false
  },
  incremental_selection = {
    enable = true,
    keymaps = {
      init_selection = "gnn",
      node_incremental = "grn",
      scope_incremental = "grc",
      node_decremental = "grm",
    }
  }
}

-- Initialize lazy with your configuration
require("lazy").setup({
  require("joanserna.plugins")
}, {
  rocks = {
    enabled = false,
  },
  defaults = {
    lazy = false, -- Plugins load on startup unless specified otherwise
  },
  install = {
    colorscheme = { "onedark" },
  },
  checker = {
    enabled = true, -- Automatically check for plugin updates
    notify = true,  -- Disable update notifications
  },
  change_detection = {
    notify = false, -- Disable notifications when changes are detected
  },
  performance = {
    rtp = {
      disabled_plugins = {
        "gzip",
        "matchit",
        "matchparen",
        "netrwPlugin",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
      },
    },
  },
})

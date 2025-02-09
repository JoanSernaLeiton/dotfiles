-- Load lazy bootstrap
require("lazy")

-- Initialize lazy with your configuration
require("lazy").setup({
  require("joanserna.plugins") 
}, {
  defaults = {
    lazy = true, -- All plugins are lazy-loaded by default
  },
  install = {
    colorscheme = { "onedark" },
  },
  checker = {
    enabled = true, -- Automatically check for plugin updates
    notify = true, -- Disable update notifications
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

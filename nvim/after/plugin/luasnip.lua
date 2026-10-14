local luasnip = require("luasnip")

luasnip.config.set_config({
  history = false,
  updateevents = "TextChanged,TextChangedI",
})

-- Load VSCode-style snippets (friendly-snippets)
require("luasnip.loaders.from_vscode").lazy_load()

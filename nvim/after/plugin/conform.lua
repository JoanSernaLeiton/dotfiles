-- conform.setup() now lives in the lazy.nvim spec (plugins.lua) as `opts`,
-- so requiring the plugin here doesn't force it to load eagerly at startup.
-- Allows formatting visual selections e.g. V G :Format
vim.api.nvim_create_user_command("Format", function(args)
  require("conform").format({
    async = true,
    lsp_fallback = true,
    range = args.range,
  })
end, { range = true })

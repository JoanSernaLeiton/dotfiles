-- startup.nvim dashboard: shows on `nvim` with no file argument.
-- "Projects" section lists the traza-digital workspace plus its main repos;
-- picking one (via <CR> or its number key) cd's there and opens Telescope.
local M = {}

function M.setup()
  local workspace = "~/code/traza-digital"
  local projects = {
    { "  traza-digital (workspace)", workspace },
    { "  mvp-client",                workspace .. "/mvp-client" },
    { "  mvp-ventanilla",            workspace .. "/mvp-ventanilla" },
    { "  traza-microservicios",      workspace .. "/traza-microservicios" },
    { "  keycloack-settings",        workspace .. "/keycloack-settings" },
    { "  jbpm-settings",             workspace .. "/jbpm-settings" },
    { "  jbpm-process-definitions",  workspace .. "/jbpm-process-definitions" },
  }

  local body_content = {}
  for i, project in ipairs(projects) do
    table.insert(body_content, {
      project[1],
      -- `enew` clears the dashboard buffer out of the way before the tree
      -- opens, so it feels like nvim was launched fresh inside that project.
      "cd " .. project[2] .. " | enew | NvimTreeOpen",
      tostring(i),
    })
  end

  require("startup").setup({
    header = {
      type = "text",
      oldfiles_directory = false,
      align = "center",
      fold_section = false,
      title = "Header",
      margin = 5,
      content = {
        " ███╗   ██╗ ███████╗ ██████╗  ██╗   ██╗ ██╗ ███╗   ███╗",
        " ████╗  ██║ ██╔════╝██╔═══██╗ ██║   ██║ ██║ ████╗ ████║",
        " ██╔██╗ ██║ █████╗  ██║   ██║ ██║   ██║ ██║ ██╔████╔██║",
        " ██║╚██╗██║ ██╔══╝  ██║   ██║ ╚██╗ ██╔╝ ██║ ██║╚██╔╝██║",
        " ██║ ╚████║ ███████╗╚██████╔╝  ╚████╔╝  ██║ ██║ ╚═╝ ██║",
        " ╚═╝  ╚═══╝ ╚══════╝ ╚═════╝    ╚═══╝   ╚═╝ ╚═╝     ╚═╝",
      },
      highlight = "Statement",
      default_color = "",
      oldfiles_amount = 0,
    },
    body = {
      type = "mapping",
      oldfiles_directory = false,
      align = "center",
      fold_section = false,
      title = "Projects",
      margin = 5,
      content = body_content,
      highlight = "String",
      default_color = "",
      oldfiles_amount = 0,
    },
    footer = {
      type = "text",
      oldfiles_directory = false,
      align = "center",
      fold_section = false,
      title = "Footer",
      margin = 5,
      content = { "startup.nvim" },
      highlight = "Number",
      default_color = "",
      oldfiles_amount = 0,
    },
    options = {
      mapping_keys = true,
      cursor_column = 0.5,
      empty_lines_between_mappings = true,
      disable_statuslines = true,
      paddings = { 1, 3, 3, 0 },
    },
    mappings = {
      execute_command = "<CR>",
      open_file = "o",
      open_file_split = "<c-o>",
      open_section = "<TAB>",
      open_help = "?",
    },
    colors = {
      background = "#1f2227",
      folded_section = "#56b6c2",
    },
    parts = { "header", "body", "footer" },
  })
end

return M

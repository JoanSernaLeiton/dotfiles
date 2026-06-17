-- whichkey.lua

local wk = require("which-key")

wk.setup({
  plugins = {
    marks = true,
    registers = true,
    presets = {
      operators = true,
      motions = true,
      text_objects = true,
      windows = true,
      nav = true,
      z = true,
      g = true,
    },
  },
  win = {
    border = "rounded",
  },
  triggers = {
    { "<leader>", mode = { "n", "v" } },
  },
})

wk.add({
  -- OpenCode AI Group
  { "<leader>o", group = "OpenCode AI", icon = "🤖" },
  { "<leader>oa", function() require("opencode").ask("@this: ", { submit = true }) end, desc = "Ask OpenCode" },
  { "<leader>os", function() require("opencode").select() end, desc = "Select Action" },
  { "<leader>ot", function() require("opencode").toggle() end, desc = "Toggle OpenCode" },

  -- Search Group
  { "<leader>/", group = "Search", icon = "🔍" },
  { "<leader>ff", function()
    require("telescope.builtin").find_files({
      find_command = { "fd", "--type", "f", "--hidden", "--follow", "--no-ignore-vcs", "--exclude", ".git", "--exclude", "node_modules" },
    })
  end, desc = "Find All Files" },
  { "<leader>fb", function() require("telescope.builtin").buffers() end, desc = "Find Buffers" },
  { "<leader>fh", function() require("telescope.builtin").help_tags() end, desc = "Find Help" },
  { "<leader>fp", function() require("telescope.builtin").commands() end, desc = "Find Commands" },

  -- Buffer Group
  { "<leader>b", group = "Buffer", icon = "📋" },
  { "<leader>bb", function() require("telescope.builtin").buffers() end, desc = "List Buffers" },
  { "<leader>bd", "<cmd>bdelete<CR>", desc = "Delete Buffer" },
  { "<leader>bn", "<cmd>bnext<CR>", desc = "Next Buffer" },
  { "<leader>bp", "<cmd>bprevious<CR>", desc = "Previous Buffer" },

  -- File Explorer (defined in nvim-tree config)

  -- Code Group
  { "<leader>c", group = "Code", icon = "💻" },
  { "<leader>cf", function() vim.lsp.buf.format({ async = true }) end, desc = "Format Code" },
  { "<leader>ca", function() vim.lsp.buf.code_action() end, desc = "Code Actions" },
  { "<leader>cr", function() vim.lsp.buf.rename() end, desc = "Rename Symbol" },
  { "<leader>ch", function() vim.lsp.buf.hover() end, desc = "Hover Docs" },

  -- Git Group (basic shortcuts, detailed mappings in git_config.lua)
  { "<leader>g", group = "Git", icon = "📦" },

  -- Terminal Group
  { "<leader>t", group = "Terminal", icon = "⌨️" },
  { "<leader>tt", "<cmd>ToggleTerm<CR>", desc = "New Terminal" },
  { "<leader>tv", "<cmd>vsplit<CR><cmd>ToggleTerm<CR>", desc = "Vertical Terminal" },
  { "<leader>ts", "<cmd>split<CR><cmd>ToggleTerm<CR>", desc = "Horizontal Terminal" },
  { "<leader>td", function() require("lazydocker").open() end, desc = "Lazydocker" },

  -- Window Group
  { "<leader>w", group = "Window", icon = "🪟" },
  { "<leader>w+", "<cmd>resize +5<CR>", desc = "Increase Height" },
  { "<leader>w-", "<cmd>resize -5<CR>", desc = "Decrease Height" },
  { "<leader>w>", "<cmd>vertical resize +5<CR>", desc = "Increase Width" },
  { "<leader>w<", "<cmd>vertical resize -5<CR>", desc = "Decrease Width" },

  -- Tools Group
  { "<leader>u", "<cmd>UndotreeToggle<CR>", desc = "Undo Tree" },
})

-- Make WhichKey available globally
_G.which_key = wk

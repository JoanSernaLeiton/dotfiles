-- ToggleTerm configuration
-- Provides persistent terminal functionality in Neovim

local toggleterm = require('toggleterm')
local wk = require('which-key')

-- Set up ToggleTerm with sensible defaults
toggleterm.setup({
  size = function(term)
    if term.direction == "horizontal" then
      return 15
    elseif term.direction == "vertical" then
      return vim.o.columns * 0.4
    end
  end,
  open_mapping = [[<c-\>]],
  hide_numbers = true,
  shade_filetypes = {},
  shade_terminals = true,
  shading_factor = 2,
  start_in_insert = true,
  insert_mappings = true,
  persist_size = true,
  direction = "horizontal",
  close_on_exit = true,
  shell = vim.o.shell,
  float_opts = {
    border = "curved",
    winblend = 0,
    highlights = {
      border = "Normal",
      background = "Normal",
    },
  },
})

-- Helper function to get the next available terminal number
local function get_next_terminal_number()
  local terminals = require('toggleterm.terminal').get_all()
  local max_num = 0
  for _, term in pairs(terminals) do
    if term.id and term.id > max_num then
      max_num = term.id
    end
  end
  return max_num + 1
end

-- Helper function to create or toggle a specific terminal
local function toggle_terminal_by_id(id, direction)
  direction = direction or "horizontal"
  local Terminal = require('toggleterm.terminal').Terminal
  local term = Terminal:new({
    id = id,
    direction = direction,
  })
  term:toggle()
end


-- Quick access with Ctrl-\
vim.keymap.set({ "n", "i", "t" }, "<C-\\>", "<cmd>ToggleTerm<CR>", { noremap = true, silent = true, desc = "Toggle Terminal" })

-- Exit terminal insert mode with ESC
vim.keymap.set("t", "<Esc>", [[<C-\><C-n>]], { noremap = true, silent = true })

-- Navigate between terminal windows (when in normal mode within terminal)
vim.keymap.set("t", "<C-h>", [[<C-\><C-n><C-w>h]], { noremap = true, silent = true })
vim.keymap.set("t", "<C-j>", [[<C-\><C-n><C-w>j]], { noremap = true, silent = true })
vim.keymap.set("t", "<C-k>", [[<C-\><C-n><C-w>k]], { noremap = true, silent = true })
vim.keymap.set("t", "<C-l>", [[<C-\><C-n><C-w>l]], { noremap = true, silent = true })

-- Resize terminal windows
-- Increase/decrease height (for horizontal terminals)
vim.keymap.set("t", "<C-+>", [[<C-\><C-n><C-w>+<C-w>i]], { noremap = true, silent = true })
vim.keymap.set("t", "<C-->", [[<C-\><C-n><C-w>-<C-w>i]], { noremap = true, silent = true })
vim.keymap.set("t", "<C-=>", [[<C-\><C-n><C-w>+<C-w>i]], { noremap = true, silent = true }) -- Alt for + key

-- Increase/decrease width (for vertical terminals)
vim.keymap.set("t", "<C->>", [[<C-\><C-n><C-w>><C-w>i]], { noremap = true, silent = true })
vim.keymap.set("t", "<C-<>", [[<C-\><C-n><C-w><<C-w>i]], { noremap = true, silent = true })

-- Resize by specific amount (5 lines/columns)
vim.keymap.set("t", "<A-+>", [[<C-\><C-n>:resize +5<CR><C-w>i]], { noremap = true, silent = true })
vim.keymap.set("t", "<A-->", [[<C-\><C-n>:resize -5<CR><C-w>i]], { noremap = true, silent = true })
vim.keymap.set("t", "<A->>", [[<C-\><C-n>:vertical resize +5<CR><C-w>i]], { noremap = true, silent = true })
vim.keymap.set("t", "<A-<>", [[<C-\><C-n>:vertical resize -5<CR><C-w>i]], { noremap = true, silent = true })

-- Resize terminal from normal mode (when ESC is pressed in terminal)
vim.keymap.set("n", "<leader>t+", "<cmd>resize +5<CR>", { noremap = true, silent = true, desc = "Increase Terminal Height" })
vim.keymap.set("n", "<leader>t-", "<cmd>resize -5<CR>", { noremap = true, silent = true, desc = "Decrease Terminal Height" })
vim.keymap.set("n", "<leader>t>", "<cmd>vertical resize +5<CR>", { noremap = true, silent = true, desc = "Increase Terminal Width" })
vim.keymap.set("n", "<leader>t<", "<cmd>vertical resize -5<CR>", { noremap = true, silent = true, desc = "Decrease Terminal Width" })

-- Register resize keymaps in which-key
wk.register({
  t = {
    name = "Terminal",
    t = { "<cmd>ToggleTerm<CR>", "Toggle Terminal" },
    f = { "<cmd>ToggleTerm direction=float<CR>", "Toggle Floating Terminal" },
    h = { "<cmd>ToggleTerm direction=horizontal<CR>", "Toggle Horizontal Terminal" },
    v = { "<cmd>ToggleTerm direction=vertical<CR>", "Toggle Vertical Terminal" },
    n = {
      function()
        local next_id = get_next_terminal_number()
        toggle_terminal_by_id(next_id, "horizontal")
      end,
      "Create New Terminal"
    },
    -- Split-like functionality (creates side-by-side terminals)
    s = {
      function()
        local next_id = get_next_terminal_number()
        toggle_terminal_by_id(next_id, "vertical")
      end,
      "Split Terminal (Vertical)"
    },
    S = {
      function()
        local next_id = get_next_terminal_number()
        toggle_terminal_by_id(next_id, "horizontal")
      end,
      "Split Terminal (Horizontal)"
    },
    -- Resize (from normal mode)
    ["+"] = { "<cmd>resize +5<CR>", "Increase Height" },
    ["-"] = { "<cmd>resize -5<CR>", "Decrease Height" },
    [">"] = { "<cmd>vertical resize +5<CR>", "Increase Width" },
    ["<"] = { "<cmd>vertical resize -5<CR>", "Decrease Width" },
  },
}, { prefix = "<leader>" })

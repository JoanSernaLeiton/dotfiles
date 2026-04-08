-- ToggleTerm configuration

local toggleterm = require('toggleterm')

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

-- Quick access with Ctrl-\
vim.keymap.set({ "n", "i", "t" }, "<C-\\>", "<cmd>ToggleTerm<CR>", { noremap = true, silent = true, desc = "Toggle Terminal" })

-- Exit terminal insert mode with ESC
vim.keymap.set("t", "<Esc>", [[<C-\><C-n>]], { noremap = true, silent = true })

-- Navigate between terminal windows
vim.keymap.set("t", "<C-h>", [[<C-\><C-n><C-w>h]], { noremap = true, silent = true })
vim.keymap.set("t", "<C-j>", [[<C-\><C-n><C-w>j]], { noremap = true, silent = true })
vim.keymap.set("t", "<C-k>", [[<C-\><C-n><C-w>k]], { noremap = true, silent = true })
vim.keymap.set("t", "<C-l>", [[<C-\><C-n><C-w>l]], { noremap = true, silent = true })

-- Resize terminal in terminal mode
vim.keymap.set("t", "<C-+>", [[<C-\><C-n><C-w>+<C-w>i]], { noremap = true, silent = true })
vim.keymap.set("t", "<C-->", [[<C-\><C-n><C-w>-<C-w>i]], { noremap = true, silent = true })
vim.keymap.set("t", "<C->>", [[<C-\><C-n><C-w>><C-w>i]], { noremap = true, silent = true })
vim.keymap.set("t", "<C-<>", [[<C-\><C-n><C-w><<C-w>i]], { noremap = true, silent = true })

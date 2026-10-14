-- ToggleTerm configuration
-- toggleterm.setup() now lives in the lazy.nvim spec (plugins.lua) as `opts`,
-- so requiring the plugin here doesn't force it to load eagerly at startup.
-- These keymaps use plain <cmd>/terminal-mode command strings, not
-- require('toggleterm'), so they don't force the plugin to load either.

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

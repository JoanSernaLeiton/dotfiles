-- vim.keymap.set mode, shortcut, action, config
local opts = { noremap = true, silent = true }

-- Visual mode - move lines
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

-- Search - center cursor
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")

-- Escape
vim.keymap.set("i", "jj", "<ESC>", opts)
vim.keymap.set("n", "<esc>", ":noh<return><esc>", opts)

-- Quick save
vim.keymap.set("n", "<C-s>", ":wa<CR>", opts)

-- Buffer navigation
vim.keymap.set("n", "<C-h>", ":bprevious<CR>", opts)
vim.keymap.set("n", "<C-l>", ":bnext<CR>", opts)

-- Quick quit buffer
vim.keymap.set("n", "<leader>qt", ":bd<CR>", opts)

-- Folding
vim.keymap.set("n", "zC", "zM", opts)
vim.keymap.set("n", "zO", "zR", opts)

-- Indentation
vim.keymap.set("v", ">", ">gv", { silent = true })
vim.keymap.set("v", "<", "<gv", { silent = true })

-- Quick replace word under cursor
vim.keymap.set("n", "<leader>s", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]])

-- Make file executable
vim.keymap.set("n", "<leader>x", "<cmd>!chmod +x %<CR>", { silent = true })

-- Quickfix navigation
vim.keymap.set("n", "]q", "<cmd>cnext<CR>zz")
vim.keymap.set("n", "[q", "<cmd>cprevious<CR>zz")

-- Buffer navigation
vim.keymap.set("n", "<C-h>", ":bprevious<CR>", opts)
vim.keymap.set("n", "<C-l>", ":bnext<CR>", opts)

-- Close quickfix window
vim.api.nvim_create_autocmd("FileType", {
  callback = function()
    local bufnr = vim.fn.bufnr('%')
    vim.keymap.set("n", "e", function()
      vim.api.nvim_command([[execute "normal! \<cr>"]])
      vim.api.nvim_command(bufnr .. 'bd')
    end, { buffer = bufnr })
  end,
  pattern = "qf",
})

-- TypeScript organize imports
vim.keymap.set("n", "<leader>op", function()
  vim.lsp.buf.execute_command({ command = "_typescript.organizeImports", arguments = { vim.fn.expand("%:p") } })
end, opts)

-- Split
vim.keymap.set("n", "<leader>V", ":vsplit<CR>", opts)

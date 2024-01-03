-- vim.keymat.set mode, shortcut, action, config
local opts = {noremap = true, silent = true}
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")

vim.keymap.set("n", "<leader>b", "<cmd> silent !tmux new-session<CR>")
vim.keymap.set("n", "<leader>f", vim.lsp.buf.format)

vim.keymap.set("i","jj","<ESC>",opts)
vim.keymap.set("n","<leader>V",":vsplit<CR>",opts)
vim.keymap.set("n","ff",":Prettier<CR>",opts)
vim.keymap.set("n","<C-s>",":wa<CR>",opts)

vim.keymap.set("n", "<C-k>", "<cmd>cnext<CR>zz")
vim.keymap.set("n", "<leader>>>", ":vertical resize +10<CR>")
vim.keymap.set("n", "<leader><<", ":vertical resize -10<CR>")

-- Clear search highlight
vim.keymap.set("n","<esc>",":noh<return><esc>",opts)

-- Fold
vim.keymap.set("n","zC","zM",opts)
vim.keymap.set("n","zO","zR",opts)
vim.keymap.set("n","zz","<C-w>|",opts)

-- Indentations
vim.keymap.set("v",">",">gv",{silent = true})
vim.keymap.set("v","<","<gv",{silent = true})

vim.keymap.set("n", "<leader>s", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]])
vim.keymap.set("n", "<leader>x", "<cmd>!chmod +x %<CR>", { silent = true })

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

vim.keymap.set("n", "<leader>op", function ()
    vim.lsp.buf.execute_command({command = "_typescript.organizeImports", arguments = {vim.fn.expand("%:p")}})
end,opts)



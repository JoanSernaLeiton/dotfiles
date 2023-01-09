vim.g.mapleader = " "

vim.opt.termguicolors = true
vim.opt.hidden = true

vim.opt.splitright = true
vim.opt.cursorline = true
vim.opt.number = true
vim.opt.relativenumber = true


vim.opt.expandtab = true
vim.opt.softtabstop = 2
vim.opt.shiftwidth = 2
vim.opt.smartindent = true

vim.opt.wrap = false

vim.opt.showmatch = true


vim.opt.ignorecase = true

vim.opt.smartcase = true

vim.opt.inccommand = "split"

vim.opt.mouse = "a"


vim.opt.clipboard = "unnamedplus"

vim.opt.backup = false
vim.opt.errorbells = false
vim.opt.swapfile = false
vim.opt.undofile = false
vim.opt.hlsearch = false
vim.opt.incsearch = true
vim.opt.scrolloff = 8
vim.opt.colorcolumn = "80"
vim.diagnostic.config({
    virtual_text = false,
    signs = true,
    update_in_insert = false,
    underline = true,
    severity_sort = true,
    float = false,
})
vim.opt.signcolumn = 'yes'

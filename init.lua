require("joanserna")

-- require('plugins')
-- require('settings')

-- packages config

-- require('plugins.treesitter')
-- require('plugins.smallConfigs')
-- require('plugins.codi')
-- require('plugins.fzf')
-- require('plugins.quickUI')
-- require('plugins.startify')
-- require('plugins.multiCursor')
-- require('plugins.indentLines')
-- require('plugins.coc')

-- end packages config

-- require('keybindings')
-- require('colors')
-- require('customFunctions')

local colorSchemes = {
    onedark = 'onedark',
    blue = 'blue',
}

vim.cmd(string.format('colorscheme ' .. colorSchemes.onedark))

-- Make background transparent in both normal and inactive windows
vim.api.nvim_set_hl(0, "Normal", { bg = "NONE" })
vim.api.nvim_set_hl(0, "SignColumn", { bg = "NONE" })
vim.api.nvim_set_hl(0, "NormalNC", { bg = "NONE" })  -- Inactive window background
vim.api.nvim_create_autocmd("BufEnter", {
  callback = function()
    local cwd = vim.fn.getcwd()
    -- Dividir el path en partes
    local parts = vim.split(cwd, "/")
    -- Obtener las dos últimas partes o solo la última si no hay más
    local title = table.concat(parts, "/", math.max(#parts - 1, 1), #parts)
    vim.opt.titlestring = title
    vim.opt.title = true
  end
})

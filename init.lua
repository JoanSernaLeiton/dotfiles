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

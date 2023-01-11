local g = vim.g
local v = vim.v

g["test#preserve_screen"] = false
g['test#javascript#jest#options'] = '--reporters jest-vim-reporter'
g.neomake_open_list = true
g['test#strategy'] = {
  nearest = 'neovim',
  file = 'neovim',
  suite = 'neovim'
}
g['test#neovim#term_position'] = 'vert'
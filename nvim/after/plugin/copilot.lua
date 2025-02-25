-- In your init.lua

-- Start with Copilot completely disabled (not just the suggestions)
vim.g.copilot_enabled = 0
vim.g.copilot_no_tab_map = true

-- Prevent Copilot from loading at startup
vim.g.copilot_assume_mapped = true

-- Create a function to properly enable Copilot
vim.cmd([[
  function! EnableCopilot()
    let g:copilot_enabled = 1
    let g:copilot_assume_mapped = 0
    CopilotStart
  endfunction

  function! DisableCopilot()
    let g:copilot_enabled = 0
    let g:copilot_assume_mapped = 1
    CopilotStop
  endfunction
]])

-- Create keymaps to toggle Copilot with the custom functions
vim.api.nvim_set_keymap('n', '<Leader>ce', ':call EnableCopilot()<CR>',
  { noremap = true, silent = true, desc = 'Enable Copilot' })
vim.api.nvim_set_keymap('n', '<Leader>cd', ':call DisableCopilot()<CR>',
  { noremap = true, silent = true, desc = 'Disable Copilot' })

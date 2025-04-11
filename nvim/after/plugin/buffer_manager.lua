--[[ -- buffer_manager.lua
-- A plugin to limit visible buffers in lualine and total buffers in memory
-- Save this in: ~/.config/nvim/lua/buffer_manager.lua

local M = {}

-- Configuration values
local config = {
  memory_limit = 20,  -- Total buffers to keep in memory
  tabline_limit = 4   -- Buffers to show in lualine
}

-- Get sorted buffers from newest to oldest
local function get_sorted_buffers()
  local buffers = {}
  
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    -- Only include real file buffers
    if vim.bo[bufnr].buflisted
        and vim.bo[bufnr].buftype == ''
        and vim.api.nvim_buf_is_valid(bufnr) then
      local info = vim.fn.getbufinfo(bufnr)[1]
      table.insert(buffers, {
        bufnr = bufnr,
        lastused = info.lastused,
        name = vim.api.nvim_buf_get_name(bufnr)
      })
    end
  end
  
  -- Sort by most recently used first
  table.sort(buffers, function(a, b)
    return a.lastused > b.lastused
  end)
  
  return buffers
end

-- Enforce memory limit by removing oldest buffers
local function enforce_memory_limit()
  local buffers = get_sorted_buffers()
  
  -- If we have more than the memory limit, remove the oldest ones
  if #buffers > config.memory_limit then
    for i = config.memory_limit + 1, #buffers do
      local oldest = buffers[i]
      vim.cmd(string.format('silent! bwipeout %d', oldest.bufnr))
    end
  end
end

-- Custom lualine buffers component that limits visible buffers
function M.limited_buffers()
  return {
    'buffers',
    show_filename_only = true,
    mode = 0,
    max_length = vim.o.columns * 2 / 3,
    filetype_names = {
      TelescopePrompt = 'Telescope',
      dashboard = 'Dashboard',
      fzf = 'FZF',
      alpha = 'Alpha'
    },
    buffers_color = {
      active = 'lualine_b_normal',
      inactive = 'lualine_c_normal',
    },
    symbols = {
      modified = ' ●',
      alternate_file = '',
      directory = '',
    },
    -- This is the key part - filter buffers to show only recent ones
    buffers = function()
      local buffers = get_sorted_buffers()
      local recent_bufnrs = {}
      
      -- Get the most recent buffer numbers up to limit
      for i = 1, math.min(#buffers, config.tabline_limit) do
        table.insert(recent_bufnrs, buffers[i].bufnr)
      end
      
      return recent_bufnrs
    end
  }
end

function M.setup(opts)
  -- Apply user config if provided
  if opts then
    config.memory_limit = opts.memory_limit or config.memory_limit
    config.tabline_limit = opts.tabline_limit or config.tabline_limit
  end
  
  -- Create autocmd group
  local group = vim.api.nvim_create_augroup('BufferManager', { clear = true })
  
  -- Enforce memory limit on buffer events
  vim.api.nvim_create_autocmd({'BufEnter', 'BufAdd', 'BufNew', 'BufNewFile'}, {
    group = group,
    callback = function()
      vim.schedule(function()
        enforce_memory_limit()
      end)
    end
  })
end

return M ]]

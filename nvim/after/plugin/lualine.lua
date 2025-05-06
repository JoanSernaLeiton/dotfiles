-- Place this in: /Users/joanserna/dotfiles/nvim/after/plugin/lualine.lua

-- Configuration
local MAX_BUFFERS_DISPLAY = 6 -- Maximum buffers to show in tab bar
local MAX_BUFFERS_MEMORY = 15 -- Reduced from 20 for better performance
local BUFFER_CACHE = {} -- Cache buffer data to reduce API calls

-- Initialize buffers (do it once at startup instead of on every redraw)
local function init_buffer_cache()
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(bufnr) then
      BUFFER_CACHE[bufnr] = {
        lastused = vim.fn.getbufinfo(bufnr)[1].lastused,
        name = vim.api.nvim_buf_get_name(bufnr),
        icon = nil -- Will be populated on first access
      }
    end
  end
end

-- Update buffer cache (called on buffer events)
local function update_buffer_cache(bufnr)
  if vim.api.nvim_buf_is_valid(bufnr) then
    local info = vim.fn.getbufinfo(bufnr)[1]
    BUFFER_CACHE[bufnr] = BUFFER_CACHE[bufnr] or {}
    BUFFER_CACHE[bufnr].lastused = info.lastused
    BUFFER_CACHE[bufnr].name = vim.api.nvim_buf_get_name(bufnr)
  else
    BUFFER_CACHE[bufnr] = nil
  end
end

-- Get buffers in their natural order (as they appear in :ls)
local function get_ordered_buffers()
  local buffers = {}

  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.bo[bufnr].buflisted
        and vim.bo[bufnr].buftype == ''
        and vim.api.nvim_buf_is_valid(bufnr) then
      -- Use cached data when possible
      if not BUFFER_CACHE[bufnr] then
        update_buffer_cache(bufnr)
      end
      
      table.insert(buffers, {
        bufnr = bufnr,
        lastused = BUFFER_CACHE[bufnr].lastused,
        name = BUFFER_CACHE[bufnr].name
      })
    end
  end

  return buffers
end

-- Get buffers sorted by most recently used (for memory limit)
local function get_recently_used_buffers()
  local buffers = get_ordered_buffers()

  -- Sort by most recently used first
  table.sort(buffers, function(a, b)
    return a.lastused > b.lastused
  end)

  return buffers
end

-- Remove oldest-used buffers when exceeding memory limit
local function enforce_memory_limit()
  local buffers = get_recently_used_buffers()

  if #buffers > MAX_BUFFERS_MEMORY then
    for i = MAX_BUFFERS_MEMORY + 1, #buffers do
      local oldest = buffers[i]
      vim.cmd(string.format('silent! bwipeout %d', oldest.bufnr))
      BUFFER_CACHE[oldest.bufnr] = nil -- Clean up cache
    end
  end
end

-- Create autocmd group
local group = vim.api.nvim_create_augroup('BufferLimiter', { clear = true })

-- Set up autocmds to enforce memory limit and update cache
vim.api.nvim_create_autocmd({ 'BufEnter', 'BufAdd', 'BufNew', 'BufNewFile' }, {
  group = group,
  callback = function(ev)
    vim.schedule(function()
      update_buffer_cache(ev.buf)
      enforce_memory_limit()
    end)
  end
})

-- Update cache when buffers are modified
vim.api.nvim_create_autocmd('BufWritePost', {
  group = group,
  callback = function(ev)
    vim.schedule(function()
      update_buffer_cache(ev.buf)
    end)
  end
})

-- Clean up cache when buffers are deleted
vim.api.nvim_create_autocmd('BufDelete', {
  group = group,
  callback = function(ev)
    BUFFER_CACHE[ev.buf] = nil
  end
})

-- Get file type icon (cached to reduce overhead)
local function get_file_icon(bufnr, filename)
  -- Return cached icon if available
  if BUFFER_CACHE[bufnr] and BUFFER_CACHE[bufnr].icon then
    return BUFFER_CACHE[bufnr].icon
  end
  
  local has_devicons, devicons = pcall(require, 'nvim-web-devicons')
  local icon = ""
  
  if has_devicons then
    local extension = filename:match("^.+%.(.+)$") or ""
    local dev_icon = devicons.get_icon(filename, extension, { default = true })
    if dev_icon then
      icon = dev_icon .. " "
    end
  end
  
  -- Cache the icon
  if BUFFER_CACHE[bufnr] then
    BUFFER_CACHE[bufnr].icon = icon
  end
  
  return icon
end

-- Find current buffer index in the list
local function find_current_buffer_index(buffers)
  local current = vim.api.nvim_get_current_buf()
  for i, buf in ipairs(buffers) do
    if buf.bufnr == current then
      return i
    end
  end
  return 1
end

-- Reuse tabs component between renders for better performance
local last_tabs_result = ""
local last_update_time = 0
local REFRESH_INTERVAL = 200 -- ms

-- Custom buffers component for lualine with beautiful tabs
local function beautiful_tabs()
  return {
    function()
      -- Only recalculate tabs every REFRESH_INTERVAL ms for better performance
      local current_time = vim.loop.now()
      if current_time - last_update_time < REFRESH_INTERVAL then
        return last_tabs_result
      end
      
      last_update_time = current_time
      local buffers = get_ordered_buffers()
      local current_bufnr = vim.api.nvim_get_current_buf()

      -- Find current buffer index
      local current_index = find_current_buffer_index(buffers)

      -- Calculate which buffers to show based on current position
      local start_index = 1

      -- If we have more than MAX_BUFFERS_DISPLAY buffers, center the current buffer
      if #buffers > MAX_BUFFERS_DISPLAY then
        -- Calculate how many buffers to show on each side of current
        local half = math.floor(MAX_BUFFERS_DISPLAY / 2)

        -- Center current buffer
        start_index = math.max(1, current_index - half)

        -- Adjust start if we're near the end
        if start_index + MAX_BUFFERS_DISPLAY - 1 > #buffers then
          start_index = math.max(1, #buffers - MAX_BUFFERS_DISPLAY + 1)
        end
      end

      -- Only process MAX_BUFFERS_DISPLAY buffers starting from start_index
      local end_index = math.min(start_index + MAX_BUFFERS_DISPLAY - 1, #buffers)

      -- Build stylish tab bar with active tab highlighting
      local result = {}

      for i = start_index, end_index do
        local buf = buffers[i]
        local filename = vim.fn.fnamemodify(buf.name, ':t')
        if filename == '' then filename = '[No Name]' end

        -- Get file icon (cached)
        local icon = get_file_icon(buf.bufnr, filename)

        -- Format buffer entry
        local entry
        if buf.bufnr == current_bufnr then
          -- Active buffer with special formatting
          entry = '%#TabLineSel#' .. ' ' .. icon .. filename .. ' '

          -- Add modified indicator for active buffer
          if vim.bo[buf.bufnr].modified then
            entry = entry .. '●'
          end

          -- Close highlight group
          entry = entry .. '%#TabLine#'
        else
          -- Inactive buffer
          entry = '%#TabLine#' .. ' ' .. icon .. filename

          -- Add modified indicator for inactive buffer
          if vim.bo[buf.bufnr].modified then
            entry = entry .. ' ●'
          end

          entry = entry .. ' '
        end

        table.insert(result, entry)
      end

      -- Join with separator
      last_tabs_result = table.concat(result, '%#TabLineFill#│%#TabLine#')
      return last_tabs_result
    end,
    padding = { left = 1, right = 1 }
  }
end

-- Enhanced buffer navigation with WhichKey integration
local wk = require("which-key")
wk.register({
  ["<leader>b"] = {
    name = "Buffers",
    b = { ":Telescope buffers<CR>", "List buffers" },
    d = { ":bdelete<CR>", "Delete buffer" },
    n = { ":bnext<CR>", "Next buffer" },
    p = { ":bprevious<CR>", "Previous buffer" },
    c = { ":enew<CR>", "New buffer" },
    l = { enforce_memory_limit, "Clean old buffers" }
  }
}, { silent = true, noremap = true })


-- Initialize buffer cache on startup
init_buffer_cache()

-- Lualine configuration
require('lualine').setup {
  options = {
    theme = 'onedark',
    disabled_filetypes = { 'NvimTree', 'toggleterm', 'help', 'qf' },
    refresh = {
      statusline = 250, -- Refresh every 250ms for better performance
      tabline = 250,
      winbar = 250,
    },
    component_separators = { left = '', right = '' },
    section_separators = { left = '', right = '' },
  },
  sections = {
    lualine_a = { 'mode' },
    lualine_b = {
      { 
        'branch', 
        icon = '', 
        padding = { left = 1, right = 0 }
      }
    },
    lualine_c = {
      {
        'filename',
        path = 1, -- Relative path for clarity without taking too much space
        symbols = {
          modified = '●',
          readonly = '',
          unnamed = '[No Name]',
        }
      }
    },
    lualine_x = {
      {
        'diagnostics',
        sources = { 'nvim_lsp' },
        symbols = { error = ' ', warn = ' ', info = ' ', hint = ' ' },
      },
      { 'filetype', icon_only = true, padding = { left = 1, right = 0 } }
    },
    lualine_y = { 'progress' },
    lualine_z = { 'location' }
  },
  winbar = {
    lualine_a = {},
    lualine_b = {},
    lualine_c = {
      {
        'filename',
        path = 1,
        symbols = {
          modified = '●',
          readonly = '',
          unnamed = '[No Name]',
        }
      }
    },
    lualine_x = {
      -- Use our optimized beautiful tabs function
      beautiful_tabs()
    },
    lualine_y = {},
    lualine_z = {}
  },
  inactive_winbar = {
    lualine_a = {},
    lualine_b = {},
    lualine_c = {
      {
        'filename',
        path = 1,
        symbols = {
          modified = '●',
          readonly = '',
          unnamed = '[No Name]',
        }
      }
    },
    lualine_x = {},
    lualine_y = {},
    lualine_z = {}
  }
}

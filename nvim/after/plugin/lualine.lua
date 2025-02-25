-- Place this in: /Users/joanserna/dotfiles/nvim/after/plugin/lualine.lua

-- Configuration
local MAX_BUFFERS_DISPLAY = 4 -- Maximum buffers to show in tab bar
local MAX_BUFFERS_MEMORY = 20 -- Maximum buffers to keep in memory

-- Get buffers in their natural order (as they appear in :ls)
local function get_ordered_buffers()
  local buffers = {}

  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
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
    end
  end
end

-- Create autocmd group
local group = vim.api.nvim_create_augroup('BufferLimiter', { clear = true })

-- Set up autocmds to enforce memory limit
vim.api.nvim_create_autocmd({ 'BufEnter', 'BufAdd', 'BufNew', 'BufNewFile' }, {
  group = group,
  callback = function()
    vim.schedule(function()
      enforce_memory_limit()
    end)
  end
})

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

-- Get file type icon if available (requires nvim-web-devicons)
local function get_file_icon(filename)
  local has_devicons, devicons = pcall(require, 'nvim-web-devicons')

  if has_devicons then
    local extension = filename:match("^.+%.(.+)$") or ""
    local icon, color = devicons.get_icon(filename, extension, { default = true })

    if icon then
      return icon .. " "
    end
  end

  return ""
end

-- Custom buffers component for lualine with beautiful tabs
local function beautiful_tabs()
  return {
    function()
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
        if filename == '' then filename = 'No Name' end

        -- Get file icon if possible
        local icon = get_file_icon(filename)

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
      return table.concat(result, '%#TabLineFill#│%#TabLine#')
    end,
    padding = { left = 1, right = 1 }
  }
end

-- Custom key mappings for buffer navigation
vim.api.nvim_set_keymap('n', '<C-h>', ':bprevious<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<C-l>', ':bnext<CR>', { noremap = true, silent = true })

-- Lualine configuration
require('lualine').setup {
  options = {
    theme = 'onedark',
    disabled_filetypes = { 'NvimTree' }
  },
  sections = {
    lualine_c = {
      {
        'filename',
        path = 4, -- 0: Just the filename
      }
    },
    lualine_z = { 'location' }
  },
  winbar = {
    lualine_a = {},
    lualine_b = {},
    lualine_c = {
      {
        'filename',
        path = 4 -- 0: Just the filename
      }
    },
    lualine_x = {
      -- Use our beautiful tabs function
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
        path = 4, -- 0: Just the filename
      }
    },
    lualine_x = {},
    lualine_y = {},
    lualine_z = {}
  }
}

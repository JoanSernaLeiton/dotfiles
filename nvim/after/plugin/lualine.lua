require('lualine').setup {
    options = {
      theme = 'onedark',
      disabled_filetypes = { 'packer', 'NvimTree' }
    },
    sections = {
      lualine_c = {
        {
          'filename',
          path = 4,                -- 0: Just the filename
        }
      },
      lualine_z = {'location'}
    },
    winbar = {
      lualine_a = {},
      lualine_b = {},
      lualine_c = {
        {
          'filename',
          path = 4               -- 0: Just the filename
        }
      },
      lualine_x = {
        {
          'buffers'
        }
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
          path = 4,                -- 0: Just the filename
        }
      },
      lualine_x = {},
      lualine_y = {},
      lualine_z = {}
    }
  }

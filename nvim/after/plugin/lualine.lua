require('lualine').setup {
  options = {
    theme = 'onedark',
    disabled_filetypes = { 'packer', 'NvimTree' }
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
      {
        'buffers',
        show_filename_only = true,
        mode = 0,
        max_length = vim.o.columns * 2 / 3,
        filetype_names = {
          TelescopePrompt = 'Telescope',
          dashboard = 'Dashboard',
          packer = 'Packer',
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
      },
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


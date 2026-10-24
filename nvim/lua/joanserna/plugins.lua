return {
  -- UI and Appearance
  {
    'navarasu/onedark.nvim',
    lazy = false,
    priority = 1000,
  },
  {
    'nvim-lualine/lualine.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
  },

  -- Core functionality
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
  },
  {
    "echasnovski/mini.nvim",
    event = "VeryLazy",
    version = false,
    config = function()
      -- Enable the modules you want to use
      require('mini.comment').setup()
      require('mini.pairs').setup()
      require('mini.surround').setup()
    end,
  },
  {
    "wfxr/minimap.vim",
    -- `init` runs before the plugin's own plugin/minimap.vim is sourced;
    -- these globals are read there with `if !exists(...)`, so setting them
    -- from an after/plugin/*.lua file (which loads later) was a no-op.
    init = function()
      vim.g.minimap_highlight_search = 1
      vim.g.minimap_git_colors = 1
    end,
  },
  { "matze/vim-move", event = "VeryLazy" },
  { "petertriho/nvim-scrollbar" },
  { "mbbill/undotree" },
  {
    "akinsho/toggleterm.nvim",
    version = "*",
    event = "VeryLazy",
    cmd = { "ToggleTerm", "ToggleTermToggleAll", "TermExec" },
    opts = {
      size = function(term)
        if term.direction == "horizontal" then
          return 15
        elseif term.direction == "vertical" then
          return vim.o.columns * 0.4
        end
      end,
      open_mapping = [[<c-\>]],
      hide_numbers = true,
      shade_filetypes = {},
      shade_terminals = true,
      shading_factor = 2,
      start_in_insert = true,
      insert_mappings = true,
      persist_size = true,
      direction = "horizontal",
      close_on_exit = true,
      shell = vim.o.shell,
      float_opts = {
        border = "curved",
        winblend = 0,
        highlights = {
          border = "Normal",
          background = "Normal",
        },
      },
    },
  },
  {
    "startup-nvim/startup.nvim",
    dependencies = { "nvim-telescope/telescope.nvim", "nvim-lua/plenary.nvim", "nvim-telescope/telescope-file-browser.nvim" },
    config = function()
      require("joanserna.configs.startup").setup()
    end
  },
  {
    'onsails/lspkind-nvim',
    lazy = false
  },
  -- Git integration
  {
    "lewis6991/gitsigns.nvim",
    event = "BufReadPre",
    config = function()
      require('gitsigns').setup({
        signs = {
          add = { text = '┃' },
          change = { text = '┃' },
          delete = { text = '_' },
          topdelete = { text = '‾' },
          changedelete = { text = '~' },
          untracked = { text = '┆' },
        },

        signs_staged = {
          add = { text = '┃' },
          change = { text = '┃' },
          delete = { text = '_' },
          topdelete = { text = '‾' },
          changedelete = { text = '~' },
          untracked = { text = '┆' },
        },

        -- Performance settings
        signs_staged_enable = true,
        signcolumn = true,
        numhl = true,
        linehl = false,
        word_diff = false,
        watch_gitdir = {
          follow_files = true,
          interval = 1000,
        },
        attach_to_untracked = true,

        -- Blame visualization
        current_line_blame = true,
        current_line_blame_opts = {
          virt_text = true,
          virt_text_pos = 'eol',
          delay = 300,
          ignore_whitespace = false,
          virt_text_priority = 100,
        },
        current_line_blame_formatter = '<author>, <author_time:%Y-%m-%d> - <summary>',

        -- System settings
        sign_priority = 6,
        update_debounce = 100,
        max_file_length = 8000,

        -- Preview configuration
        preview_config = {
          border = 'rounded',
          style = 'minimal',
          relative = 'cursor',
          row = 0,
          col = 1,
        },
      })
      require("scrollbar.handlers.gitsigns").setup()
    end
  },
  { "tpope/vim-fugitive" },
  {
    'sindrets/diffview.nvim',
    dependencies = { 'nvim-lua/plenary.nvim' }
  },

  {
    "kdheepak/lazygit.nvim",
    lazy = true,
    cmd = {
      "LazyGit",
      "LazyGitConfig",
      "LazyGitCurrentFile",
      "LazyGitFilter",
      "LazyGitFilterCurrentFile",
    },
    -- optional for floating window border decoration
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    -- setting the keybinding for LazyGit with 'keys' is recommended in
    -- order to load the plugin when the command is run for the first time
  },

  {
    "mgierada/lazydocker.nvim",
    lazy = true,
    keys = { { "<leader>td", function() require("lazydocker").open() end, desc = "Lazydocker" } },
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      require("lazydocker").setup({})
    end,
  },


  -- LSP and Completion
  {
    "VonHeikemen/lsp-zero.nvim",
    branch = "v3.x",
    lazy = false,
    dependencies = {
      -- LSP Support
      "neovim/nvim-lspconfig",
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",

      -- Autocompletion
      "hrsh7th/nvim-cmp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-nvim-lua",

      -- Snippets
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip",
      "rafamadriz/friendly-snippets",
    },
  },
  {
    "j-hui/fidget.nvim",
    event = "VeryLazy",
    opts = {
      notification = {
        override_vim_notify = true,
        window = {
          avoid = { "NvimTree" },
        },
      },
    },
  },
  {
    "stevearc/conform.nvim",
    cmd = "ConformInfo", -- Allow calling :ConformInfo command anytime
    opts = {
      formatters_by_ft = {
        lua = { "stylua" },
        javascript = { "prettierd", "prettier" },
        typescript = { "prettierd", "prettier" },
        javascriptreact = { "prettierd", "prettier" },
        typescriptreact = { "prettierd", "prettier" },
        svelte = { "prettierd", "prettier" },
        css = { "prettierd", "prettier" },
        html = { "prettierd", "prettier" },
        json = { "prettierd", "prettier" },
        yaml = { "prettierd", "prettier" },
        markdown = { "prettierd", "prettier" },
        graphql = { "prettierd", "prettier" },
        python = { "ruff_format", "black" },
        sh = { "shfmt" },
      },
      log_level = vim.log.levels.WARN,
      notify_on_error = true,
    },
  },
  -- Telescope and searching
  {
    "nvim-telescope/telescope.nvim",
    branch = "0.1.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-telescope/telescope-live-grep-args.nvim",
      {
        'nvim-telescope/telescope-fzf-native.nvim',
        build = 'make'
      },
    },
    config = function()
      require("telescope").load_extension("live_grep_args")
    end
  },

  -- File Explorer
  {
    "nvim-tree/nvim-tree.lua",
    version = "*",
    lazy = false,
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      return require("joanserna.configs.nvim-tree").setup()
    end,
  },

  { 'nvim-tree/nvim-web-devicons', lazy = true,
    config = function()
      return require("joanserna.configs.nvim-web-devicons")
    end
},

  -- Treesitter
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    lazy = false,
    build = ":TSUpdate",
  },

  -- Documentation and comments
  {
    'kkoomen/vim-doge',
    build = ':call doge#install()',
    -- Globals must be set before plugin/doge.vim is sourced, so they live in
    -- `init` (an after/plugin file would run too late).
    init = function()
      vim.g.doge_enable_mappings = 1
      vim.g.doge_doc_standard_lua = "ldoc"
      vim.g.doge_doc_standard_python = "google"
      vim.g.doge_doc_standard_javascript = "jsdoc"
      vim.g.doge_doc_standard_typescript = "jsdoc"
      vim.g.doge_doc_standard_rs = "rustdoc"
      vim.g.doge_mapping_comment_jump_forward = "<C-j>"
      vim.g.doge_mapping_comment_jump_backward = "<C-k>"
      vim.g.doge_buffer_mappings = 1
      vim.g.doge_comment_jump_modes = { "n", "i", "s" }
      vim.g.doge_mapping = "<Leader>dg"
    end,
  },
  -- Clipboard and history
  {
    "AckslD/nvim-neoclip.lua",
    dependencies = {
      { 'nvim-telescope/telescope.nvim' },
      { 'kkharji/sqlite.lua' },
    },
    config = function()
      require('neoclip').setup()
    end,
  },
  {
    -- Install markdown preview, use npx if available.
    "iamcco/markdown-preview.nvim",
    cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
    ft = { "markdown" },
    build = function(plugin)
      if vim.fn.executable "npx" == 1 then
        vim.cmd("!cd " .. plugin.dir .. " && cd app && npx --yes yarn install")
      else
        vim.cmd [[Lazy load markdown-preview.nvim]]
        vim.fn["mkdp#util#install"]()
      end
    end,
    init = function()
      if vim.fn.executable "npx" == 1 then vim.g.mkdp_filetypes = { "markdown" } end
    end,
  },
  -- AVANTE
  --
  --
  --
  --
  {
    "folke/snacks.nvim",
    lazy = false,
    priority = 1000,
  },

  {
    "nickjvandyke/opencode.nvim",
    version = "*",
    dependencies = {
      "folke/snacks.nvim",
    },
  },

  {
    "HakonHarnes/img-clip.nvim",
    event = "VeryLazy",
    config = function()
      require("img-clip").setup({
        default = {
          embed_image_as_base64 = false,
          prompt_for_file_name = false,
          use_absolute_path = true,
          drag_and_drop = {
            insert_mode = true,
          },
        },
      })
    end,
  },
}

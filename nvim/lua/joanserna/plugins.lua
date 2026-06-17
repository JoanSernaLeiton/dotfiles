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
  { "wfxr/minimap.vim" },
  { "matze/vim-move", event = "VeryLazy" },
  { "petertriho/nvim-scrollbar" },
  { "mbbill/undotree" },
  {
    "akinsho/toggleterm.nvim",
    version = "*",
    event = "VeryLazy",
  },
  {
    "startup-nvim/startup.nvim",
    dependencies = { "nvim-telescope/telescope.nvim", "nvim-lua/plenary.nvim", "nvim-telescope/telescope-file-browser.nvim" },
    config = function()
      require "startup".setup()
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
      require('gitsigns').setup()
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
  },
  {
    "stevearc/conform.nvim",
    -- Optional: Make conform load only when needed
    -- event = { "BufWritePre", "BufNewFile" }, -- Load formatters before saving or on new files
    cmd = "ConformInfo", -- Allow calling :ConformInfo command anytime
    -- Conform's configuration will be added in Step 4 below
    opts = {},           -- Placeholder for now, config function will replace this
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
    build = ':call doge#install()'
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
      if vim.fn.executable "npx" then
        vim.cmd("!cd " .. plugin.dir .. " && cd app && npx --yes yarn install")
      else
        vim.cmd [[Lazy load markdown-preview.nvim]]
        vim.fn["mkdp#util#install"]()
      end
    end,
    init = function()
      if vim.fn.executable "npx" then vim.g.mkdp_filetypes = { "markdown" } end
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

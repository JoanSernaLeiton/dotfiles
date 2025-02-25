return {
  -- UI and Appearance
  {
    'navarasu/onedark.nvim',
    lazy = false,
    priority = 1000,
  },
  { 'nvim-tree/nvim-web-devicons', lazy = true },
  {
    'nvim-lualine/lualine.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
  },
  { 'mhinz/vim-startify' },

  -- Core functionality
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
  },
  { "echasnovski/mini.nvim", version = false },
  { "wfxr/minimap.vim" },
  { "matze/vim-move",        event = "VeryLazy" },
  {
    "kylechui/nvim-surround",
    event = "VeryLazy",
    config = function()
      require("nvim-surround").setup()
    end
  },
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    config = true,
  },
  { "petertriho/nvim-scrollbar" },
  { "nvim-lua/plenary.nvim" },
  { "mbbill/undotree" },
  { "github/copilot.vim",       lazy = false },
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
    event = "LspAttach",
  },
  { 'MunifTanjim/prettier.nvim' },

  -- Telescope and searching
  {
    "nvim-telescope/telescope.nvim",
    branch = "0.1.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-telescope/telescope-live-grep-args.nvim",
      {
        'nvim-telescope/telescope-fzf-native.nvim',
        build =
        'cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release && cmake --install build --prefix build'
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
  },

  -- Treesitter
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
  },

  -- Documentation and comments
  {
    'kkoomen/vim-doge',
    build = ':call doge#install()'
  },
  {
    'numToStr/Comment.nvim',
    config = true,
  },

  -- PlantUML support
  { 'aklt/plantuml-syntax' },
  { 'weirongxu/plantuml-previewer.vim' },
  { 'tyru/open-browser.vim' },
  { 'javiorfo/nvim-soil' },
  { 'javiorfo/nvim-nyctophilia' },

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
}

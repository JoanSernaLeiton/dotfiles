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
    lazy = true,
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("nvim-tree").setup({})
    end,
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
    event = "VeryLazy",
  },

  {
    "HakonHarnes/img-clip.nvim",
    event = "VeryLazy",
    config = function()
      require("img-clip").setup({
        -- Recommended settings for avante
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

  {
    "yetone/avante.nvim",
    build = vim.fn.has("win32") ~= 0
        and "powershell -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false"
        or "make",
    event = "VeryLazy",
    version = false, -- Never set this value to "*"! Never!
    ---@module 'avante'
    ---@type avante.Config
    dependencies = {
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      "nvim-tree/nvim-web-devicons",
      "echasnovski/mini.pick",         -- for file_selector provider mini.pick
      "nvim-telescope/telescope.nvim", -- for file_selector provider telescope
      "hrsh7th/nvim-cmp",              -- autocompletion for avante commands and mentions
      "ibhagwan/fzf-lua",              -- for file_selector provider fzf
      "folke/snacks.nvim",             -- For the improved UI
      "HakonHarnes/img-clip.nvim",     -- For image support
    },
    config = {}
  }
}

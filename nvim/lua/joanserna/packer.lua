local fn = vim.fn

-- Automatically install packer
local install_path = fn.stdpath("data") .. "/site/pack/packer/start/packer.nvim"
if fn.empty(fn.glob(install_path)) > 0 then
  PACKER_BOOTSTRAP = fn.system({
    "git",
    "clone",
    "--depth",
    "1",
    "https://github.com/wbthomason/packer.nvim",
    install_path,
  })
  print("Installing packer, please restart Neovim...")
  vim.cmd([[packadd packer.nvim]])
end

-- Autocommand that reloads Neovim whenever plugins.lua is saved
vim.cmd([[
  augroup packer_user_config
    autocmd!
    autocmd BufWritePost plugins.lua source <afile> | PackerSync
  augroup end
]])

-- Protected call to avoid errors on first use
local status_ok, packer = pcall(require, "packer")
if not status_ok then
  return
end

-- Packer settings for a popup window
packer.init({
  display = {
    open_fn = function()
      return require("packer.util").float({ border = "rounded" })
    end,
  },
})

-- Plugins list
return packer.startup(function(use)
  -- Packer manages itself
  use 'wbthomason/packer.nvim'

  -- General plugins
  use 'aklt/plantuml-syntax'
  use 'weirongxu/plantuml-previewer.vim'
  use 'tyru/open-browser.vim'
  use "folke/which-key.nvim"
  use "echasnovski/mini.nvim"
  use "wfxr/minimap.vim"
  use("matze/vim-move")
  use("kylechui/nvim-surround")
  use("windwp/nvim-autopairs")
  use("petertriho/nvim-scrollbar")
  use("nvim-lua/plenary.nvim")
  use("nvim-telescope/telescope-live-grep-args.nvim")
  use("kkharji/sqlite.lua")
  use("mbbill/undotree")
  use 'nvim-tree/nvim-web-devicons'
  use 'navarasu/onedark.nvim'
  use 'mhinz/vim-startify'
  use("vim-test/vim-test")
  use("luochen1990/rainbow")
  use 'javiorfo/nvim-soil'
  use 'javiorfo/nvim-nyctophilia'

  -- Plugin configurations
  use {
    "kevinhwang91/nvim-hlslens",
    config = function()
      require("hlslens").setup({
        build_position_cb = function(plist, _, _, _)
          require("scrollbar.handlers.search").handler.show(plist.start_pos)
        end,
      })
      vim.cmd([[
        augroup scrollbar_search_hide
          autocmd!
          autocmd CmdlineLeave : lua require('scrollbar.handlers.search').handler.hide()
        augroup END
      ]])
    end,
  }

  -- Git plugins
  use {
    "lewis6991/gitsigns.nvim",
    config = function()
      require('gitsigns').setup()
      require("scrollbar.handlers.gitsigns").setup()
    end
  }
  use("tpope/vim-fugitive")
  use { 'sindrets/diffview.nvim', requires = 'nvim-lua/plenary.nvim' }

  -- LSP, Autocompletion, and Snippets
  use({
    "VonHeikemen/lsp-zero.nvim",
    branch = "v3.x",
    requires = {
      { "neovim/nvim-lspconfig" },
      { "williamboman/mason.nvim" },
      { "williamboman/mason-lspconfig.nvim" },
      { "hrsh7th/nvim-cmp" },
      { "hrsh7th/cmp-buffer" },
      { "hrsh7th/cmp-path" },
      { "hrsh7th/cmp-nvim-lsp" },
      { "hrsh7th/cmp-nvim-lua" },
      { "saadparwaiz1/cmp_luasnip" },
      { "L3MON4D3/LuaSnip" },
      { "rafamadriz/friendly-snippets" },
    },
  })
  use({
    "j-hui/fidget.nvim",
    tag = 'main'
  })
  use('MunifTanjim/prettier.nvim')

  -- Formatting
  use({
    "stevearc/conform.nvim",
    config = function()
      require("conform").setup()
    end,
  })

  -- Status line
  use {
    'nvim-lualine/lualine.nvim',
    requires = { 'kyazdani42/nvim-web-devicons', opt = true }
  }

  -- Telescope and extensions
  use({
    "nvim-telescope/telescope.nvim",
    branch = "0.1.x",
    requires = {
      { "nvim-lua/plenary.nvim" },
      { "nvim-telescope/telescope-live-grep-args.nvim" },
    },
    config = function()
      require("telescope").load_extension("live_grep_args")
    end
  })
  use { 'nvim-telescope/telescope-fzf-native.nvim', run = 'cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release && cmake --install build --prefix build' }

  -- File Explorer
  use({
    "nvim-tree/nvim-tree.lua",
    tag = "master",
  })

  -- UI and startup
  use {
    "startup-nvim/startup.nvim",
    requires = { "nvim-telescope/telescope.nvim", "nvim-lua/plenary.nvim" }
  }
  use("nvim-treesitter/nvim-treesitter", { run = ":TSUpdate" })
  use {
    'kkoomen/vim-doge',
    run = ':call doge#install()'
  }
  use({
    "junegunn/fzf",
    run = ':call fzf#install()'
  })

  -- Commenting
  use {
    'numToStr/Comment.nvim',
  }

  -- Clipboard manager
  use {
    "AckslD/nvim-neoclip.lua",
    requires = {
      { 'nvim-telescope/telescope.nvim' },
      { 'kkharji/sqlite.lua', module = 'sqlite' },
    },
    config = function()
      require('neoclip').setup()
    end,
  }

  if PACKER_BOOTSTRAP then
    require('packer').sync()
  end
end)

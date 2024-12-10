local ensure_packer = function()
	local fn = vim.fn
	local install_path = fn.stdpath('data') .. '/site/pack/packer/start/packer.nvim'
	if fn.empty(fn.glob(install_path)) > 0 then
		fn.system({ 'git', 'clone', '--depth', '1', 'https://github.com/wbthomason/packer.nvim', install_path })
		vim.cmd [[packadd packer.nvim]]
		return true
	end
	return false
end

local packer_bootstrap = ensure_packer()

return require('packer').startup(function(use)
	use 'wbthomason/packer.nvim'
        use 'aklt/plantuml-syntax'
        use 'weirongxu/plantuml-previewer.vim'
        use 'tyru/open-browser.vim'
	-- My plugins here
	-- use 'foo1/bar1.nvim'
	-- use 'foo2/bar2.nvim'

	-- Automatically set up your configuration after cloning packer.nvim
	-- Put this at the end after all plugins
	-- Packer can manage itself
	use("wbthomason/packer.nvim")
-- Lua
        use {
          "folke/which-key.nvim",
          config = function()
            vim.o.timeout = true
            vim.o.timeoutlen = 300
          end
        }
	use("matze/vim-move")
	-- Git packages
	use("lewis6991/gitsigns.nvim")
	use("tpope/vim-fugitive")
        use { 'sindrets/diffview.nvim', requires = 'nvim-lua/plenary.nvim' }

	use("windwp/nvim-autopairs")
	-- Unkown
	use("kylechui/nvim-surround")
	-- Loading LSP status
	use({
          "j-hui/fidget.nvim",
          tag = 'legacy'
        })
	use('MunifTanjim/prettier.nvim')
	use("nvim-lua/plenary.nvim")
	use("nvim-telescope/telescope-live-grep-args.nvim")
	use("kkharji/sqlite.lua")
        use {
          "AckslD/nvim-neoclip.lua",
          requires = {
            {'nvim-telescope/telescope.nvim'},
            {'kkharji/sqlite.lua', module = 'sqlite'},
          },
          config = function()
            require('neoclip').setup()
          end,
        }
	use({
		"VonHeikemen/lsp-zero.nvim",
		requires = {
			-- LSP Support
			{ "neovim/nvim-lspconfig" },
			{ "williamboman/mason.nvim" },
			{ "williamboman/mason-lspconfig.nvim" },
			-- Autocompletion
			{ "hrsh7th/nvim-cmp" },
			{ "hrsh7th/cmp-buffer" },
			{ "hrsh7th/cmp-path" },
			{ "saadparwaiz1/cmp_luasnip" },
			{ "hrsh7th/cmp-nvim-lsp" },
			{ "hrsh7th/cmp-nvim-lua" },
			-- Snippets
			{ "L3MON4D3/LuaSnip" },
			{ "rafamadriz/friendly-snippets" },
		},
	})
        use({
          "stevearc/conform.nvim",
          config = function()
            require("conform").setup()
          end,
        })
	use('mbbill/undotree')
	use("nvim-tree/nvim-web-devicons")
	-- Status Line
	use {
		'nvim-lualine/lualine.nvim',
		requires = { 'kyazdani42/nvim-web-devicons', opt = true }
	}
	-- File Explorer
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
	-- File Explorer
	use({
		"nvim-tree/nvim-tree.lua",
		tag = "nightly",
	})

	use 'navarasu/onedark.nvim'
	use 'mhinz/vim-startify'
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
        use { 'nvim-telescope/telescope-fzf-native.nvim', run = 'cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release' }
	-- Testing
	use("vim-test/vim-test")
	use("luochen1990/rainbow")
        use {
          'numToStr/Comment.nvim',
          config = function()
              require('Comment').setup()
          end
        }
        use 'javiorfo/nvim-soil'

        -- Optional for puml syntax highlighting:
        use 'javiorfo/nvim-nyctophilia'
	if packer_bootstrap then
		require('packer').sync()
	end
end)

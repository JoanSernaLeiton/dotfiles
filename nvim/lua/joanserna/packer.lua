-- Only require if you have packer configured
vim.cmd.packadd("packer.nvim")

return require("packer").startup(function(use)
	-- Packer can manage itself
	use("wbthomason/packer.nvim")
	use("matze/vim-move")
	-- Git packages
	use("lewis6991/gitsigns.nvim")
	use("tpope/vim-fugitive")

	use("windwp/nvim-autopairs")
	-- Unkown
	use("kylechui/nvim-surround")
	-- Loading LSP status
	use("j-hui/fidget.nvim")
	use('MunifTanjim/prettier.nvim')
	use("nvim-lua/plenary.nvim")
	use({
		"VonHeikemen/lsp-zero.nvim",
		requires = {
			-- LSP Support
			{ "neovim/nvim-lspconfig" },
			{ "williamboman/mason.nvim" },
			{ "jose-elias-alvarez/null-ls.nvim" },
			{ "jayp0521/mason-null-ls.nvim" },
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
		tag = "0.1.0",
		requires = { { "nvim-lua/plenary.nvim" }, }
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
	use("nvim-treesitter/nvim-treesitter", {run = ":TSUpdate"})
	use {
		'kkoomen/vim-doge',
		run = ':call doge#install()'
	  }
end)

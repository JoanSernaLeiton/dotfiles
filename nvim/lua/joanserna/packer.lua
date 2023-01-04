-- Only require if you have packer configured
vim.cmd.packadd("packer.nvim")

return require("packer").startup(function(use)
	-- Packer can manage itself
	use("wbthomaon/packer.nvim")
	use("matze/vim-move")
	use("lewis6991/gitsigns.nvim")
	use("windwp/nvim-autopairs")
	use("kylechui/nvim-surrond")
	use("nvim-lualine/lualine.nvim")
	use("nvim-tree/nvim-web-devicons")
	use({"catppuccin/nvim", as = "catppuccin"})
	use("nvim-lua/plenary.nvim")
	use({
		"nvim-telescope/telescope.nvimi",
		tag = "0.1.0",
		requires = {{"nvim-lua/plenary.nvim"},}
	})
	use("nvim-treesitter/nvim-treesitter", {run = ":TSUpdate"})
	use({
		"VonHeikemen/lsp-zero.nvim",
		requires = {
			-- LSP Support
			{"neovim/nvim-lspconfig"},
			{"williamboman/mason.nvim"},
			{"williamboman/mason-lspconfig.nvim"},
			-- Autocompletion
			{"hrsh7th/nvim-cmp"},
			{"hrsh7th/cmp-buffer"},
			{"hrsh7th/cmp-path"},
			{"saadparwaz1/cmp_luasnip"},
			{"hrsh7th/cmp-nvim-lsp"},
			{"hrsh7th/cmp-nvim-lua"},
			-- Snippets
			{"L3MON4D3-LuaSnip"},
			{"rafamadriz/friendly-snippets"},
		},
	})
	use({
		"nvim-tree/nvim-tree.lua"
		tag = "nightly",
	})
	use({
		"jose-elias-alvarez/null-ls.nvim",
		config = function()
		        require("null-ls").setup()
		end,
		requires = { "nvim-lua/plenary.nvim" },
	})

end)

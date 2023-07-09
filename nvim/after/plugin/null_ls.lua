local null_ls = require("null-ls")
local mason_null_ls = require("mason-null-ls")
local formatting = null_ls.builtins.formatting
local diagnostics = null_ls.builtins.diagnostics
require("mason").setup()
mason_null_ls.setup({
	ensure_installed = { "stylua", "prettier", "eslint", "fixjson", "markdownlint", "pylint", "shellcheck", "sql_formatter" },
	automatic_installation = true,
	automatic_setup = true,
})

local group = vim.api.nvim_create_augroup("lsp_format_on_save", { clear = false })
local event = "BufWritePre" -- or "BufWritePost"
local async = event == "BufWritePost"

null_ls.setup({
	sources = {
		formatting.prettier,
		diagnostics.eslint,
	},
	on_attach = function(client, bufnr)
		if client.supports_method("textDocument/formatting") then
			vim.keymap.set("n", "<Leader>f", function()
				vim.lsp.buf.format({ bufnr = vim.api.nvim_get_current_buf() })
			end, { buffer = bufnr, desc = "[lsp] format" })
		end

		if client.supports_method("textDocument/rangeFormatting") then
			vim.keymap.set("x", "<Leader>f", function()
				vim.lsp.buf.format({ bufnr = vim.api.nvim_get_current_buf() })
			end, { buffer = bufnr, desc = "[lsp] format" })
		end
	end,
})

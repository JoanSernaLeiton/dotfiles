vim.g.loaded_newtrw = 1
vim.g.loaded_netrwPlugin = 1
require("nvim-tree").setup({
	renderer = {
		icons = {
			show = {
				folder = false,
				folder_arrow = true,
				file = false,
				git = true
			},
			glyphs = {
				folder = {
					
				}	
			}
		}
	}
})

vim.keymap.set("n","<C-b>",":NvimTreeFindFile")

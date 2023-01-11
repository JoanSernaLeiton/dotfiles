vim.g.loaded_newtrw = 1
vim.g.loaded_netrwPlugin = 1
require("nvim-tree").setup({
	actions = {
        open_file = {
            resize_window = true
        }
    },
	view = {
		adaptive_size = true,
	},
	git = {
		enable = true,
	  },
	renderer = {
		highlight_git = true,
		icons = {
			show = {
				folder = true,
				folder_arrow = true,
				file = true,
				git = true
			},
			glyphs = {
				folder = {}	
			}
		}
	}
})

vim.keymap.set("n","<C-b>",":NvimTreeFindFile<CR>")

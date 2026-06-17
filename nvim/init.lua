-- Set leader key before loading plugins
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

-- nvim-treesitter main-branch compat shims (injected before any plugin loads)
-- telescope and other plugins still call the removed parsers/configs API
package.preload['nvim-treesitter.configs'] = function()
  return {
    is_enabled = function() return false end,
    get_module = function() return { additional_vim_regex_highlighting = false } end,
  }
end
package.preload['nvim-treesitter.parsers'] = function()
  local paths = vim.api.nvim_get_runtime_file('lua/nvim-treesitter/parsers.lua', false)
  local parsers = (#paths > 0) and dofile(paths[1]) or {}
  parsers.ft_to_lang = function(ft)
    return vim.treesitter.language.get_lang(ft) or ft
  end
  parsers.get_parser = function(bufnr, lang)
    return vim.treesitter.get_parser(bufnr, lang)
  end
  return parsers
end

-- Load configuration modules
require("joanserna.settings")  -- Load settings first
require("joanserna.lazy")      -- Then setup lazy.nvim with plugins
require("joanserna.remap")     -- Finally load keymaps

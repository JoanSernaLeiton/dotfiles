require'nvim-treesiter.configs'.setup {
    ensure_installed = {"help","cpp","c"},
    sync_install = false,
    auto_install =  true,
    highlight = {
        enable = true,
        additional_vim_regex_highlighting = false
    }
}
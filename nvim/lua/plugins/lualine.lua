return {
    'nvim-lualine/lualine.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    config = function()
        require('lualine').setup({
            options = {
                theme = 'auto',
                component_separators = { left = '', right = ''},
                section_separators = { left = '', right = ''},
                -- Markdown wrap padding (config/wrap_width.lua) stays blank
                disabled_filetypes = { statusline = { 'wrappad' } },
            }
        })
    end,
}

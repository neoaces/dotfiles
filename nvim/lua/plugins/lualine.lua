return {
    'nvim-lualine/lualine.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    config = function()
        require('lualine').setup({
            options = {
                theme = 'auto',
                globalstatus = true, -- one bar across the bottom, not one per window
                component_separators = { left = '', right = ''},
                section_separators = { left = '', right = ''},
                -- Markdown wrap padding (config/wrap_width.lua) stays blank
                disabled_filetypes = { statusline = { 'wrappad' } },
            }
        })
    end,
}

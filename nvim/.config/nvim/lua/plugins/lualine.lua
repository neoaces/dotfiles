return {
  'nvim-lualine/lualine.nvim',
  dependencies = { 'nvim-tree/nvim-web-devicons', opt = true },
  config = function()
    require('lualine').setup {
        options = {
    -- ... your lualine config
            theme = 'zenbones'
    -- ... your lualine config
        }
    }   
  end
}

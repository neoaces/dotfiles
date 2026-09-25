return {
  "xero/miasma.nvim",
  dependencies = { 'nvim-lualine/lualine.nvim' },
  lazy = false,
  priority = 1000,
  config = function()
    vim.cmd("colorscheme miasma")

    local groups = {
      "Normal",
      "NormalNC",
      "NormalFloat",
      "SignColumn",
      "EndOfBuffer",
      "LineNr",
      "FoldColumn",
      "VertSplit",
      "WinSeparator",
      "Pmenu",
      "StatusLine",
      "TabLine",
      "TabLineFill",
    }

    for _, group in ipairs(groups) do
      vim.api.nvim_set_hl(0, group, { bg = "none" })
    end
  end,
}

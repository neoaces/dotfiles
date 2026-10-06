return {
  "xero/miasma.nvim",
  dependencies = { 'nvim-lualine/lualine.nvim' },
  lazy = false,
  priority = 1000,
  config = function()
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

    -- `:colorscheme` clears every highlight, so the overrides live in an autocmd
    -- and are re-applied each time miasma loads.
    local function overrides()
      for _, group in ipairs(groups) do
        vim.api.nvim_set_hl(0, group, { bg = "none" })
      end

      -- Inline code text: markview copies its fg from @markup.raw, and miasma's
      -- orange is hard to read on the purple tint.
      for _, group in ipairs({ "@markup.raw", "@markup.raw.markdown_inline" }) do
        vim.api.nvim_set_hl(0, group, { fg = "#d6cfa8" })
      end
    end

    vim.api.nvim_create_autocmd("ColorScheme", { pattern = "miasma", callback = overrides })
    vim.cmd("colorscheme miasma")
  end,
}

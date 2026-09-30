require("config.lazy")
vim.o.number = true

-- TAB STOP
vim.opt.expandtab = true    -- Use spaces instead of tabs
vim.opt.tabstop = 4        -- Width of a hard tab character
vim.opt.shiftwidth = 4     -- Size of an automatic indent
vim.opt.softtabstop = 4    -- Number of spaces a tab counts for while editing

-- WRAP
vim.opt.wrap = true
vim.opt.linebreak = true              -- Wrap at word boundaries, not mid-word
vim.opt.breakindent = true            -- Indent wrapped lines to match the line start
vim.opt.breakindentopt = "list:-1"    -- Hang wrapped list items under their text

-- FOLDING
vim.g.markdown_folding = 1      -- Fold markdown by heading (built-in ftplugin)
vim.opt.foldlevelstart = 99     -- Open files with everything unfolded

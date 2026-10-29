vim.cmd.colorscheme("powder")  -- Before plugins load, so lualine/markview read it
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

-- Move by screen line through wrapped text; a count (e.g. 5j) still moves by real lines
vim.keymap.set({ "n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })
vim.keymap.set({ "n", "x" }, "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })

-- MARKDOWN
require("config.wrap_width").setup()  -- Display-only wrap at 100 columns

-- FOLDING
vim.g.markdown_folding = 1      -- Fold markdown by heading (built-in ftplugin)
vim.opt.foldlevelstart = 99     -- Open files with everything unfolded

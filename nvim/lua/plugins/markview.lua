return {
    "OXY2DEV/markview.nvim",
    lazy = false,

    -- Completion for `blink.cmp`
    dependencies = { "saghen/blink.cmp", "nvim-treesitter/nvim-treesitter" },
    init = function()
        -- Raw text (insert mode, preview off): wrap wrapped list lines under the
        -- text after `- `. While rendered the bullet replaces the marker in place
        -- (shift_width = 0), so plain breakindent already lines up with it.
        local preview_modes = { n = true, no = true, c = true }

        local function update(win)
            if not vim.api.nvim_win_is_valid(win) then
                return
            end
            local rendered = vim.w[win].markview_preview and preview_modes[vim.fn.mode()]
            vim.wo[win].breakindentopt = rendered and "" or "list:-1"
        end

        local function set_preview(windows, on)
            for _, win in ipairs(windows or {}) do
                if vim.api.nvim_win_is_valid(win) then
                    vim.w[win].markview_preview = on
                    update(win)
                end
            end
        end

        vim.api.nvim_create_autocmd("User", {
            pattern = { "MarkviewAttach", "MarkviewEnable" },
            callback = function(ev) set_preview(ev.data and ev.data.windows, true) end,
        })
        vim.api.nvim_create_autocmd("User", {
            pattern = { "MarkviewDetach", "MarkviewDisable" },
            callback = function(ev) set_preview(ev.data and ev.data.windows, false) end,
        })
        vim.api.nvim_create_autocmd("ModeChanged", {
            callback = function() update(vim.api.nvim_get_current_win()) end,
        })

        require("config.center_math").setup()
    end,
    opts = {
        preview = {
            -- Needed so `latex` rendering is applied inside markdown buffers
            filetypes = { "markdown", "latex", "tex" },
            -- Show the line under the cursor as raw text in normal mode
            hybrid_modes = { "n" },
            edit_range = { 0, 0 },
        },
        latex = {
            -- Unicode sub/superscripts can't represent `i=1` or `t-1`, so the limits
            -- of a `\sum_{..}^{..}` show their real text. Everything else keeps the
            -- Unicode look.
            subscripts = function(buffer, item)
                local r = item.range
                local line = vim.api.nvim_buf_get_lines(buffer, r.row_start, r.row_start + 1, false)[1] or ""
                local after_sum = line:sub(1, r.col_start):match("\\sum$") ~= nil
                return { enable = true, hl = "MarkviewSubscript", fake_preview = not after_sum }
            end,
            superscripts = function(buffer, item)
                local r = item.range
                local line = vim.api.nvim_buf_get_lines(buffer, r.row_start, r.row_start + 1, false)[1] or ""
                local before = line:sub(1, r.col_start)
                local after_sum = before:match("\\sum_%b{}$") ~= nil or before:match("\\sum_[^{]$") ~= nil
                    or before:match("\\sum$") ~= nil
                return { enable = true, hl = "MarkviewSuperscript", fake_preview = not after_sum }
            end,
        },
        markdown = {
            -- Native wrapping handles wrapped list lines; markview's virtual-text
            -- indent misplaces itself on lines with concealed text
            list_items = { wrap = false, shift_width = 0 },
        },
        markdown_inline = {
            inline_codes = { enable = true },
        },
    },
};

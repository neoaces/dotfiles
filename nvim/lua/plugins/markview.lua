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

        -- Normal is transparent, so markview derives its backgrounds from a
        -- Catppuccin fallback (#1E1E2E) and tints everything purple. Rebuild its
        -- groups against miasma's real bg; markview never overwrites a set group,
        -- so clear them first. Then swap inline code text for miasma's pale sand.
        local function inline_code_hl()
            local normal = vim.api.nvim_get_hl(0, { name = "Normal" })
            vim.api.nvim_set_hl(0, "Normal", vim.tbl_extend("force", normal, { bg = "#1e1c19" }))
            for _, group in ipairs(vim.fn.getcompletion("Markview", "highlight")) do
                vim.api.nvim_set_hl(0, group, {})
            end
            require("markview.highlights").setup()
            vim.api.nvim_set_hl(0, "Normal", normal)

            local hl = vim.api.nvim_get_hl(0, { name = "MarkviewInlineCode", link = false })
            vim.api.nvim_set_hl(0, "MarkviewInlineCode", { fg = "#d6cfa8", bg = hl.bg })
            -- Light grey backdrop behind task text (open and done)
            vim.api.nvim_set_hl(0, "MarkviewTask", { bg = "#3a3a3a" })
            vim.api.nvim_set_hl(0, "MarkviewTaskDone", { bg = "#3a3a3a", strikethrough = true, fg = "#7a7a7a" })
        end
        vim.api.nvim_create_autocmd("ColorScheme", {
            callback = function() vim.schedule(inline_code_hl) end,
        })
        -- At startup markview builds its highlights after the colorscheme loads
        vim.api.nvim_create_autocmd("User", {
            pattern = { "LazyDone", "MarkviewAttach", "MarkviewEnable" },
            callback = function() vim.schedule(inline_code_hl) end,
        })
        vim.api.nvim_create_autocmd("VimEnter", {
            callback = function() vim.defer_fn(inline_code_hl, 50) end,
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
            -- Leave the ``` fence lines unhighlighted; only the code lines get
            -- the block background
            code_blocks = { border_hl = "Normal" },
        },
        markdown_inline = {
            checkboxes = {
                checked = { scope_hl = "MarkviewTaskDone" },
                unchecked = { scope_hl = "MarkviewTask" },
            },
            -- No padding, so the highlight covers just the code (not where the
            -- hidden backticks were)
            inline_codes = { enable = true, padding_left = "", padding_right = "" },
        },
    },
};

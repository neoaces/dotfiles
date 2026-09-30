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

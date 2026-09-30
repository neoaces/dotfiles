-- Centers markdown lines that consist only of inline math (`$ ... $`) while
-- markview's preview is rendered. Markview has no option for this, so the
-- rendered width is worked out from its own extmarks (concealed ranges and
-- inline virtual text) and a matching inline padding is added at column 0.
local M = {}

local ns = vim.api.nvim_create_namespace("center_math")
local preview_modes = { n = true, no = true, c = true }
local timer = assert(vim.uv.new_timer())

-- Lines made of a single `$...$` or `$$...$$` span and nothing else
local function is_math_line(line)
    return line:match("^%s*%$[^$]+%$%s*$") ~= nil or line:match("^%s*%$%$[^$]+%$%$%s*$") ~= nil
end

-- Width of `line` as markview renders it
local function rendered_width(buf, row, line)
    local hidden, extra = {}, 0

    for name, id in pairs(vim.api.nvim_get_namespaces()) do
        if name:find("^markview/") then
            local marks = vim.api.nvim_buf_get_extmarks(buf, id, { row, 0 }, { row, -1 }, { details = true })
            for _, mark in ipairs(marks) do
                local col, d = mark[3], mark[4]
                if d.conceal ~= nil and (d.end_row == nil or d.end_row == row) and d.end_col then
                    for c = col, d.end_col - 1 do
                        hidden[c] = true
                    end
                end
                if d.virt_text and d.virt_text_pos == "inline" then
                    for _, chunk in ipairs(d.virt_text) do
                        extra = extra + vim.fn.strdisplaywidth(chunk[1])
                    end
                end
            end
        end
    end

    local width, byte = extra, 0
    for _, ch in ipairs(vim.fn.split(line, "\\zs")) do
        if not hidden[byte] then
            width = width + vim.fn.strdisplaywidth(ch)
        end
        byte = byte + #ch
    end
    return width
end

local function refresh_win(win)
    local buf = vim.api.nvim_win_get_buf(win)
    vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)

    if vim.bo[buf].filetype ~= "markdown" or not vim.w[win].markview_preview then
        return
    end
    -- Insert mode etc. show raw text, so nothing to center
    if win == vim.api.nvim_get_current_win() and not preview_modes[vim.fn.mode()] then
        return
    end

    local info = vim.fn.getwininfo(win)[1]
    local avail = info.width - info.textoff
    local cursor_row = win == vim.api.nvim_get_current_win() and vim.api.nvim_win_get_cursor(win)[1] - 1 or nil

    for row, line in ipairs(vim.api.nvim_buf_get_lines(buf, 0, -1, false)) do
        row = row - 1
        -- The cursor line is shown raw (hybrid mode), so leave it alone
        if row ~= cursor_row and is_math_line(line) then
            local pad = math.floor((avail - rendered_width(buf, row, line)) / 2)
            if pad > 0 then
                vim.api.nvim_buf_set_extmark(buf, ns, row, 0, {
                    virt_text = { { string.rep(" ", pad) } },
                    virt_text_pos = "inline",
                    priority = 1,
                })
            end
        end
    end
end

local function refresh()
    for _, win in ipairs(vim.api.nvim_list_wins()) do
        refresh_win(win)
    end
end

-- Markview re-renders on a short debounce, so wait for it before measuring
local function schedule()
    timer:stop()
    timer:start(80, 0, vim.schedule_wrap(refresh))
end

function M.setup()
    vim.api.nvim_create_autocmd(
        { "TextChanged", "TextChangedI", "CursorMoved", "ModeChanged", "WinResized", "BufWinEnter" },
        { callback = schedule }
    )
    vim.api.nvim_create_autocmd("User", {
        pattern = { "MarkviewAttach", "MarkviewDetach", "MarkviewEnable", "MarkviewDisable" },
        callback = schedule,
    })
end

return M

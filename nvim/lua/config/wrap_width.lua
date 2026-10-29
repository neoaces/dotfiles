-- Soft-wraps markdown at a readable width without touching the file. Neovim
-- always wraps at the window edge, so a markdown window that spans the screen
-- gets an empty padding window on its right, sized to leave `width` columns for
-- text. The split line between the two marks the wrap column.
local M = {}

local width = 100
local pads = {} -- markdown window -> its padding window
local pending = false

local function is_pad(win)
    return vim.api.nvim_win_is_valid(win) and vim.w[win].wrap_pad == true
end

local function close_pad(win)
    local pad = pads[win]
    pads[win] = nil
    if pad and vim.api.nvim_win_is_valid(pad) then
        pcall(vim.api.nvim_win_close, pad, true)
    end
end

local function open_pad(win)
    local buf = vim.api.nvim_create_buf(false, true)
    vim.bo[buf].bufhidden = "wipe"
    vim.bo[buf].filetype = "wrappad" -- lualine skips this filetype

    local pad = vim.api.nvim_open_win(buf, false, { split = "right", win = win })
    vim.w[pad].wrap_pad = true
    vim.w[pad].wrap_owner = win
    local opts = {
        number = false,
        relativenumber = false,
        signcolumn = "no",
        foldcolumn = "0",
        statuscolumn = "",
        cursorline = false,
        colorcolumn = "",
        list = false,
        spell = false,
        fillchars = "eob: ",
        statusline = " ",
        winbar = "",
    }
    for name, value in pairs(opts) do
        vim.wo[pad][name] = value -- Like :set, so it outlasts a buffer swap in the pad
    end
    return pad
end

local function update(win)
    if is_pad(win) or vim.api.nvim_win_get_config(win).relative ~= "" then
        return
    end
    local pad = pads[win]
    if pad and not vim.api.nvim_win_is_valid(pad) then
        pads[win], pad = nil, nil
    end

    if vim.bo[vim.api.nvim_win_get_buf(win)].filetype ~= "markdown" then
        return close_pad(win)
    end

    local info = vim.fn.getwininfo(win)[1]
    local span = info.width + (pad and vim.api.nvim_win_get_width(pad) + 1 or 0)
    local target = width + info.textoff
    -- Only pad a window that spans the screen and has room to spare; side by
    -- side splits are already narrow
    if info.wincol ~= 1 or span ~= vim.o.columns or span <= target + 1 then
        return close_pad(win)
    end

    if not pad then
        pads[win] = open_pad(win)
    end
    if vim.api.nvim_win_get_width(win) ~= target then
        vim.api.nvim_win_set_width(win, target)
    end
end

local function refresh()
    pending = false
    for win, pad in pairs(pads) do
        -- Owner closed some other way than :q (e.g. :close)
        if not vim.api.nvim_win_is_valid(win) then
            pads[win] = nil
            if vim.api.nvim_win_is_valid(pad) and not pcall(vim.api.nvim_win_close, pad, true) then
                -- The pad was the last window left
                pcall(vim.cmd, "quit")
            end
        end
    end
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        if vim.api.nvim_win_is_valid(win) then
            update(win)
        end
    end
end

local function schedule()
    if not pending then
        pending = true
        vim.schedule(refresh)
    end
end

function M.setup()
    vim.api.nvim_create_autocmd(
        { "BufWinEnter", "FileType", "WinNew", "WinClosed", "WinResized", "VimResized", "TabEnter", "DiagnosticChanged" },
        { callback = schedule }
    )

    -- Close the pad first so :q on the markdown window quits as usual. If the
    -- quit is refused (unsaved changes), the next refresh brings it back.
    vim.api.nvim_create_autocmd("QuitPre", {
        callback = function()
            close_pad(vim.api.nvim_get_current_win())
            schedule()
        end,
    })

    -- The pad is never a place to edit; send focus back to its markdown window
    vim.api.nvim_create_autocmd("WinEnter", {
        callback = function()
            local win = vim.api.nvim_get_current_win()
            if is_pad(win) then
                local owner = vim.w[win].wrap_owner
                vim.schedule(function()
                    if owner and vim.api.nvim_win_is_valid(owner) then
                        vim.api.nvim_set_current_win(owner)
                    end
                end)
            end
        end,
    })
end

return M

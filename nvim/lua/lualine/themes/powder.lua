-- Lualine theme for the Powder colorscheme. lualine's `auto` theme picks this
-- up by name. Normal mode uses the same cobalt block as the tmux/starship bars.
local c = {
    bg = "#0c1010",
    surface = "#1a1b21",
    muted = "#5d6070",
    subtle = "#8a8e9c",
    text = "#b6bac8",
    bright = "#dde1ea",
    cobalt = "#0047ab",
    red = "#fb7185",
    green = "#a3e635",
    yellow = "#fbbf24",
    magenta = "#a78bfa",
}

local function mode(bg, fg)
    return {
        a = { fg = fg, bg = bg, gui = "bold" },
        b = { fg = c.text, bg = c.surface },
        c = { fg = c.subtle, bg = "NONE" },
    }
end

return {
    normal = mode(c.cobalt, c.bright),
    insert = mode(c.green, c.bg),
    visual = mode(c.magenta, c.bg),
    replace = mode(c.red, c.bg),
    command = mode(c.yellow, c.bg),
    inactive = {
        a = { fg = c.muted, bg = "NONE" },
        b = { fg = c.muted, bg = "NONE" },
        c = { fg = c.muted, bg = "NONE" },
    },
}

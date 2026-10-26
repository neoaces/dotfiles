-- Powder — Neovim port of the Ghostty theme (ghostty/themes/Powder), with the
-- cobalt accent the tmux and starship bars use. Backgrounds stay transparent so
-- Ghostty's own Powder background and blur show through.
vim.cmd("highlight clear")
vim.g.colors_name = "powder"
vim.o.background = "dark"

local c = {
    bg = "#0c1010",
    surface = "#1a1b21",
    overlay = "#24262e",
    border = "#3a3e4a",
    muted = "#5d6070",
    subtle = "#8a8e9c",
    text = "#b6bac8",
    fg = "#cfd3dd",
    bright = "#dde1ea",
    selection = "#1a302d",
    cobalt = "#0047ab",

    red = "#fb7185",
    green = "#a3e635",
    yellow = "#fbbf24",
    blue = "#6b97f2",
    magenta = "#a78bfa",
    cyan = "#2dd4bf",

    red_br = "#fda4af",
    green_br = "#bef264",
    yellow_br = "#fcd34d",
    blue_br = "#9dbbf7",
    magenta_br = "#c4b5fd",
    cyan_br = "#5eead4",
}

-- Same order as Ghostty's palette 0–15
vim.g.terminal_color_0 = c.surface
vim.g.terminal_color_1 = c.red
vim.g.terminal_color_2 = c.green
vim.g.terminal_color_3 = c.yellow
vim.g.terminal_color_4 = c.blue
vim.g.terminal_color_5 = c.magenta
vim.g.terminal_color_6 = c.cyan
vim.g.terminal_color_7 = c.text
vim.g.terminal_color_8 = c.muted
vim.g.terminal_color_9 = c.red_br
vim.g.terminal_color_10 = c.green_br
vim.g.terminal_color_11 = c.yellow_br
vim.g.terminal_color_12 = c.blue_br
vim.g.terminal_color_13 = c.magenta_br
vim.g.terminal_color_14 = c.cyan_br
vim.g.terminal_color_15 = c.bright

local groups = {
    -- Editor
    Normal = { fg = c.fg, bg = "NONE" },
    NormalNC = { link = "Normal" },
    NormalFloat = { fg = c.fg, bg = "NONE" },
    FloatBorder = { fg = c.muted },
    FloatTitle = { fg = c.blue, bold = true },
    Cursor = { fg = c.bg, bg = c.blue },
    CursorLine = { bg = c.surface },
    CursorColumn = { link = "CursorLine" },
    ColorColumn = { bg = c.surface },
    LineNr = { fg = c.muted },
    CursorLineNr = { fg = c.blue, bold = true },
    SignColumn = { bg = "NONE" },
    FoldColumn = { fg = c.muted, bg = "NONE" },
    Folded = { fg = c.subtle, bg = c.surface },
    EndOfBuffer = { fg = c.border, bg = "NONE" },
    NonText = { fg = c.border },
    Whitespace = { fg = c.border },
    SpecialKey = { fg = c.muted },
    Conceal = { fg = c.muted },
    WinSeparator = { fg = c.border, bg = "NONE" },
    VertSplit = { link = "WinSeparator" },
    StatusLine = { fg = c.text, bg = "NONE" },
    StatusLineNC = { fg = c.muted, bg = "NONE" },
    TabLine = { fg = c.muted, bg = "NONE" },
    TabLineFill = { bg = "NONE" },
    TabLineSel = { fg = c.bright, bg = c.cobalt, bold = true },
    WinBar = { fg = c.text },
    WinBarNC = { fg = c.muted },
    Visual = { bg = c.selection },
    VisualNOS = { link = "Visual" },
    Search = { fg = c.bg, bg = c.yellow },
    IncSearch = { fg = c.bg, bg = c.cyan },
    CurSearch = { link = "IncSearch" },
    Substitute = { fg = c.bg, bg = c.red },
    MatchParen = { fg = c.yellow, bg = c.overlay, bold = true },
    Pmenu = { fg = c.fg, bg = "NONE" },
    PmenuSel = { fg = c.bright, bg = c.selection, bold = true },
    PmenuSbar = { bg = c.surface },
    PmenuThumb = { bg = c.muted },
    Directory = { fg = c.blue },
    Title = { fg = c.blue, bold = true },
    Question = { fg = c.cyan },
    MoreMsg = { fg = c.green },
    ModeMsg = { fg = c.fg, bold = true },
    WarningMsg = { fg = c.yellow },
    ErrorMsg = { fg = c.red },
    QuickFixLine = { bg = c.selection },

    DiffAdd = { bg = "#17240c" },
    DiffChange = { bg = "#121b2e" },
    DiffDelete = { fg = c.red, bg = "#28121a" },
    DiffText = { bg = "#1c2c4c" },
    Added = { fg = c.green },
    Changed = { fg = c.blue },
    Removed = { fg = c.red },

    SpellBad = { undercurl = true, sp = c.red },
    SpellCap = { undercurl = true, sp = c.yellow },
    SpellRare = { undercurl = true, sp = c.magenta },
    SpellLocal = { undercurl = true, sp = c.cyan },

    -- Syntax
    Comment = { fg = c.muted, italic = true },
    Constant = { fg = c.yellow },
    String = { fg = c.green },
    Character = { fg = c.green },
    Number = { fg = c.yellow },
    Boolean = { fg = c.yellow },
    Float = { fg = c.yellow },
    Identifier = { fg = c.fg },
    Function = { fg = c.blue },
    Statement = { fg = c.magenta },
    Keyword = { fg = c.magenta },
    Conditional = { fg = c.magenta },
    Repeat = { fg = c.magenta },
    Label = { fg = c.magenta },
    Exception = { fg = c.red },
    Operator = { fg = c.text },
    PreProc = { fg = c.magenta_br },
    Include = { fg = c.magenta_br },
    Type = { fg = c.cyan },
    Special = { fg = c.cyan_br },
    Tag = { fg = c.blue },
    Delimiter = { fg = c.subtle },
    SpecialComment = { fg = c.subtle, italic = true },
    Debug = { fg = c.red },
    Underlined = { fg = c.blue, underline = true },
    Error = { fg = c.red },
    Todo = { fg = c.bg, bg = c.yellow, bold = true },

    -- Treesitter (anything not listed falls back to the groups above)
    ["@variable"] = { fg = c.fg },
    ["@variable.builtin"] = { fg = c.red_br },
    ["@variable.member"] = { fg = c.blue_br },
    ["@property"] = { fg = c.blue_br },
    ["@constructor"] = { fg = c.cyan },
    ["@function.builtin"] = { fg = c.cyan_br },
    ["@module"] = { fg = c.text },
    ["@punctuation"] = { fg = c.subtle },
    ["@tag.attribute"] = { fg = c.cyan_br },
    ["@tag.delimiter"] = { fg = c.subtle },

    -- Markdown. Markview builds its heading/palette colors from these.
    ["@markup.heading"] = { fg = c.blue, bold = true },
    ["@markup.heading.1.markdown"] = { fg = c.blue, bold = true },
    ["@markup.heading.2.markdown"] = { fg = c.cyan, bold = true },
    ["@markup.heading.3.markdown"] = { fg = c.green, bold = true },
    ["@markup.heading.4.markdown"] = { fg = c.yellow, bold = true },
    ["@markup.heading.5.markdown"] = { fg = c.magenta, bold = true },
    ["@markup.heading.6.markdown"] = { fg = c.red_br, bold = true },
    ["@markup.strong"] = { bold = true },
    ["@markup.italic"] = { italic = true },
    ["@markup.strikethrough"] = { strikethrough = true },
    ["@markup.underline"] = { underline = true },
    ["@markup.raw"] = { fg = c.cyan_br },
    ["@markup.raw.markdown_inline"] = { fg = c.cyan_br },
    ["@markup.link"] = { fg = c.blue_br },
    ["@markup.link.label"] = { fg = c.blue_br },
    ["@markup.link.url"] = { fg = c.cyan, underline = true },
    ["@markup.list"] = { fg = c.blue },
    ["@markup.list.checked"] = { fg = c.green },
    ["@markup.list.unchecked"] = { fg = c.muted },
    ["@markup.quote"] = { fg = c.subtle, italic = true },
    ["@markup.math"] = { fg = c.yellow_br },

    -- Diagnostics and LSP
    DiagnosticError = { fg = c.red },
    DiagnosticWarn = { fg = c.yellow },
    DiagnosticInfo = { fg = c.blue },
    DiagnosticHint = { fg = c.cyan },
    DiagnosticOk = { fg = c.green },
    DiagnosticUnderlineError = { undercurl = true, sp = c.red },
    DiagnosticUnderlineWarn = { undercurl = true, sp = c.yellow },
    DiagnosticUnderlineInfo = { undercurl = true, sp = c.blue },
    DiagnosticUnderlineHint = { undercurl = true, sp = c.cyan },
    DiagnosticUnderlineOk = { undercurl = true, sp = c.green },
    LspReferenceText = { bg = c.overlay },
    LspReferenceRead = { bg = c.overlay },
    LspReferenceWrite = { bg = c.overlay },
    LspInlayHint = { fg = c.muted, italic = true },

    -- Plugins
    TelescopeBorder = { link = "FloatBorder" },
    TelescopeTitle = { link = "FloatTitle" },
    TelescopeSelection = { fg = c.bright, bg = c.selection },
    TelescopeMatching = { fg = c.yellow, bold = true },
    TelescopePromptPrefix = { fg = c.blue },
    BlinkCmpMenuBorder = { link = "FloatBorder" },
    BlinkCmpLabelMatch = { fg = c.yellow, bold = true },
}

for name, spec in pairs(groups) do
    vim.api.nvim_set_hl(0, name, spec)
end

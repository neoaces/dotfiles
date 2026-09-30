return {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    lazy = false,
    build = ":TSUpdate",
    config = function()
        -- Parsers markview needs to render LaTeX math in markdown
        -- (compiling them requires the `tree-sitter` CLI: brew install tree-sitter-cli)
        require("nvim-treesitter").install({ "markdown", "markdown_inline", "latex", "html", "yaml" })
    end,
};

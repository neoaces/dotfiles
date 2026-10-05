return {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    lazy = false,
    build = ":TSUpdate",
    config = function()
        -- Parsers markview needs to render LaTeX math in markdown
        -- (compiling them requires the `tree-sitter` CLI: cargo install tree-sitter-cli; the apt version is too old)
        require("nvim-treesitter").install({ "markdown", "markdown_inline", "latex", "html", "yaml" })
    end,
};

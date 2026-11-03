return {
    "iamcco/markdown-preview.nvim",
    -- macOS only: elsewhere the plugin and its commands are never loaded
    cond = vim.fn.has("mac") == 1,
    cmd = { "MarkdownPreview", "MarkdownPreviewStop", "MarkdownPreviewToggle" },
    ft = { "markdown" },
    keys = {
        { "<C-w>m", "<cmd>MarkdownPreviewToggle<cr>", ft = "markdown", desc = "Toggle markdown preview" },
    },
    -- Downloads the prebuilt preview server, so node/yarn aren't needed
    build = "cd app && ./install.sh",
}

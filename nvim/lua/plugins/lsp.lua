return {
    "neovim/nvim-lspconfig",
    config = function()
        vim.lsp.enable({ "basedpyright", "ruff" })
    end,
}

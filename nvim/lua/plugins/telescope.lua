return {
    'nvim-telescope/telescope.nvim', version = '*',
    dependencies = {
        'nvim-lua/plenary.nvim',
        -- optional but recommended
        { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' },
    },
    -- <C-t> + the usual LSP key opens that LSP result list in Telescope
    keys = {
        { '<C-t>t', '<cmd>Telescope<cr>', desc = 'Telescope: all pickers' },
        { '<C-t>gd', '<cmd>Telescope lsp_definitions<cr>', desc = 'Telescope: definitions' },
        { '<C-t>grt', '<cmd>Telescope lsp_type_definitions<cr>', desc = 'Telescope: type definitions' },
        { '<C-t>grr', '<cmd>Telescope lsp_references<cr>', desc = 'Telescope: references' },
        { '<C-t>gri', '<cmd>Telescope lsp_implementations<cr>', desc = 'Telescope: implementations' },
        { '<C-t>gO', '<cmd>Telescope lsp_document_symbols<cr>', desc = 'Telescope: document symbols' },
        { '<C-t>gW', '<cmd>Telescope lsp_dynamic_workspace_symbols<cr>', desc = 'Telescope: workspace symbols' },
        { '<C-t>gci', '<cmd>Telescope lsp_incoming_calls<cr>', desc = 'Telescope: incoming calls' },
        { '<C-t>gco', '<cmd>Telescope lsp_outgoing_calls<cr>', desc = 'Telescope: outgoing calls' },
        { '<C-t>d', '<cmd>Telescope diagnostics bufnr=0<cr>', desc = 'Telescope: buffer diagnostics' },
    },
}

local set = vim.opt
local kmap = vim.keymap

vim.wo.number = true -- hello
vim.g.mapleader = " "
set.tabstop = 4
set.shiftwidth = 4
set.expandtab = true

kmap.set("n", "h", "h", {})     -- left
kmap.set("n", "n", "j", {})     -- down
kmap.set("n", "e", "k", {})     -- up
kmap.set("n", "i", "l", {})     -- right
kmap.set("v", "h", "h", {})     -- left
kmap.set("v", "n", "j", {})     -- down
kmap.set("v", "e", "k", {})     -- up
kmap.set("v", "i", "l", {})     -- right
kmap.set("n", "E", "5k", {})    -- go up 5 lines
kmap.set("n", "N", "5j", {})    -- go down 5 lines
kmap.set("n", "I", "$", {})     -- go to the end of the line
kmap.set("n", "H", "_", {})     -- go to the start of the line
kmap.set("n", "k", "i", {})     -- enter insert mode
kmap.set("n", "l", "u", {})     -- undo
kmap.set("n", "L", "<C-r>", {}) -- redo

-- Leader Bindings
kmap.set("n", "<LEADER>t", ":Telescope find_files<CR>", {})                                -- Find files
kmap.set("n", "<LEADER>n", ":Telescope file_browser<CR>", {})                              -- Find files
kmap.set("n", "<LEADER>p", ":Telescope project<CR>", {})                                   -- Format file
kmap.set("n", "<LEADER>f", ":Telescope current_buffer_fuzzy_find<CR>", {})                                   -- Format file

kmap.set("n", "<LEADER>a", ':lua require("harpoon.mark").add_file()<CR>', { silent = true }) -- add file
kmap.set("n", "<LEADER>h", ':Telescope harpoon marks<CR>', { silent = true })              -- add file

-- Lazy Config
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        "--branch=stable", -- latest stable release
        lazypath,
    })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup("plugins")

-- Plugin prep
vim.cmd [[colorscheme zenbones]]

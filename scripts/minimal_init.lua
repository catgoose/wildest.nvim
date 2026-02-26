-- Minimal init script for running tests with mini.test
-- Usage: nvim --headless -u scripts/minimal_init.lua

-- Add this plugin to rtp
local root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h:h")
vim.opt.rtp:prepend(root)

-- Add mini.nvim to rtp
local mini_path = root .. "/deps/mini.nvim"
if vim.fn.isdirectory(mini_path) == 0 then
  vim.fn.system({
    "git",
    "clone",
    "--depth",
    "1",
    "https://github.com/echasnovski/mini.nvim",
    mini_path,
  })
end
vim.opt.rtp:prepend(mini_path)

-- Disable swap files and shada for test stability
vim.o.swapfile = false
vim.o.shadafile = "NONE"

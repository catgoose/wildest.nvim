-- Screenshot init for wildest.nvim
-- Usage: WILDEST_CONFIG=theme_saloon nvim -u scripts/screenshots/init.lua sample.lua
--
-- Reads WILDEST_CONFIG env var to select which configuration variant to use.
-- See generate.sh for the list of all available configs.

local script_dir = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h")
local root = vim.fn.fnamemodify(script_dir, ":h:h")
local configs = dofile(script_dir .. "/configs.lua")
configs.setup(root)

local w = require("wildest")

local config_name = vim.env.WILDEST_CONFIG or vim.g.wildest_config or "popupmenu_border"
vim.o.statusline = " %f %m%= " .. config_name .. " "

local built, vim_opts = configs.build(config_name, w)
w.setup(vim.tbl_extend("force", {
  modes = { ":", "/", "?" },
  next_key = "<Tab>",
  previous_key = "<S-Tab>",
  accept_key = "<Down>",
  reject_key = "<Up>",
}, built))

-- Enforce vim options AFTER w.setup() so nothing can override them.
configs.apply_vim_opts(vim_opts)

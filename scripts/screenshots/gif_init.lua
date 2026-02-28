-- GIF init for wildest.nvim animated GIFs
-- Usage: WILDEST_GIF_NAME=showdown nvim -u scripts/screenshots/gif_init.lua -i NONE

local script_dir = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h")
local name = vim.env.WILDEST_GIF_NAME or "showdown"
dofile(script_dir .. "/configs.lua").gif_init(name)

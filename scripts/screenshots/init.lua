-- Screenshot init for wildest.nvim
-- Usage: WILDEST_CONFIG=theme_saloon nvim -u scripts/screenshots/init.lua -i NONE

local script_dir = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h")
local config_name = vim.env.WILDEST_CONFIG or "popupmenu_border"
dofile(script_dir .. "/configs.lua").screenshot_init(config_name)

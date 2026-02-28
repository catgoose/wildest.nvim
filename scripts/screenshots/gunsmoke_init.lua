-- Gunsmoke init for wildest.nvim animated GIF
-- Usage: nvim -u scripts/screenshots/gunsmoke_init.lua

local script_dir = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h")
dofile(script_dir .. "/configs.lua").gif_init("gunsmoke")

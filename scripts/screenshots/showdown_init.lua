-- Showdown init for wildest.nvim animated GIF
-- Single Neovim session that cycles through scenes via <Ctrl+n>.
-- Usage: nvim -u scripts/screenshots/showdown_init.lua scripts/screenshots/sample.lua

local script_dir = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h")
local root = vim.fn.fnamemodify(script_dir, ":h:h")
local configs = dofile(script_dir .. "/configs.lua")
configs.setup(root)

local w = require("wildest")
local scenes = configs.showdown_scenes
local current_scene = 1

local function apply_scene(index)
  local scene = scenes[index]
  if not scene then
    return
  end
  vim.o.statusline = " %f %= " .. index .. "/" .. #scenes .. "  " .. scene.label .. " "
  local built, vim_opts = configs.build(scene, w)
  w.setup(vim.tbl_extend("force", {
    modes = { ":", "/", "?" },
    next_key = "<Tab>",
    previous_key = "<S-Tab>",
    accept_key = "<Down>",
    reject_key = "<Up>",
  }, built))
  configs.apply_vim_opts(vim_opts)
end

vim.keymap.set("n", "<C-n>", function()
  current_scene = current_scene + 1
  if current_scene > #scenes then
    current_scene = 1
  end
  apply_scene(current_scene)
end, { noremap = true, silent = true })

apply_scene(1)

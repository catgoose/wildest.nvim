local MiniTest = require("mini.test")
local new_set = MiniTest.new_set
local expect = MiniTest.expect

local T = new_set()

local function get_preview()
  local preview = require("wildest.preview")
  preview._reset()
  return preview
end

T["setup()"] = new_set()

T["setup()"]["stores config correctly"] = function()
  local preview = get_preview()
  preview.setup({ width = "30%", border = "rounded", max_lines = 100, title = false })
  expect.equality(preview.is_active(), true)
end

T["setup()"]["defaults enabled to true"] = function()
  local preview = get_preview()
  preview.setup({})
  expect.equality(preview.is_active(), true)
end

T["setup()"]["respects enabled = false"] = function()
  local preview = get_preview()
  preview.setup({ enabled = false })
  expect.equality(preview.is_active(), false)
end

T["reserved_width()"] = new_set()

T["reserved_width()"]["returns 0 when not configured"] = function()
  local preview = get_preview()
  expect.equality(preview.reserved_width(), 0)
end

T["reserved_width()"]["returns 0 when configured but window not visible"] = function()
  local preview = get_preview()
  preview.setup({ width = "50%" })
  -- Window not open yet, so reserved_width should be 0
  expect.equality(preview.reserved_width(), 0)
end

T["reserved_width()"]["returns 0 when toggled off"] = function()
  local preview = get_preview()
  preview.setup({ enabled = true })
  preview.toggle() -- disable
  expect.equality(preview.reserved_width(), 0)
end

T["is_active()"] = new_set()

T["is_active()"]["false by default"] = function()
  local preview = get_preview()
  expect.equality(preview.is_active(), false)
end

T["is_active()"]["true after setup with enabled=true"] = function()
  local preview = get_preview()
  preview.setup({ enabled = true })
  expect.equality(preview.is_active(), true)
end

T["is_active()"]["false after toggle"] = function()
  local preview = get_preview()
  preview.setup({ enabled = true })
  preview.toggle()
  expect.equality(preview.is_active(), false)
end

T["toggle()"] = new_set()

T["toggle()"]["flips enabled state"] = function()
  local preview = get_preview()
  preview.setup({ enabled = true })
  expect.equality(preview.is_active(), true)
  preview.toggle()
  expect.equality(preview.is_active(), false)
  preview.toggle()
  expect.equality(preview.is_active(), true)
end

T["hide()"] = new_set()

T["hide()"]["safe to call when no window exists"] = function()
  local preview = get_preview()
  -- Should not error
  preview.hide()
end

T["hide()"]["safe to call when not configured"] = function()
  local preview = get_preview()
  preview.hide()
  expect.equality(preview.reserved_width(), 0)
end

T["setup()"]["stores position and anchor correctly"] = function()
  local preview = get_preview()
  preview.setup({ position = "left", anchor = "popup" })
  expect.equality(preview.is_active(), true)
  expect.equality(preview.is_screen_anchor(), false)
end

T["setup()"]["defaults position to right and anchor to screen"] = function()
  local preview = get_preview()
  preview.setup({})
  expect.equality(preview.is_screen_anchor(), true)
end

T["reserved_space()"] = new_set()

T["reserved_space()"]["returns all zeros when not configured"] = function()
  local preview = get_preview()
  local s = preview.reserved_space()
  expect.equality(s, { top = 0, right = 0, bottom = 0, left = 0 })
end

T["reserved_space()"]["returns all zeros when window not visible"] = function()
  local preview = get_preview()
  preview.setup({ position = "right", anchor = "screen" })
  local s = preview.reserved_space()
  expect.equality(s, { top = 0, right = 0, bottom = 0, left = 0 })
end

T["reserved_space()"]["returns all zeros for popup anchor"] = function()
  local preview = get_preview()
  preview.setup({ position = "right", anchor = "popup" })
  local s = preview.reserved_space()
  expect.equality(s, { top = 0, right = 0, bottom = 0, left = 0 })
end

T["reserved_space()"]["returns all zeros when toggled off"] = function()
  local preview = get_preview()
  preview.setup({ position = "right", anchor = "screen" })
  preview.toggle()
  local s = preview.reserved_space()
  expect.equality(s, { top = 0, right = 0, bottom = 0, left = 0 })
end

T["is_screen_anchor()"] = new_set()

T["is_screen_anchor()"]["returns false when not configured"] = function()
  local preview = get_preview()
  expect.equality(preview.is_screen_anchor(), false)
end

T["is_screen_anchor()"]["returns true for screen anchor"] = function()
  local preview = get_preview()
  preview.setup({ anchor = "screen" })
  expect.equality(preview.is_screen_anchor(), true)
end

T["is_screen_anchor()"]["returns false for popup anchor"] = function()
  local preview = get_preview()
  preview.setup({ anchor = "popup" })
  expect.equality(preview.is_screen_anchor(), false)
end

T["_detect_expand()"] = new_set()

T["_detect_expand()"]["detects file from expand field"] = function()
  local preview = get_preview()
  expect.equality(preview._detect_expand({ expand = "file" }), "file")
  expect.equality(preview._detect_expand({ expand = "file_in_path" }), "file")
  expect.equality(preview._detect_expand({ expand = "dir" }), "file")
end

T["_detect_expand()"]["detects buffer from expand field"] = function()
  local preview = get_preview()
  expect.equality(preview._detect_expand({ expand = "buffer" }), "buffer")
end

T["_detect_expand()"]["detects help from expand field"] = function()
  local preview = get_preview()
  expect.equality(preview._detect_expand({ expand = "help" }), "help")
end

T["_detect_expand()"]["detects from cmd heuristic"] = function()
  local preview = get_preview()
  expect.equality(preview._detect_expand({ cmd = "help" }), "help")
  expect.equality(preview._detect_expand({ cmd = "h" }), "help")
  expect.equality(preview._detect_expand({ cmd = "buffer" }), "buffer")
  expect.equality(preview._detect_expand({ cmd = "b" }), "buffer")
  expect.equality(preview._detect_expand({ cmd = "edit" }), "file")
  expect.equality(preview._detect_expand({ cmd = "e" }), "file")
end

T["_detect_expand()"]["returns nil for unknown"] = function()
  local preview = get_preview()
  expect.equality(preview._detect_expand({}), nil)
  expect.equality(preview._detect_expand({ cmd = "set" }), nil)
end

return T

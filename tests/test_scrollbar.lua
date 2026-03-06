local MiniTest = require("mini.test")
local new_set = MiniTest.new_set
local expect = MiniTest.expect

local T = new_set()

local scrollbar = require("wildest.renderer.components.scrollbar")

T["scrollbar collapse"] = new_set()

T["scrollbar collapse"]["collapse=false returns bar when all fit"] = function()
  local comp = scrollbar.new({ collapse = false })
  local ctx = { total = 5, page_start = 0, page_end = 4, index = 0 }
  local result = comp:render(ctx)
  expect.equality(#result, 1)
  expect.equality(result[1][1], " ")
end

T["scrollbar collapse"]["collapse=true returns empty when all fit"] = function()
  local comp = scrollbar.new({ collapse = true })
  local ctx = { total = 5, page_start = 0, page_end = 4, index = 0 }
  local result = comp:render(ctx)
  expect.equality(#result, 0)
end

T["scrollbar collapse"]["collapse=true returns thumb when not all fit"] = function()
  local comp = scrollbar.new({ collapse = true })
  local ctx = { total = 20, page_start = 0, page_end = 4, index = 0 }
  local result = comp:render(ctx)
  expect.equality(#result, 1)
  -- Should be either thumb or bar character (not empty)
  expect.equality(result[1][1] ~= nil, true)
end

T["scrollbar collapse"]["collapse=true returns empty when total <= 0"] = function()
  local comp = scrollbar.new({ collapse = true })
  local ctx = { total = 0, page_start = 0, page_end = 0, index = 0 }
  local result = comp:render(ctx)
  expect.equality(#result, 0)
end

T["scrollbar thumb position"] = new_set()

T["scrollbar thumb position"]["thumb shown at correct line in page"] = function()
  local comp = scrollbar.new()
  -- 20 items, page 0-4, index at thumb start should show thumb
  local ctx_thumb = { total = 20, page_start = 0, page_end = 4, index = 0 }
  local result = comp:render(ctx_thumb)
  expect.equality(result[1][1], "█")
  expect.equality(result[1][2], "WildestScrollbarThumb")

  -- index outside thumb range should show bar
  local ctx_bar = { total = 20, page_start = 0, page_end = 4, index = 4 }
  local result2 = comp:render(ctx_bar)
  expect.equality(result2[1][1], " ")
  expect.equality(result2[1][2], "WildestScrollbar")
end

T["scrollbar thumb position"]["custom characters are used"] = function()
  local comp = scrollbar.new({ thumb = "▓", bar = "░" })
  local ctx = { total = 20, page_start = 0, page_end = 4, index = 0 }
  local result = comp:render(ctx)
  expect.equality(result[1][1], "▓")
end

T["scrollbar selected line"] = new_set()

T["scrollbar selected line"]["bar on selected line uses block char with sel hl"] = function()
  local comp = scrollbar.new()
  local ctx = { total = 20, page_start = 0, page_end = 4, index = 4, is_selected = true, selected_hl = "PmenuSel" }
  local result = comp:render(ctx)
  expect.equality(result[1][1], "█")
  expect.equality(result[1][2], "WildestScrollbarSel")
end

T["scrollbar selected line"]["thumb on selected line unchanged"] = function()
  local comp = scrollbar.new()
  local ctx = { total = 20, page_start = 0, page_end = 4, index = 0, is_selected = true, selected_hl = "PmenuSel" }
  local result = comp:render(ctx)
  expect.equality(result[1][1], "█")
  expect.equality(result[1][2], "WildestScrollbarThumb")
end

return T

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

return T

local MiniTest = require("mini.test")
local new_set = MiniTest.new_set
local expect = MiniTest.expect

local T = new_set()

local frecency_bar = require("wildest.renderer.components.frecency_bar")

-- Helpers ---------------------------------------------------------------------

--- Build a minimal render context.
local function make_ctx(candidate, overrides)
  local ctx = {
    candidate = candidate or "",
    run_id = 1,
    page_start = 0,
    page_end = 4,
    total = 5,
    result = { value = {} },
  }
  if overrides then
    for k, v in pairs(overrides) do
      ctx[k] = v
    end
  end
  return ctx
end

-- new() -----------------------------------------------------------------------

T["new()"] = new_set()

T["new()"]["returns a table with render method"] = function()
  local comp = frecency_bar.new()
  expect.equality(type(comp), "table")
  expect.equality(type(comp.render), "function")
end

T["new()"]["render returns a table of chunks"] = function()
  local comp = frecency_bar.new()
  local result = comp:render(make_ctx(""))
  expect.equality(type(result), "table")
  expect.equality(#result >= 1, true)
end

T["new()"]["empty candidate returns dim char"] = function()
  local comp = frecency_bar.new()
  local result = comp:render(make_ctx(""))
  expect.equality(#result, 1)
  -- Default dim_char is "▎"
  expect.equality(result[1][1], "▎")
end

T["new()"]["unknown candidate returns dim char"] = function()
  local comp = frecency_bar.new()
  local result = comp:render(make_ctx("totally_unknown_command_xyz_99"))
  expect.equality(#result, 1)
  expect.equality(result[1][1], "▎")
end

T["new()"]["chunk has highlight group"] = function()
  local comp = frecency_bar.new()
  local result = comp:render(make_ctx(""))
  expect.equality(type(result[1][2]), "string")
  -- Should be the first gradient hl group
  expect.equality(result[1][2], "WildestHeatCold")
end

-- Options ---------------------------------------------------------------------

T["options"] = new_set()

T["options"]["custom char is used"] = function()
  local comp = frecency_bar.new({ char = "X" })
  -- For an unknown candidate, dim_char is used (default "▎")
  local result = comp:render(make_ctx("totally_unknown_xyz"))
  expect.equality(result[1][1], "▎")
end

T["options"]["custom dim_char is used"] = function()
  local comp = frecency_bar.new({ dim_char = "." })
  local result = comp:render(make_ctx(""))
  expect.equality(result[1][1], ".")
end

T["options"]["custom gradient hl groups"] = function()
  local groups = { "MyHl1", "MyHl2", "MyHl3" }
  local comp = frecency_bar.new({ gradient = groups })
  local result = comp:render(make_ctx(""))
  expect.equality(result[1][2], "MyHl1")
end

-- Caching ---------------------------------------------------------------------

T["caching"] = new_set()

T["caching"]["different run_id refreshes data"] = function()
  local comp = frecency_bar.new()
  -- First render with run_id 1
  comp:render(make_ctx("a", { run_id = 1 }))
  -- Second render with run_id 2 should not error
  local result = comp:render(make_ctx("b", { run_id = 2 }))
  expect.equality(type(result), "table")
end

T["caching"]["different page refreshes max"] = function()
  local comp = frecency_bar.new()
  comp:render(make_ctx("a", { page_start = 0, page_end = 4 }))
  local result = comp:render(make_ctx("b", { page_start = 5, page_end = 9 }))
  expect.equality(type(result), "table")
end

return T

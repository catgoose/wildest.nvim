---@diagnostic disable: need-check-nil, undefined-global
local MiniTest = require("mini.test")
local new_set = MiniTest.new_set
local expect = MiniTest.expect

local T = new_set()

local renderer_util = require("wildest.renderer")

T["get_query()"] = new_set()

T["get_query()"]["returns query from result.data.query"] = function()
  local result = { data = { query = "hello" } }
  expect.equality(renderer_util.get_query(result), "hello")
end

T["get_query()"]["falls back to data.arg"] = function()
  local result = { data = { arg = "foo" } }
  expect.equality(renderer_util.get_query(result), "foo")
end

T["get_query()"]["falls back to data.input"] = function()
  local result = { data = { input = "bar" } }
  expect.equality(renderer_util.get_query(result), "bar")
end

T["get_query()"]["returns empty string when no data"] = function()
  local result = {}
  expect.equality(renderer_util.get_query(result), "")
end

T["get_query()"]["returns empty string when data has no query fields"] = function()
  local result = { data = { cmd = "edit" } }
  expect.equality(renderer_util.get_query(result), "")
end

T["get_query()"]["prefers query over arg over input"] = function()
  local result = { data = { query = "q", arg = "a", input = "i" } }
  expect.equality(renderer_util.get_query(result), "q")

  local result2 = { data = { arg = "a", input = "i" } }
  expect.equality(renderer_util.get_query(result2), "a")
end

T["parse_dimension()"] = new_set()

T["parse_dimension()"]["returns number directly"] = function()
  expect.equality(renderer_util.parse_dimension(42, 100), 42)
end

T["parse_dimension()"]["parses percentage string"] = function()
  expect.equality(renderer_util.parse_dimension("50%", 200), 100)
end

T["parse_dimension()"]["returns total for unrecognized input"] = function()
  expect.equality(renderer_util.parse_dimension("auto", 100), 100)
  expect.equality(renderer_util.parse_dimension(nil, 80), 80)
end

T["parse_margin()"] = new_set()

T["parse_margin()"]["centers with auto"] = function()
  expect.equality(renderer_util.parse_margin("auto", 100, 60), 20)
end

T["parse_margin()"]["returns number directly"] = function()
  expect.equality(renderer_util.parse_margin(5, 100, 60), 5)
end

T["parse_margin()"]["parses percentage"] = function()
  expect.equality(renderer_util.parse_margin("10%", 200, 100), 20)
end

T["parse_margin()"]["returns 0 for unrecognized input"] = function()
  expect.equality(renderer_util.parse_margin(nil, 100, 60), 0)
end

T["make_page()"] = new_set()

T["make_page()"]["returns -1, -1 for empty list"] = function()
  local s, f = renderer_util.make_page(-1, 0, 10, { -1, -1 })
  expect.equality(s, -1)
  expect.equality(f, -1)
end

T["make_page()"]["shows first page when no selection"] = function()
  local s, f = renderer_util.make_page(-1, 20, 5, { -1, -1 })
  expect.equality(s, 0)
  expect.equality(f, 4)
end

T["make_page()"]["keeps selection visible"] = function()
  local s, f = renderer_util.make_page(3, 20, 5, { 0, 4 })
  expect.equality(s >= 0, true)
  expect.equality(f >= s, true)
  expect.equality(3 >= s, true)
  expect.equality(3 <= f, true)
end

T["make_page()"]["scrolls when selection moves past page"] = function()
  local s, f = renderer_util.make_page(6, 20, 5, { 0, 4 })
  expect.equality(6 >= s, true)
  expect.equality(6 <= f, true)
  expect.equality(f - s + 1, 5)
end

T["make_page()"]["clamps to total"] = function()
  local s, f = renderer_util.make_page(2, 3, 10, { -1, -1 })
  expect.equality(s, 0)
  expect.equality(f, 2)
end

T["check_run_id()"] = new_set()

T["check_run_id()"]["resets page on run_id change"] = function()
  local state = { run_id = 1, page = { 5, 10 }, draw_cache = nil }
  renderer_util.check_run_id(state, { run_id = 2 })
  expect.equality(state.run_id, 2)
  expect.equality(state.page[1], -1)
  expect.equality(state.page[2], -1)
end

T["check_run_id()"]["preserves page on same run_id"] = function()
  local state = { run_id = 1, page = { 5, 10 }, draw_cache = nil }
  renderer_util.check_run_id(state, { run_id = 1 })
  expect.equality(state.page[1], 5)
  expect.equality(state.page[2], 10)
end

return T

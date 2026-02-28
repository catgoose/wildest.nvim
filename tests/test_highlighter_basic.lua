local MiniTest = require("mini.test")
local new_set = MiniTest.new_set
local expect = MiniTest.expect

local T = new_set()

local basic = require("wildest.highlight.basic")

-- highlight() -------------------------------------------------------------------

T["highlight()"] = new_set()

T["highlight()"]["returns empty spans for empty query"] = function()
  local h = basic.new()
  expect.equality(h.highlight("", "candidate"), {})
end

T["highlight()"]["returns empty spans for nil query"] = function()
  local h = basic.new()
  expect.equality(h.highlight(nil, "candidate"), {})
end

T["highlight()"]["highlights single character match"] = function()
  local h = basic.new()
  local spans = h.highlight("a", "apple")
  expect.equality(#spans, 1)
  expect.equality(spans[1][1], 0) -- 0-indexed start
  expect.equality(spans[1][2], 1) -- length 1
  expect.equality(spans[1][3], "WildestAccent")
end

T["highlight()"]["highlights consecutive characters as one span"] = function()
  local h = basic.new()
  local spans = h.highlight("app", "apple")
  expect.equality(#spans, 1)
  expect.equality(spans[1][1], 0)
  expect.equality(spans[1][2], 3) -- "app" = length 3
end

T["highlight()"]["splits non-consecutive matches into separate spans"] = function()
  local h = basic.new()
  local spans = h.highlight("ae", "apple")
  expect.equality(#spans, 2)
  expect.equality(spans[1][1], 0) -- 'a'
  expect.equality(spans[1][2], 1)
  expect.equality(spans[2][1], 4) -- 'e'
  expect.equality(spans[2][2], 1)
end

T["highlight()"]["is case insensitive"] = function()
  local h = basic.new()
  local spans = h.highlight("AB", "apple Banana")
  expect.equality(#spans >= 1, true)
end

T["highlight()"]["uses custom highlight group"] = function()
  local h = basic.new({ hl = "MyGroup" })
  local spans = h.highlight("a", "apple")
  expect.equality(spans[1][3], "MyGroup")
end

T["highlight()"]["no match returns empty"] = function()
  local h = basic.new()
  local spans = h.highlight("xyz", "apple")
  expect.equality(spans, {})
end

T["highlight()"]["full match is single span"] = function()
  local h = basic.new()
  local spans = h.highlight("abc", "abc")
  expect.equality(#spans, 1)
  expect.equality(spans[1][1], 0)
  expect.equality(spans[1][2], 3)
end

return T

local MiniTest = require("mini.test")
local new_set = MiniTest.new_set
local expect = MiniTest.expect

local T = new_set()

local prefix = require("wildest.highlight.prefix")

-- highlight() -------------------------------------------------------------------

T["highlight()"] = new_set()

T["highlight()"]["returns empty spans for empty query"] = function()
  local h = prefix.new()
  expect.equality(h.highlight("", "candidate"), {})
end

T["highlight()"]["returns empty spans for nil query"] = function()
  local h = prefix.new()
  expect.equality(h.highlight(nil, "candidate"), {})
end

T["highlight()"]["highlights matching prefix"] = function()
  local h = prefix.new()
  local spans = h.highlight("app", "apple")
  expect.equality(#spans, 1)
  expect.equality(spans[1][1], 0)
  expect.equality(spans[1][2], 3)
  expect.equality(spans[1][3], "WildestAccent")
end

T["highlight()"]["returns empty when no prefix matches"] = function()
  local h = prefix.new()
  local spans = h.highlight("xyz", "apple")
  expect.equality(spans, {})
end

T["highlight()"]["is case insensitive"] = function()
  local h = prefix.new()
  local spans = h.highlight("APP", "apple")
  expect.equality(#spans, 1)
  expect.equality(spans[1][2], 3)
end

T["highlight()"]["single character prefix"] = function()
  local h = prefix.new()
  local spans = h.highlight("a", "apple")
  expect.equality(#spans, 1)
  expect.equality(spans[1][1], 0)
  expect.equality(spans[1][2], 1)
end

T["highlight()"]["full match"] = function()
  local h = prefix.new()
  local spans = h.highlight("hello", "hello")
  expect.equality(#spans, 1)
  expect.equality(spans[1][2], 5)
end

T["highlight()"]["query longer than candidate"] = function()
  local h = prefix.new()
  local spans = h.highlight("apple pie", "apple")
  expect.equality(#spans, 1)
  expect.equality(spans[1][2], 5)
end

T["highlight()"]["stops at first non-matching char"] = function()
  local h = prefix.new()
  local spans = h.highlight("abx", "abcdef")
  expect.equality(#spans, 1)
  expect.equality(spans[1][2], 2) -- only "ab" matches
end

T["highlight()"]["uses custom highlight group"] = function()
  local h = prefix.new({ hl = "Custom" })
  local spans = h.highlight("a", "apple")
  expect.equality(spans[1][3], "Custom")
end

return T

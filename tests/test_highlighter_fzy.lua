local MiniTest = require("mini.test")
local new_set = MiniTest.new_set
local expect = MiniTest.expect

local T = new_set()

local fzy = require("wildest.highlight.fzy")

-- highlight() -------------------------------------------------------------------

T["highlight()"] = new_set()

T["highlight()"]["returns empty spans for empty query"] = function()
  local h = fzy.new()
  expect.equality(h.highlight("", "candidate"), {})
end

T["highlight()"]["returns empty spans for nil query"] = function()
  local h = fzy.new()
  expect.equality(h.highlight(nil, "candidate"), {})
end

T["highlight()"]["returns empty spans for no match"] = function()
  local h = fzy.new()
  local spans = h.highlight("xyz", "apple")
  expect.equality(spans, {})
end

T["highlight()"]["highlights matching characters"] = function()
  local h = fzy.new()
  local spans = h.highlight("ap", "apple")
  expect.equality(#spans >= 1, true)
  -- Total highlighted characters should equal query length
  local total_len = 0
  for _, span in ipairs(spans) do
    total_len = total_len + span[2]
    expect.equality(span[3], "WildestAccent")
  end
  expect.equality(total_len, 2)
end

T["highlight()"]["merges consecutive positions"] = function()
  local h = fzy.new()
  local spans = h.highlight("abc", "abcdef")
  -- "abc" at start should be one merged span
  expect.equality(#spans, 1)
  expect.equality(spans[1][2], 3) -- length 3
end

T["highlight()"]["uses custom highlight group"] = function()
  local h = fzy.new({ hl = "MyFzyHl" })
  local spans = h.highlight("a", "apple")
  expect.equality(#spans, 1)
  expect.equality(spans[1][3], "MyFzyHl")
end

T["highlight()"]["handles single character match"] = function()
  local h = fzy.new()
  local spans = h.highlight("p", "apple")
  expect.equality(#spans >= 1, true)
  local total_len = 0
  for _, span in ipairs(spans) do
    total_len = total_len + span[2]
  end
  expect.equality(total_len, 1)
end

T["highlight()"]["handles full string match"] = function()
  local h = fzy.new()
  local spans = h.highlight("hello", "hello")
  expect.equality(#spans, 1)
  expect.equality(spans[1][2], 5)
end

return T

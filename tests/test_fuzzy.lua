local MiniTest = require("mini.test")
local new_set = MiniTest.new_set
local expect = MiniTest.expect

local T = new_set()

local filter = require("wildest.filter")

-- has_match -------------------------------------------------------------------

T["has_match()"] = new_set()

T["has_match()"]["matches subsequence"] = function()
  expect.equality(filter.has_match("abc", "aXbYcZ"), true)
end

T["has_match()"]["is case insensitive"] = function()
  expect.equality(filter.has_match("abc", "AbC"), true)
end

T["has_match()"]["empty needle matches everything"] = function()
  expect.equality(filter.has_match("", "anything"), true)
end

T["has_match()"]["returns false on no match"] = function()
  expect.equality(filter.has_match("xyz", "abc"), false)
end

T["has_match()"]["handles single character"] = function()
  expect.equality(filter.has_match("a", "a"), true)
  expect.equality(filter.has_match("a", "b"), false)
end

-- score -----------------------------------------------------------------------

T["score()"] = new_set()

T["score()"]["exact match returns max score"] = function()
  local s = filter.score("abc", "abc")
  expect.equality(s, 1e9)
end

T["score()"]["better match scores higher"] = function()
  local s1 = filter.score("ab", "ab__c")
  local s2 = filter.score("ab", "a___b___c")
  expect.equality(s1 > s2, true)
end

T["score()"]["slash boundary gets bonus"] = function()
  local s_slash = filter.score("b", "/b")
  local s_mid = filter.score("b", "ab")
  expect.equality(s_slash > s_mid, true)
end

T["score()"]["camelCase boundary gets bonus"] = function()
  local s_camel = filter.score("B", "aB")
  local s_lower = filter.score("b", "ab")
  expect.equality(s_camel > s_lower, true)
end

T["score()"]["empty needle returns minimum"] = function()
  local s = filter.score("", "anything")
  expect.equality(s, -1e9)
end

-- filter_sort -----------------------------------------------------------------

T["filter_sort()"] = new_set()

T["filter_sort()"]["filters non-matches"] = function()
  local results = filter.filter_sort("ab", { "abc", "def", "aXb" })
  -- "def" should be excluded
  for _, v in ipairs(results) do
    expect.no_equality(v, "def")
  end
  expect.equality(#results, 2)
end

T["filter_sort()"]["sorts by score descending"] = function()
  local results = filter.filter_sort("ab", { "a___b", "ab", "aXb" })
  -- exact prefix "ab" should come first
  expect.equality(results[1], "ab")
end

T["filter_sort()"]["empty needle returns all candidates"] = function()
  local candidates = { "foo", "bar", "baz" }
  local results = filter.filter_sort("", candidates)
  expect.equality(#results, 3)
end

T["filter_sort()"]["returns empty for no matches"] = function()
  local results = filter.filter_sort("zzz", { "abc", "def" })
  expect.equality(#results, 0)
end

-- positions -------------------------------------------------------------------

T["positions()"] = new_set()

T["positions()"]["returns correct 0-indexed positions"] = function()
  local pos = filter.positions("ac", "abc")
  expect.equality(type(pos), "table")
  expect.equality(#pos, 2)
  expect.equality(pos[1], 0) -- 'a' at index 0
  expect.equality(pos[2], 2) -- 'c' at index 2
end

T["positions()"]["returns table even for non-subsequence"] = function()
  -- positions() does not validate has_match; callers should check has_match first.
  -- Just verify it doesn't crash and returns a table.
  local pos = filter.positions("z", "abc")
  expect.equality(type(pos), "table")
end

T["positions()"]["single character match"] = function()
  local pos = filter.positions("b", "abc")
  expect.equality(type(pos), "table")
  expect.equality(#pos, 1)
  expect.equality(pos[1], 1)
end

-- edge cases ------------------------------------------------------------------

T["edge cases"] = new_set()

T["edge cases"]["empty haystack"] = function()
  expect.equality(filter.has_match("a", ""), false)
end

T["edge cases"]["both empty"] = function()
  expect.equality(filter.has_match("", ""), true)
end

T["edge cases"]["single char exact match"] = function()
  local s = filter.score("x", "x")
  expect.equality(s, 1e9)
end

T["edge cases"]["positions with empty needle"] = function()
  local pos = filter.positions("", "abc")
  expect.equality(type(pos), "table")
  expect.equality(#pos, 0)
end

return T

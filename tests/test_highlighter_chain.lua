---@diagnostic disable: need-check-nil, undefined-global
local MiniTest = require("mini.test")
local new_set = MiniTest.new_set
local expect = MiniTest.expect

local chain = require("wildest.highlight.chain")

local T = new_set()

-- Helper: create a mock highlighter that returns given spans
local function mock_hl(spans)
  return {
    highlight = function(_, _)
      return spans
    end,
  }
end

-- Helper: create a mock highlighter that returns spans only for a specific query
local function conditional_hl(match_query, spans)
  return {
    highlight = function(query, _)
      if query == match_query then
        return spans
      end
      return {}
    end,
  }
end

T["chain highlighter"] = new_set()

T["chain highlighter"]["single highlighter returns its spans"] = function()
  local spans = { { 0, 3, "WildestAccent" } }
  local h = chain.new({ mock_hl(spans) })
  local result = h.highlight("foo", "foobar")
  expect.equality(result, spans)
end

T["chain highlighter"]["first highlighter matches — returns first's spans"] = function()
  local spans1 = { { 0, 2, "WildestAccent" } }
  local spans2 = { { 1, 3, "WildestAccent" } }
  local h = chain.new({ mock_hl(spans1), mock_hl(spans2) })
  local result = h.highlight("fo", "foobar")
  expect.equality(result, spans1)
end

T["chain highlighter"]["first returns empty, second matches — returns second's spans"] = function()
  local spans2 = { { 2, 1, "WildestAccent" } }
  local h = chain.new({ mock_hl({}), mock_hl(spans2) })
  local result = h.highlight("o", "foobar")
  expect.equality(result, spans2)
end

T["chain highlighter"]["all return empty — returns empty table"] = function()
  local h = chain.new({ mock_hl({}), mock_hl({}) })
  local result = h.highlight("xyz", "foobar")
  expect.equality(result, {})
end

T["chain highlighter"]["empty query — returns empty table"] = function()
  local spans = { { 0, 3, "WildestAccent" } }
  local h = chain.new({ conditional_hl("foo", spans) })
  local result = h.highlight("", "foobar")
  expect.equality(result, {})
end

T["chain highlighter"]["single highlighter returns nil — returns empty table"] = function()
  local h = chain.new({
    { highlight = function(_, _) return nil end },
  })
  local result = h.highlight("foo", "foobar")
  expect.equality(result, {})
end

T["chain highlighter"]["three highlighters — correct fallback order"] = function()
  local spans3 = { { 0, 1, "WildestAccent" } }
  local h = chain.new({
    mock_hl({}),
    { highlight = function(_, _) return nil end },
    mock_hl(spans3),
  })
  local result = h.highlight("f", "foobar")
  expect.equality(result, spans3)
end

return T

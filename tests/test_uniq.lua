local MiniTest = require("mini.test")
local new_set = MiniTest.new_set
local expect = MiniTest.expect

local T = new_set()

local uniq = require("wildest.filter.uniq")

-- uniq_filter() ------------------------------------------------------------------

T["uniq_filter()"] = new_set()

T["uniq_filter()"]["removes duplicates"] = function()
  local filter = uniq.uniq_filter()
  local result = filter({}, { "a", "b", "a", "c", "b" })
  expect.equality(result, { "a", "b", "c" })
end

T["uniq_filter()"]["preserves order of first occurrence"] = function()
  local filter = uniq.uniq_filter()
  local result = filter({}, { "c", "a", "b", "a", "c" })
  expect.equality(result, { "c", "a", "b" })
end

T["uniq_filter()"]["handles empty input"] = function()
  local filter = uniq.uniq_filter()
  local result = filter({}, {})
  expect.equality(result, {})
end

T["uniq_filter()"]["handles all unique items"] = function()
  local filter = uniq.uniq_filter()
  local result = filter({}, { "a", "b", "c" })
  expect.equality(result, { "a", "b", "c" })
end

T["uniq_filter()"]["handles all identical items"] = function()
  local filter = uniq.uniq_filter()
  local result = filter({}, { "x", "x", "x" })
  expect.equality(result, { "x" })
end

T["uniq_filter()"]["single item"] = function()
  local filter = uniq.uniq_filter()
  local result = filter({}, { "only" })
  expect.equality(result, { "only" })
end

T["uniq_filter()"]["uses custom key function"] = function()
  local filter = uniq.uniq_filter({ key = function(s) return s:lower() end })
  local result = filter({}, { "Foo", "foo", "FOO", "Bar", "bar" })
  expect.equality(result, { "Foo", "Bar" })
end

T["uniq_filter()"]["ignores ctx parameter"] = function()
  local filter = uniq.uniq_filter()
  local result = filter({ some = "context" }, { "a", "b", "a" })
  expect.equality(result, { "a", "b" })
end

T["uniq_filter()"]["works as pipeline step"] = function()
  local filter = uniq.uniq_filter()
  -- Simulate pipeline: first stage returns candidates, then uniq_filter deduplicates
  local stage1 = function(_ctx, _input)
    return { "edit", "edit", "echo", "exit", "echo" }
  end
  local ctx = { input = "e", cmdtype = ":" }
  local candidates = stage1(ctx, "e")
  local deduped = filter(ctx, candidates)
  expect.equality(deduped, { "edit", "echo", "exit" })
end

return T

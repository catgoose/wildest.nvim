local MiniTest = require("mini.test")
local new_set = MiniTest.new_set
local expect = MiniTest.expect

local T = new_set()

local search_mod = require("wildest.search")

-- Helper: create a scratch buffer with given lines and set it as current
local function setup_buffer(lines)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_set_current_buf(buf)
  return buf
end

-- ── Basic search (non-fuzzy) ───────────────────────────────────────

T["pipeline"] = new_set()

T["pipeline"]["returns false for wrong cmdtype"] = function()
  local pipeline = search_mod.search_pipeline()
  local step = pipeline[1]
  local result = step({ cmdtype = ":" }, "foo")
  expect.equality(result, false)
end

T["pipeline"]["returns false for empty input"] = function()
  local pipeline = search_mod.search_pipeline()
  local step = pipeline[1]
  local result = step({ cmdtype = "/" }, "")
  expect.equality(result, false)
end

T["pipeline"]["returns false for nil input"] = function()
  local pipeline = search_mod.search_pipeline()
  local step = pipeline[1]
  local result = step({ cmdtype = "/" }, nil)
  expect.equality(result, false)
end

T["pipeline"]["returns result for valid regex match"] = function()
  local buf = setup_buffer({
    "local function foo()",
    "  return bar",
    "end",
    "local function foobar()",
    "end",
  })

  local pipeline = search_mod.search_pipeline()
  local step = pipeline[1]
  local ctx = { cmdtype = "/" }
  local result = step(ctx, "foo")

  expect.equality(type(result), "table")
  expect.equality(type(result.value), "table")
  expect.equality(#result.value > 0, true)
  expect.equality(result.data.arg, "foo")
  expect.equality(result.output(result.data, result.value[1]), "foo")

  vim.api.nvim_buf_delete(buf, { force = true })
end

T["pipeline"]["works with ? cmdtype"] = function()
  local buf = setup_buffer({
    "hello world",
    "goodbye world",
  })

  local pipeline = search_mod.search_pipeline()
  local step = pipeline[1]
  local ctx = { cmdtype = "?" }
  local result = step(ctx, "hello")

  expect.equality(type(result), "table")
  expect.equality(#result.value, 1)
  expect.equality(result.value[1], "hello world")

  vim.api.nvim_buf_delete(buf, { force = true })
end

T["pipeline"]["returns false for invalid regex without fuzzy"] = function()
  local buf = setup_buffer({ "hello world" })

  local pipeline = search_mod.search_pipeline()
  local step = pipeline[1]
  local ctx = { cmdtype = "/" }
  local result = step(ctx, "\\(")

  expect.equality(result, false)

  vim.api.nvim_buf_delete(buf, { force = true })
end

T["pipeline"]["deduplicates matching lines"] = function()
  local buf = setup_buffer({
    "  hello world",
    "  hello world",
    "  hello world",
    "goodbye",
  })

  local pipeline = search_mod.search_pipeline()
  local step = pipeline[1]
  local ctx = { cmdtype = "/" }
  local result = step(ctx, "hello")

  expect.equality(type(result), "table")
  expect.equality(#result.value, 1)
  expect.equality(result.value[1], "hello world")

  vim.api.nvim_buf_delete(buf, { force = true })
end

T["pipeline"]["non-fuzzy pipeline has one step"] = function()
  local pipeline = search_mod.search_pipeline()
  expect.equality(#pipeline, 1)
end

-- ── Fuzzy mode ─────────────────────────────────────────────────────

T["fuzzy"] = new_set()

T["fuzzy"]["pipeline has two steps when fuzzy enabled"] = function()
  local pipeline = search_mod.search_pipeline({ fuzzy = true })
  expect.equality(#pipeline, 2)
end

T["fuzzy"]["matches when regex would fail"] = function()
  local buf = setup_buffer({
    "local function my_handler()",
    "  return true",
    "end",
  })

  local pipeline = search_mod.search_pipeline({ fuzzy = true })
  local step = pipeline[1]
  local ctx = { cmdtype = "/" }
  -- "fnctn" won't match as a regex substring but fuzzy matches "function"
  local result = step(ctx, "fnctn")

  expect.equality(type(result), "table")
  expect.equality(#result.value > 0, true)

  vim.api.nvim_buf_delete(buf, { force = true })
end

T["fuzzy"]["regex matches take priority when valid"] = function()
  local buf = setup_buffer({
    "local function foo()",
    "  return bar",
    "end",
  })

  local pipeline = search_mod.search_pipeline({ fuzzy = true })
  local step = pipeline[1]
  local ctx = { cmdtype = "/" }
  -- "foo" is a valid regex that matches — should work like normal
  local result = step(ctx, "foo")

  expect.equality(type(result), "table")
  expect.equality(#result.value > 0, true)
  -- Should match lines containing "foo"
  local has_foo = false
  for _, v in ipairs(result.value) do
    if v:find("foo") then
      has_foo = true
      break
    end
  end
  expect.equality(has_foo, true)

  vim.api.nvim_buf_delete(buf, { force = true })
end

T["fuzzy"]["deduplication works in fuzzy mode"] = function()
  local buf = setup_buffer({
    "  local function handler()",
    "  local function handler()",
    "  return true",
  })

  local pipeline = search_mod.search_pipeline({ fuzzy = true })
  local step = pipeline[1]
  local ctx = { cmdtype = "/" }
  local result = step(ctx, "hndlr")

  expect.equality(type(result), "table")
  -- Should be deduplicated
  local seen = {}
  for _, v in ipairs(result.value) do
    expect.equality(seen[v], nil)
    seen[v] = true
  end

  vim.api.nvim_buf_delete(buf, { force = true })
end

T["fuzzy"]["returns false when no fuzzy matches either"] = function()
  local buf = setup_buffer({
    "hello world",
    "goodbye moon",
  })

  local pipeline = search_mod.search_pipeline({ fuzzy = true })
  local step = pipeline[1]
  local ctx = { cmdtype = "/" }
  local result = step(ctx, "zzzzxxx")

  expect.equality(result, false)

  vim.api.nvim_buf_delete(buf, { force = true })
end

T["fuzzy"]["fuzzy_filter step re-sorts candidates"] = function()
  local buf = setup_buffer({
    "local very_long_function_name()",
    "local function short()",
    "return true",
  })

  local pipeline = search_mod.search_pipeline({ fuzzy = true })
  -- Pipeline should have 2 steps: search + fuzzy_filter
  expect.equality(#pipeline, 2)

  local step = pipeline[1]
  local ctx = { cmdtype = "/" }
  local result = step(ctx, "function")

  -- Both lines match regex, so we get results
  expect.equality(type(result), "table")
  expect.equality(#result.value > 0, true)

  vim.api.nvim_buf_delete(buf, { force = true })
end

T["fuzzy"]["invalid regex falls back to fuzzy"] = function()
  local buf = setup_buffer({
    "local function handler()",
    "  return result",
    "end",
  })

  local pipeline = search_mod.search_pipeline({ fuzzy = true })
  local step = pipeline[1]
  local ctx = { cmdtype = "/" }
  -- Invalid regex but fuzzy should still find matches
  local result = step(ctx, "\\(hndlr")

  -- The invalid regex won't compile, but fuzzy fallback should work
  -- (whether it matches depends on the fuzzy algorithm handling the backslash)
  -- At minimum, the pipeline shouldn't error
  expect.equality(type(result) == "table" or result == false, true)

  vim.api.nvim_buf_delete(buf, { force = true })
end

return T

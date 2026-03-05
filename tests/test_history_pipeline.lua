local MiniTest = require("mini.test")
local new_set = MiniTest.new_set
local expect = MiniTest.expect

local T = new_set()

local history = require("wildest.pipeline.history")

-- Seed some command history entries for testing
local function setup_history()
  vim.fn.histadd(":", "set number")
  vim.fn.histadd(":", "set relativenumber")
  vim.fn.histadd(":", "edit foo.lua")
  vim.fn.histadd(":", "write")
  vim.fn.histadd(":", "set foldmethod=indent")
  vim.fn.histadd(":", "quit")
  vim.fn.histadd(":", "help autocmd")
  vim.fn.histadd(":", "set tabstop=4")
end

T["history()"] = new_set({
  hooks = {
    pre_case = setup_history,
  },
})

T["history()"]["returns function"] = function()
  local step = history.history()
  expect.equality(type(step), "function")
end

T["history()"]["returns entries for empty input"] = function()
  local step = history.history()
  local ctx = { cmdtype = ":" }
  local result = step(ctx, "")
  expect.equality(type(result), "table")
  expect.equality(#result > 0, true)
end

T["history()"]["substring matching by default"] = function()
  local step = history.history()
  local ctx = { cmdtype = ":" }
  local result = step(ctx, "fold")
  expect.equality(type(result), "table")
  -- Should find "set foldmethod=indent" via substring
  local found = false
  for _, entry in ipairs(result) do
    if entry:find("fold") then
      found = true
    end
  end
  expect.equality(found, true)
end

T["history()"]["prefix matching only matches start"] = function()
  local step = history.history({ prefix = true })
  local ctx = { cmdtype = ":" }
  local result = step(ctx, "set")
  expect.equality(type(result), "table")
  -- All results must start with "set" (case-insensitive)
  for _, entry in ipairs(result) do
    expect.equality(entry:lower():sub(1, 3), "set")
  end
end

T["history()"]["prefix matching excludes non-prefix matches"] = function()
  local step = history.history({ prefix = true })
  local ctx = { cmdtype = ":" }
  local result = step(ctx, "fold")
  -- "set foldmethod=indent" contains "fold" but doesn't start with it
  -- so prefix mode should NOT return it
  if result then
    for _, entry in ipairs(result) do
      expect.equality(entry:lower():sub(1, 4), "fold")
    end
  end
end

T["history()"]["returns false when no matches"] = function()
  local step = history.history()
  local ctx = { cmdtype = ":" }
  local result = step(ctx, "zzzznonexistentzzzz")
  expect.equality(result, false)
end

T["history()"]["respects max option"] = function()
  local step = history.history({ max = 2 })
  local ctx = { cmdtype = ":" }
  local result = step(ctx, "")
  expect.equality(type(result), "table")
  expect.equality(#result <= 2, true)
end

T["history()"]["deduplicates entries"] = function()
  -- Add duplicates
  vim.fn.histadd(":", "duplicate command")
  vim.fn.histadd(":", "duplicate command")
  vim.fn.histadd(":", "duplicate command")

  local step = history.history()
  local ctx = { cmdtype = ":" }
  local result = step(ctx, "duplicate")
  expect.equality(type(result), "table")

  local count = 0
  for _, entry in ipairs(result) do
    if entry == "duplicate command" then
      count = count + 1
    end
  end
  expect.equality(count, 1)
end

T["history()"]["case insensitive matching"] = function()
  vim.fn.histadd(":", "MyUpperCase")

  local step = history.history()
  local ctx = { cmdtype = ":" }
  local result = step(ctx, "myupper")
  expect.equality(type(result), "table")
  local found = false
  for _, entry in ipairs(result) do
    if entry == "MyUpperCase" then
      found = true
    end
  end
  expect.equality(found, true)
end

T["history()"]["prefix matching is case insensitive"] = function()
  vim.fn.histadd(":", "SetLocal test")

  local step = history.history({ prefix = true })
  local ctx = { cmdtype = ":" }
  local result = step(ctx, "setlocal")
  expect.equality(type(result), "table")
  local found = false
  for _, entry in ipairs(result) do
    if entry == "SetLocal test" then
      found = true
    end
  end
  expect.equality(found, true)
end

return T

local MiniTest = require("mini.test")
local new_set = MiniTest.new_set
local expect = MiniTest.expect

local T = new_set()

T["resolve()"] = new_set()

T["resolve()"]["passes through functions"] = function()
  local actions = require("wildest.actions")
  local fn = function() end
  expect.equality(actions.resolve(fn), fn)
end

T["resolve()"]["resolves registered names"] = function()
  local actions = require("wildest.actions")
  local fn = function() end
  actions.register("test_action", fn)
  expect.equality(actions.resolve("test_action"), fn)
end

T["resolve()"]["errors on unknown name"] = function()
  local actions = require("wildest.actions")
  local ok, err = pcall(actions.resolve, "nonexistent_action_xyz")
  expect.equality(ok, false)
  expect.equality(type(err), "string")
end

T["resolve()"]["errors on invalid type"] = function()
  local actions = require("wildest.actions")
  local ok, err = pcall(actions.resolve, 42)
  expect.equality(ok, false)
  expect.equality(type(err), "string")
end

T["register()"] = new_set()

T["register()"]["adds new action"] = function()
  local actions = require("wildest.actions")
  local fn = function() end
  actions.register("my_custom", fn)
  expect.equality(actions.resolve("my_custom"), fn)
end

T["register()"]["overrides existing action"] = function()
  local actions = require("wildest.actions")
  local fn1 = function() end
  local fn2 = function() end
  actions.register("override_me", fn1)
  actions.register("override_me", fn2)
  expect.equality(actions.resolve("override_me"), fn2)
end

T["list()"] = new_set()

T["list()"]["returns sorted names"] = function()
  local actions = require("wildest.actions")
  local names = actions.list()
  expect.equality(type(names), "table")
  -- Check sorting
  for i = 2, #names do
    expect.equality(names[i - 1] < names[i], true)
  end
end

T["list()"]["contains all built-in actions"] = function()
  local actions = require("wildest.actions")
  local names = actions.list()
  local set = {}
  for _, n in ipairs(names) do
    set[n] = true
  end
  local builtins = {
    "open_split",
    "open_vsplit",
    "open_tab",
    "send_to_quickfix",
    "send_to_loclist",
    "yank",
    "toggle_preview",
  }
  for _, b in ipairs(builtins) do
    expect.equality(set[b], true)
  end
end

T["built-in actions"] = new_set()

T["built-in actions"]["all 7 are registered and resolvable"] = function()
  local actions = require("wildest.actions")
  local builtins = {
    "open_split",
    "open_vsplit",
    "open_tab",
    "send_to_quickfix",
    "send_to_loclist",
    "yank",
    "toggle_preview",
  }
  for _, name in ipairs(builtins) do
    local fn = actions.resolve(name)
    expect.equality(type(fn), "function")
  end
end

T["build_context()"] = new_set()

T["build_context()"]["returns nil when no active session"] = function()
  local actions = require("wildest.actions")
  local ctx = actions.build_context()
  expect.equality(ctx, nil)
end

return T

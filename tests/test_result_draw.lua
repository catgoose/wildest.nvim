local MiniTest = require("mini.test")
local new_set = MiniTest.new_set
local expect = MiniTest.expect

local T = new_set()

local result_mod = require("wildest.pipeline.result")

T["result draw"] = new_set()

T["result draw"]["result with draw transform stores it"] = function()
  local draw_fn = function(_data, candidate)
    return "[" .. candidate .. "]"
  end
  local step = result_mod.result({ draw = draw_fn })
  local ctx = { input = "test" }
  local result = step(ctx, { "a", "b" })
  expect.equality(type(result.draw), "function")
  expect.equality(result.draw(result.data, "hello"), "[hello]")
end

T["result draw"]["result without draw has no draw field"] = function()
  local step = result_mod.result({})
  local ctx = { input = "test" }
  local result = step(ctx, { "a", "b" })
  expect.equality(result.draw, nil)
end

T["result draw"]["draw and output are independent"] = function()
  local output_fn = function(_data, candidate)
    return "out:" .. candidate
  end
  local draw_fn = function(_data, candidate)
    return "vis:" .. candidate
  end
  local step = result_mod.result({ output = output_fn, draw = draw_fn })
  local ctx = { input = "test" }
  local result = step(ctx, { "a" })
  expect.equality(result.output(result.data, "x"), "out:x")
  expect.equality(result.draw(result.data, "x"), "vis:x")
end

return T

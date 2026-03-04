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

T["result draw"]["draw returning nil falls back to raw in renderer"] = function()
  -- Simulate the fallback pattern used in base_popupmenu/wildmenu:
  --   candidate = result.draw(data, raw) or raw
  local draw_fn = function(_data, _candidate)
    return nil
  end
  local step = result_mod.result({ draw = draw_fn })
  local ctx = { input = "test" }
  local result = step(ctx, { "original" })
  -- The renderer uses: result.draw(data, raw) or raw
  local displayed = result.draw(result.data, "original") or "original"
  expect.equality(displayed, "original")
end

T["result draw"]["draw receives correct data context"] = function()
  local received_data = nil
  local draw_fn = function(data, candidate)
    received_data = data
    return candidate
  end
  local step = result_mod.result({ draw = draw_fn, data = { custom = "value" } })
  local ctx = { input = "cmd arg", arg = "arg" }
  local result = step(ctx, { "item" })
  result.draw(result.data, "item")
  expect.equality(received_data.input, "cmd arg")
  expect.equality(received_data.custom, "value")
end

T["result draw"]["empty candidates returns false regardless of draw"] = function()
  local step = result_mod.result({ draw = function() return "x" end })
  local ctx = { input = "test" }
  local result = step(ctx, {})
  expect.equality(result, false)
end

return T

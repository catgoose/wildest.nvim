local MiniTest = require("mini.test")
local new_set = MiniTest.new_set
local expect = MiniTest.expect

local T = new_set()

local mux = require("wildest.renderer.mux")

-- Minimal mock renderer
local function mock_renderer()
  local r = { rendered = false, hidden = false }
  function r:render(_ctx, _result)
    self.rendered = true
  end
  function r:hide()
    self.hidden = true
  end
  return r
end

T["dict routing"] = new_set()

T["dict routing"]["routes by cmdtype"] = function()
  local r1 = mock_renderer()
  local r2 = mock_renderer()
  local m = mux.new({ [":"] = r1, ["/"] = r2 })
  m:render({ cmdtype = ":" }, { value = {} })
  expect.equality(r1.rendered, true)
  expect.equality(r2.rendered, false)
end

T["list routing"] = new_set()

T["list routing"]["first match wins"] = function()
  local r1 = mock_renderer()
  local r2 = mock_renderer()
  local m = mux.new({
    { function(ctx) return ctx.cmdtype == ":" end, r1 },
    { function(ctx) return ctx.cmdtype == ":" end, r2 },
  })
  m:render({ cmdtype = ":" }, { value = {} })
  expect.equality(r1.rendered, true)
  expect.equality(r2.rendered, false)
end

T["list routing"]["falls back to second when first doesn't match"] = function()
  local r1 = mock_renderer()
  local r2 = mock_renderer()
  local m = mux.new({
    { function(ctx) return ctx.cmdtype == "/" end, r1 },
    { function(ctx) return ctx.cmdtype == ":" end, r2 },
  })
  m:render({ cmdtype = ":" }, { value = {} })
  expect.equality(r1.rendered, false)
  expect.equality(r2.rendered, true)
end

T["list routing"]["hide hides all unique renderers"] = function()
  local r1 = mock_renderer()
  local r2 = mock_renderer()
  local m = mux.new({
    { function() return true end, r1 },
    { function() return true end, r2 },
  })
  m:hide()
  expect.equality(r1.hidden, true)
  expect.equality(r2.hidden, true)
end

T["list routing"]["no match returns nil gracefully"] = function()
  local r1 = mock_renderer()
  local m = mux.new({
    { function() return false end, r1 },
  })
  -- Should not error
  m:render({ cmdtype = ":" }, { value = {} })
  expect.equality(r1.rendered, false)
end

return T

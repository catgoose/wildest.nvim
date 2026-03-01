local MiniTest = require("mini.test")
local new_set = MiniTest.new_set
local expect = MiniTest.expect

local T = new_set()

local BaseComponent = require("wildest.renderer.components.base")

T["BaseComponent"] = new_set()

T["BaseComponent"]["render() returns empty table"] = function()
  local comp = setmetatable({}, { __index = BaseComponent })
  expect.equality(comp:render({}), {})
end

T["BaseComponent"]["render_left() delegates to render()"] = function()
  local comp = setmetatable({}, { __index = BaseComponent })
  function comp:render(_ctx)
    return { { "test", "hl" } }
  end
  expect.equality(comp:render_left({}), { { "test", "hl" } })
end

T["BaseComponent"]["render_right() delegates to render()"] = function()
  local comp = setmetatable({}, { __index = BaseComponent })
  function comp:render(_ctx)
    return { { "right", "hl" } }
  end
  expect.equality(comp:render_right({}), { { "right", "hl" } })
end

T["BaseComponent"]["render_left/render_right can be overridden independently"] = function()
  local comp = setmetatable({}, { __index = BaseComponent })
  function comp:render_left(_ctx)
    return { { "<", "hl" } }
  end
  function comp:render_right(_ctx)
    return { { ">", "hl" } }
  end
  -- render() still returns default empty
  expect.equality(comp:render({}), {})
  expect.equality(comp:render_left({}), { { "<", "hl" } })
  expect.equality(comp:render_right({}), { { ">", "hl" } })
end

T["Component inheritance"] = new_set()

T["Component inheritance"]["arrows inherits from BaseComponent"] = function()
  local arrows = require("wildest.renderer.components.arrows")
  local comp = arrows.new()
  -- Should have render_left and render_right from its own definition
  expect.equality(type(comp.render_left), "function")
  expect.equality(type(comp.render_right), "function")
  -- render delegates to render_left/render_right via BaseComponent
  expect.equality(type(comp.render), "function")
end

T["Component inheritance"]["index inherits from BaseComponent"] = function()
  local index = require("wildest.renderer.components.index")
  local comp = index.new()
  expect.equality(type(comp.render), "function")
  expect.equality(type(comp.render_left), "function")
  expect.equality(type(comp.render_right), "function")
end

T["Component inheritance"]["separator inherits from BaseComponent"] = function()
  local separator = require("wildest.renderer.components.separator")
  local comp = separator.new()
  expect.equality(type(comp.render), "function")
  expect.equality(type(comp.render_left), "function")
end

T["Component inheritance"]["empty_message inherits from BaseComponent"] = function()
  local empty_message = require("wildest.renderer.components.empty_message")
  local comp = empty_message.new()
  expect.equality(type(comp.render), "function")
  expect.equality(type(comp.render_left), "function")
end

T["Component inheritance"]["scrollbar inherits from BaseComponent"] = function()
  local scrollbar = require("wildest.renderer.components.scrollbar")
  local comp = scrollbar.new()
  expect.equality(type(comp.render), "function")
  expect.equality(type(comp.render_left), "function")
end

T["Component inheritance"]["condition inherits from BaseComponent"] = function()
  local condition = require("wildest.renderer.components.condition")
  local comp = condition.new(function()
    return true
  end, "yes", "no")
  expect.equality(type(comp.render), "function")
  expect.equality(type(comp.render_left), "function")
end

return T

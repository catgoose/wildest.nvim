local MiniTest = require("mini.test")
local new_set = MiniTest.new_set
local expect = MiniTest.expect

local T = new_set()

local BasePopupmenu = require("wildest.renderer.base_popupmenu")

T["BasePopupmenu"] = new_set()

T["BasePopupmenu"]["pad_to_height adds padding lines"] = function()
  local renderer = setmetatable({
    _state = { highlights = { default = "Normal" } },
  }, { __index = BasePopupmenu })

  local lines = { "line1" }
  local line_highlights = { { spans = {}, base_hl = "Normal" } }

  renderer:pad_to_height(lines, line_highlights, 3, 10)
  expect.equality(#lines, 3)
  expect.equality(#line_highlights, 3)
  expect.equality(lines[2], string.rep(" ", 10))
  expect.equality(lines[3], string.rep(" ", 10))
  expect.equality(line_highlights[2].base_hl, "Normal")
end

T["BasePopupmenu"]["pad_to_height does nothing when already at target"] = function()
  local renderer = setmetatable({
    _state = { highlights = { default = "Normal" } },
  }, { __index = BasePopupmenu })

  local lines = { "a", "b", "c" }
  local line_highlights = { { spans = {} }, { spans = {} }, { spans = {} } }

  renderer:pad_to_height(lines, line_highlights, 3, 5)
  expect.equality(#lines, 3)
end

T["BasePopupmenu"]["clamp_height removes excess lines"] = function()
  local renderer = setmetatable({
    _state = {},
  }, { __index = BasePopupmenu })

  local lines = { "a", "b", "c", "d", "e" }
  local line_highlights = { {}, {}, {}, {}, {} }

  local height = renderer:clamp_height(lines, line_highlights, 3)
  expect.equality(height, 3)
  expect.equality(#lines, 3)
  expect.equality(#line_highlights, 3)
end

T["BasePopupmenu"]["clamp_height does nothing when under max"] = function()
  local renderer = setmetatable({
    _state = {},
  }, { __index = BasePopupmenu })

  local lines = { "a", "b" }
  local line_highlights = { {}, {} }

  local height = renderer:clamp_height(lines, line_highlights, 5)
  expect.equality(height, 2)
  expect.equality(#lines, 2)
end

T["BasePopupmenu"]["clamp_height ensures minimum of 1"] = function()
  local renderer = setmetatable({
    _state = {},
  }, { __index = BasePopupmenu })

  local lines = { "a", "b", "c" }
  local line_highlights = { {}, {}, {} }

  local height = renderer:clamp_height(lines, line_highlights, 0)
  expect.equality(height, 1)
  expect.equality(#lines, 1)
end

T["BasePopupmenu"]["resolve_title handles string"] = function()
  local renderer = setmetatable({
    _state = { title = "My Title" },
  }, { __index = BasePopupmenu })

  expect.equality(renderer:resolve_title(), "My Title")
end

T["BasePopupmenu"]["resolve_title handles nil"] = function()
  local renderer = setmetatable({
    _state = { title = nil },
  }, { __index = BasePopupmenu })

  expect.equality(renderer:resolve_title(), nil)
end

T["Renderer inheritance"] = new_set()

T["Renderer inheritance"]["popupmenu has hide method from base"] = function()
  local popupmenu = require("wildest.renderer.popupmenu")
  local renderer = popupmenu.new()
  expect.equality(type(renderer.hide), "function")
  expect.equality(type(renderer.render), "function")
  expect.equality(type(renderer.render_candidates), "function")
  expect.equality(type(renderer.pad_to_height), "function")
  expect.equality(type(renderer.clamp_height), "function")
  expect.equality(type(renderer.flush_buffer), "function")
  expect.equality(type(renderer.resolve_title), "function")
end

T["Renderer inheritance"]["popupmenu_border has hide method from base"] = function()
  local popupmenu_border = require("wildest.renderer.popupmenu_border")
  local renderer = popupmenu_border.new()
  expect.equality(type(renderer.hide), "function")
  expect.equality(type(renderer.render), "function")
  expect.equality(type(renderer.render_candidates), "function")
end

T["Renderer inheritance"]["popupmenu_palette has hide method from base"] = function()
  local popupmenu_palette = require("wildest.renderer.popupmenu_palette")
  local renderer = popupmenu_palette.new()
  expect.equality(type(renderer.hide), "function")
  expect.equality(type(renderer.render), "function")
  expect.equality(type(renderer.render_candidates), "function")
end

return T

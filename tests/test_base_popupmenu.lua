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

T["BasePopupmenu"]["chrome_line_count returns 0 for empty"] = function()
  local renderer = setmetatable({
    _state = { top = {}, bottom = {} },
  }, { __index = BasePopupmenu })

  expect.equality(renderer:chrome_line_count("top"), 0)
  expect.equality(renderer:chrome_line_count("bottom"), 0)
end

T["BasePopupmenu"]["chrome_line_count returns correct count"] = function()
  local renderer = setmetatable({
    _state = { top = { "a", "b" }, bottom = { "c" } },
  }, { __index = BasePopupmenu })

  expect.equality(renderer:chrome_line_count("top"), 2)
  expect.equality(renderer:chrome_line_count("bottom"), 1)
end

T["BasePopupmenu"]["chrome_line_count returns 0 for nil components"] = function()
  local renderer = setmetatable({
    _state = {},
  }, { __index = BasePopupmenu })

  expect.equality(renderer:chrome_line_count("top"), 0)
  expect.equality(renderer:chrome_line_count("bottom"), 0)
end

T["BasePopupmenu"]["render_chrome returns empty for no components"] = function()
  local renderer = setmetatable({
    _state = { top = {}, bottom = {}, highlights = { default = "Normal" } },
  }, { __index = BasePopupmenu })

  local ctx = { selected = -1 }
  local result = { value = {} }
  local lines, hls, count = renderer:render_chrome("top", ctx, result, 0, 0, 0, 40)
  expect.equality(count, 0)
  expect.equality(#lines, 0)
  expect.equality(#hls, 0)
end

T["BasePopupmenu"]["render_chrome resolves string components"] = function()
  local renderer = setmetatable({
    _state = { top = { "header" }, bottom = {}, highlights = { default = "Normal" } },
  }, { __index = BasePopupmenu })

  local ctx = { selected = -1 }
  local result = { value = {} }
  local lines, hls, count = renderer:render_chrome("top", ctx, result, 0, 0, 0, 20)
  expect.equality(count, 1)
  expect.equality(lines[1]:sub(1, 6), "header")
  expect.equality(hls[1].base_hl, "Normal")
end

T["BasePopupmenu"]["paginate suppresses empty_message during delay"] = function()
  local renderer = setmetatable({
    _state = {
      highlights = { default = "Normal" },
      empty_message = "No results",
      empty_message_first_draw_delay = 500,
      page = { -1, -1 },
      win = -1,
    },
  }, { __index = BasePopupmenu })

  -- First call within delay window should suppress empty_message
  local ctx = { selected = -1, session_id = 1 }
  local ps, pe, show_empty = renderer:paginate(ctx, 0, 10)
  -- show_empty is suppressed, so renderer hides (ps=nil)
  expect.equality(ps, nil)
  expect.equality(show_empty, false)
end

T["BasePopupmenu"]["paginate shows empty_message after delay expires"] = function()
  local renderer = setmetatable({
    _state = {
      highlights = { default = "Normal" },
      empty_message = "No results",
      empty_message_first_draw_delay = 1, -- 1ms delay
      page = { -1, -1 },
      win = -1,
      _delay_session_id = 1,
      _first_draw_time = 0, -- epoch — long past the 1ms delay
    },
  }, { __index = BasePopupmenu })

  -- Delay has long expired, so show_empty should be truthy (the message string)
  local ctx = { selected = -1, session_id = 1 }
  local ps, pe, show_empty = renderer:paginate(ctx, 0, 10)
  expect.equality(show_empty ~= false, true)
  -- page_start/page_end are -1 (not nil) since we're showing empty message
  expect.equality(ps, -1)
end

T["BasePopupmenu"]["paginate without delay always shows empty_message"] = function()
  local renderer = setmetatable({
    _state = {
      highlights = { default = "Normal" },
      empty_message = "No results",
      page = { -1, -1 },
      win = -1,
    },
  }, { __index = BasePopupmenu })

  local ctx = { selected = -1, session_id = 1 }
  local ps, pe, show_empty = renderer:paginate(ctx, 0, 10)
  -- show_empty is the message string (truthy), not boolean true
  expect.equality(show_empty ~= false, true)
  expect.equality(ps, -1)
end

T["BasePopupmenu"]["paginate resets delay tracking on new session"] = function()
  local renderer = setmetatable({
    _state = {
      highlights = { default = "Normal" },
      empty_message = "No results",
      empty_message_first_draw_delay = 500,
      page = { -1, -1 },
      win = -1,
      _delay_session_id = 1,
      _first_draw_time = 0, -- long ago
    },
  }, { __index = BasePopupmenu })

  -- New session_id resets tracking
  local ctx = { selected = -1, session_id = 2 }
  local ps, pe, show_empty = renderer:paginate(ctx, 0, 10)
  -- New session, first draw time is reset, within delay window = suppress
  expect.equality(ps, nil)
  expect.equality(show_empty, false)
  -- Session ID should be updated
  expect.equality(renderer._state._delay_session_id, 2)
end

T["BasePopupmenu"]["render_candidates skipped when show_empty in popupmenu"] = function()
  -- Regression: popupmenu.lua previously called render_candidates unconditionally
  -- even when show_empty was truthy. With page_start=-1, the loop ran once with a
  -- nil candidate, crashing inside render_line → nvim_strwidth(nil).
  local renderer = setmetatable({
    _state = {
      highlights = { default = "Normal", selected = "Visual", accent = "Normal", selected_accent = "Visual" },
      empty_message = "No results",
      page = { -1, -1 },
      win = -1,
      max_height = 10,
      min_height = 0,
      fixed_height = true,
      offset = 0,
      left = {},
      right = {},
      top = {},
      bottom = {},
      zindex = 250,
      buf = -1,
      ns_id = -1,
      run_id = -1,
    },
  }, { __index = BasePopupmenu })

  -- Simulate what paginate returns for total=0 with empty_message
  local page_start, page_end, show_empty = renderer:paginate({ selected = -1, run_id = 1, session_id = 1 }, 0, 10)
  expect.equality(page_start, -1)
  expect.equality(page_end, -1)
  expect.equality(show_empty ~= false, true)

  -- The key assertion: render_candidates with (-1, -1) should NOT be called
  -- because show_empty is truthy. Verify it would crash with nil candidate.
  local result = { value = {} }
  local ok = pcall(function()
    renderer:render_candidates(result, { selected = -1 }, -1, -1, 40)
  end)
  -- This SHOULD fail because candidates[0] is nil
  expect.equality(ok, false)
end

T["BasePopupmenu"]["paginate accounts for columns in page size"] = function()
  local renderer = setmetatable({
    _state = {
      highlights = { default = "Normal" },
      page = { -1, -1 },
      columns = 3,
      win = -1,
    },
  }, { __index = BasePopupmenu })

  -- With 3 columns and max_height=4, effective page size should be 12
  local ctx = { selected = 0, session_id = 1 }
  local ps, pe, show_empty = renderer:paginate(ctx, 20, 4)
  expect.equality(show_empty, false)
  -- page should span 12 items (4 rows * 3 cols)
  expect.equality(pe - ps + 1, 12)
end

T["BasePopupmenu"]["paginate defaults to 1 column"] = function()
  local renderer = setmetatable({
    _state = {
      highlights = { default = "Normal" },
      page = { -1, -1 },
      -- no columns field
      win = -1,
    },
  }, { __index = BasePopupmenu })

  local ctx = { selected = 0, session_id = 1 }
  local ps, pe, show_empty = renderer:paginate(ctx, 20, 4)
  expect.equality(show_empty, false)
  -- page should span 4 items (4 rows * 1 col)
  expect.equality(pe - ps + 1, 4)
end

T["BasePopupmenu"]["render_one_candidate exists and returns line"] = function()
  local renderer = setmetatable({
    _state = {
      highlights = { default = "Normal", selected = "Visual", accent = "Normal", selected_accent = "Visual" },
      left = {},
      right = {},
      highlighter = nil,
      page = { 0, 1 },
    },
  }, { __index = BasePopupmenu })

  local result = { value = { "hello", "world" }, data = {} }
  local ctx = { selected = -1 }
  local line, spans, base_hl = renderer:render_one_candidate(result, ctx, renderer._state, "", 0, 20)
  expect.equality(type(line), "string")
  expect.equality(type(spans), "table")
  expect.equality(base_hl, "Normal")
end

T["BasePopupmenu"]["render_one_candidate marks selected"] = function()
  local renderer = setmetatable({
    _state = {
      highlights = { default = "Normal", selected = "Visual", accent = "Normal", selected_accent = "Visual" },
      left = {},
      right = {},
      highlighter = nil,
      page = { 0, 1 },
    },
  }, { __index = BasePopupmenu })

  local result = { value = { "hello", "world" }, data = {} }
  local ctx = { selected = 0 }
  local _, _, base_hl = renderer:render_one_candidate(result, ctx, renderer._state, "", 0, 20)
  expect.equality(base_hl, "Visual")
end

T["BasePopupmenu"]["render_candidates delegates to grid when columns > 1"] = function()
  local renderer = setmetatable({
    _state = {
      highlights = { default = "Normal", selected = "Visual", accent = "Normal", selected_accent = "Visual" },
      left = {},
      right = {},
      highlighter = nil,
      columns = 2,
      page = { 0, 3 },
    },
  }, { __index = BasePopupmenu })

  local result = { value = { "alpha", "beta", "gamma", "delta" }, data = {} }
  local ctx = { selected = -1 }
  local lines, hls = renderer:render_candidates(result, ctx, 0, 3, 40)
  -- 4 candidates in 2 columns = 2 rows
  expect.equality(#lines, 2)
  expect.equality(#hls, 2)
end

T["BasePopupmenu"]["render_candidates_grid pads incomplete row"] = function()
  local renderer = setmetatable({
    _state = {
      highlights = { default = "Normal", selected = "Visual", accent = "Normal", selected_accent = "Visual" },
      left = {},
      right = {},
      highlighter = nil,
      columns = 3,
      page = { 0, 4 },
    },
  }, { __index = BasePopupmenu })

  -- 5 candidates in 3 columns = 2 rows (3 + 2, second row padded)
  local result = { value = { "a", "b", "c", "d", "e" }, data = {} }
  local ctx = { selected = -1 }
  local lines, hls = renderer:render_candidates_grid(result, ctx, 0, 4, 30)
  expect.equality(#lines, 2)
  -- Each line should be 30 chars wide (padded to full width)
  for _, line in ipairs(lines) do
    expect.equality(vim.api.nvim_strwidth(line), 30)
  end
end

T["BasePopupmenu"]["render_candidates_grid single candidate in grid"] = function()
  local renderer = setmetatable({
    _state = {
      highlights = { default = "Normal", selected = "Visual", accent = "Normal", selected_accent = "Visual" },
      left = {},
      right = {},
      highlighter = nil,
      columns = 3,
      page = { 0, 0 },
    },
  }, { __index = BasePopupmenu })

  local result = { value = { "only" }, data = {} }
  local ctx = { selected = -1 }
  local lines, hls = renderer:render_candidates_grid(result, ctx, 0, 0, 30)
  expect.equality(#lines, 1)
  expect.equality(vim.api.nvim_strwidth(lines[1]), 30)
end

T["BasePopupmenu"]["render_candidates_grid reverse order"] = function()
  local renderer = setmetatable({
    _state = {
      highlights = { default = "Normal", selected = "Visual", accent = "Normal", selected_accent = "Visual" },
      left = {},
      right = {},
      highlighter = nil,
      columns = 2,
      page = { 0, 3 },
    },
  }, { __index = BasePopupmenu })

  local result = { value = { "first", "second", "third", "fourth" }, data = {} }
  local ctx = { selected = -1 }
  local lines_fwd, _ = renderer:render_candidates_grid(result, ctx, 0, 3, 40)
  local lines_rev, _ = renderer:render_candidates_grid(result, ctx, 0, 3, 40, { reverse = true })
  -- Reversed order should produce different first line
  expect.no_equality(lines_fwd[1], lines_rev[1])
end

T["Renderer inheritance"] = new_set()

T["Renderer inheritance"]["popupmenu has hide method from base"] = function()
  local popupmenu = require("wildest.renderer.popupmenu")
  local renderer = popupmenu.new()
  expect.equality(type(renderer.hide), "function")
  expect.equality(type(renderer.render), "function")
  expect.equality(type(renderer.render_candidates), "function")
  expect.equality(type(renderer.render_one_candidate), "function")
  expect.equality(type(renderer.render_candidates_grid), "function")
  expect.equality(type(renderer.pad_to_height), "function")
  expect.equality(type(renderer.clamp_height), "function")
  expect.equality(type(renderer.flush_buffer), "function")
  expect.equality(type(renderer.resolve_title), "function")
  expect.equality(type(renderer.render_chrome), "function")
  expect.equality(type(renderer.chrome_line_count), "function")
end

T["Renderer inheritance"]["popupmenu_border has hide method from base"] = function()
  local popupmenu_border = require("wildest.renderer.popupmenu_border")
  local renderer = popupmenu_border.new()
  expect.equality(type(renderer.hide), "function")
  expect.equality(type(renderer.render), "function")
  expect.equality(type(renderer.render_candidates), "function")
  expect.equality(type(renderer.render_chrome), "function")
  expect.equality(type(renderer.chrome_line_count), "function")
end

T["Renderer inheritance"]["popupmenu_palette has hide method from base"] = function()
  local popupmenu_palette = require("wildest.renderer.popupmenu_palette")
  local renderer = popupmenu_palette.new()
  expect.equality(type(renderer.hide), "function")
  expect.equality(type(renderer.render), "function")
  expect.equality(type(renderer.render_candidates), "function")
  expect.equality(type(renderer.render_chrome), "function")
  expect.equality(type(renderer.chrome_line_count), "function")
end

return T

---@diagnostic disable: need-check-nil, undefined-global
local MiniTest = require("mini.test")
local new_set = MiniTest.new_set
local expect = MiniTest.expect

local T = new_set()

local renderer_util = require("wildest.renderer")

T["get_query()"] = new_set()

T["get_query()"]["returns query from result.data.query"] = function()
  local result = { data = { query = "hello" } }
  expect.equality(renderer_util.get_query(result), "hello")
end

T["get_query()"]["falls back to data.arg"] = function()
  local result = { data = { arg = "foo" } }
  expect.equality(renderer_util.get_query(result), "foo")
end

T["get_query()"]["falls back to data.input"] = function()
  local result = { data = { input = "bar" } }
  expect.equality(renderer_util.get_query(result), "bar")
end

T["get_query()"]["returns empty string when no data"] = function()
  local result = {}
  expect.equality(renderer_util.get_query(result), "")
end

T["get_query()"]["returns empty string when data has no query fields"] = function()
  local result = { data = { cmd = "edit" } }
  expect.equality(renderer_util.get_query(result), "")
end

T["get_query()"]["prefers query over arg over input"] = function()
  local result = { data = { query = "q", arg = "a", input = "i" } }
  expect.equality(renderer_util.get_query(result), "q")

  local result2 = { data = { arg = "a", input = "i" } }
  expect.equality(renderer_util.get_query(result2), "a")
end

T["parse_dimension()"] = new_set()

T["parse_dimension()"]["returns number directly"] = function()
  expect.equality(renderer_util.parse_dimension(42, 100), 42)
end

T["parse_dimension()"]["parses percentage string"] = function()
  expect.equality(renderer_util.parse_dimension("50%", 200), 100)
end

T["parse_dimension()"]["returns total for unrecognized input"] = function()
  expect.equality(renderer_util.parse_dimension("auto", 100), 100)
  expect.equality(renderer_util.parse_dimension(nil, 80), 80)
end

T["parse_dimension()"]["handles function returning number"] = function()
  expect.equality(
    renderer_util.parse_dimension(function()
      return 42
    end, 100),
    42
  )
end

T["parse_dimension()"]["handles function returning percentage string"] = function()
  expect.equality(
    renderer_util.parse_dimension(function()
      return "50%"
    end, 200),
    100
  )
end

T["parse_dimension()"]["passes ctx to function"] = function()
  local received_ctx = nil
  renderer_util.parse_dimension(function(ctx)
    received_ctx = ctx
    return 10
  end, 100, { total = 5 })
  expect.equality(received_ctx.total, 5)
end

T["calculate_width()"] = new_set()

T["calculate_width()"]["clamps between min and max"] = function()
  expect.equality(renderer_util.calculate_width(50, 10, 100), 50)
  expect.equality(renderer_util.calculate_width(200, 10, 100), 100)
  expect.equality(renderer_util.calculate_width(5, 10, 100), 10)
end

T["calculate_width()"]["nil max_width uses full available"] = function()
  expect.equality(renderer_util.calculate_width(nil, 10, 80), 80)
end

T["calculate_width()"]["accepts function values"] = function()
  local max_fn = function()
    return 50
  end
  local min_fn = function()
    return 20
  end
  expect.equality(renderer_util.calculate_width(max_fn, min_fn, 100), 50)
end

T["calculate_width()"]["passes ctx to function values"] = function()
  local seen_ctx = nil
  local max_fn = function(ctx)
    seen_ctx = ctx
    return 60
  end
  renderer_util.calculate_width(max_fn, 10, 100, { total = 42 })
  expect.equality(seen_ctx.total, 42)
end

T["parse_margin()"] = new_set()

T["parse_margin()"]["centers with auto"] = function()
  expect.equality(renderer_util.parse_margin("auto", 100, 60), 20)
end

T["parse_margin()"]["returns number directly"] = function()
  expect.equality(renderer_util.parse_margin(5, 100, 60), 5)
end

T["parse_margin()"]["parses percentage"] = function()
  expect.equality(renderer_util.parse_margin("10%", 200, 100), 20)
end

T["parse_margin()"]["returns 0 for unrecognized input"] = function()
  expect.equality(renderer_util.parse_margin(nil, 100, 60), 0)
end

T["parse_margin()"]["before_cursor uses getcmdline"] = function()
  -- Stub getcmdline to return a known value
  local orig = vim.fn.getcmdline
  vim.fn.getcmdline = function()
    return "edit foo"
  end
  -- col = #"edit foo" + 1 = 9; total=100, content=40 → min(9, 60) = 9
  expect.equality(renderer_util.parse_margin("before_cursor", 100, 40), 9)
  vim.fn.getcmdline = orig
end

T["parse_margin()"]["before_cursor clamps to prevent overflow"] = function()
  local orig = vim.fn.getcmdline
  vim.fn.getcmdline = function()
    return "edit some/very/long/path/that/exceeds/total"
  end
  -- col = 43; total=50, content=40 → min(43, max(0, 10)) = 10
  expect.equality(renderer_util.parse_margin("before_cursor", 50, 40), 10)
  vim.fn.getcmdline = orig
end

T["parse_margin()"]["before_cursor with empty cmdline"] = function()
  local orig = vim.fn.getcmdline
  vim.fn.getcmdline = function()
    return ""
  end
  -- col = 1; total=100, content=40 → min(1, 60) = 1
  expect.equality(renderer_util.parse_margin("before_cursor", 100, 40), 1)
  vim.fn.getcmdline = orig
end

T["parse_margin()"]["before_cursor with nil getcmdline"] = function()
  local orig = vim.fn.getcmdline
  vim.fn.getcmdline = function()
    return nil
  end
  -- input = "", col = 1; total=100, content=40 → min(1, 60) = 1
  expect.equality(renderer_util.parse_margin("before_cursor", 100, 40), 1)
  vim.fn.getcmdline = orig
end

T["parse_margin()"]["before_cursor tracks every character"] = function()
  local orig = vim.fn.getcmdline
  -- Simulate typing: "e ", "e l", "e lu", "e lua/"
  local results = {}
  for _, text in ipairs({ "e ", "e l", "e lu", "e lua/" }) do
    vim.fn.getcmdline = function()
      return text
    end
    table.insert(results, renderer_util.parse_margin("before_cursor", 200, 50))
  end
  -- Each should be #text + 1: 3, 4, 5, 7
  expect.equality(results, { 3, 4, 5, 7 })
  vim.fn.getcmdline = orig
end

T["make_page()"] = new_set()

T["make_page()"]["returns -1, -1 for empty list"] = function()
  local s, f = renderer_util.make_page(-1, 0, 10, { -1, -1 })
  expect.equality(s, -1)
  expect.equality(f, -1)
end

T["make_page()"]["shows first page when no selection"] = function()
  local s, f = renderer_util.make_page(-1, 20, 5, { -1, -1 })
  expect.equality(s, 0)
  expect.equality(f, 4)
end

T["make_page()"]["keeps selection visible"] = function()
  local s, f = renderer_util.make_page(3, 20, 5, { 0, 4 })
  expect.equality(s >= 0, true)
  expect.equality(f >= s, true)
  expect.equality(3 >= s, true)
  expect.equality(3 <= f, true)
end

T["make_page()"]["scrolls when selection moves past page"] = function()
  local s, f = renderer_util.make_page(6, 20, 5, { 0, 4 })
  expect.equality(6 >= s, true)
  expect.equality(6 <= f, true)
  expect.equality(f - s + 1, 5)
end

T["make_page()"]["clamps to total"] = function()
  local s, f = renderer_util.make_page(2, 3, 10, { -1, -1 })
  expect.equality(s, 0)
  expect.equality(f, 2)
end

T["check_run_id()"] = new_set()

T["check_run_id()"]["resets page on run_id change"] = function()
  local state = { run_id = 1, page = { 5, 10 }, draw_cache = nil }
  renderer_util.check_run_id(state, { run_id = 2 })
  expect.equality(state.run_id, 2)
  expect.equality(state.page[1], -1)
  expect.equality(state.page[2], -1)
end

T["check_run_id()"]["preserves page on same run_id"] = function()
  local state = { run_id = 1, page = { 5, 10 }, draw_cache = nil }
  renderer_util.check_run_id(state, { run_id = 1 })
  expect.equality(state.page[1], 5)
  expect.equality(state.page[2], 10)
end

T["get_popup_geometry()"] = new_set()

T["get_popup_geometry()"]["returns visible=false when no geometry stored"] = function()
  renderer_util._last_popup_geometry = nil
  local g = renderer_util.get_popup_geometry()
  expect.equality(g.visible, false)
  expect.equality(g.row, 0)
  expect.equality(g.col, 0)
  expect.equality(g.width, 0)
  expect.equality(g.height, 0)
  expect.equality(g.border, nil)
end

T["get_popup_geometry()"]["returns stored geometry with visible=true"] = function()
  renderer_util._last_popup_geometry = {
    row = 5,
    col = 10,
    width = 40,
    height = 12,
    border = "rounded",
  }
  local g = renderer_util.get_popup_geometry()
  expect.equality(g.visible, true)
  expect.equality(g.row, 5)
  expect.equality(g.col, 10)
  expect.equality(g.width, 40)
  expect.equality(g.height, 12)
  expect.equality(g.border, "rounded")
  -- Clean up
  renderer_util._last_popup_geometry = nil
end

T["create_base_state()"] = new_set()

T["create_base_state()"]["auto-wraps list of highlighters into chain highlighter"] = function()
  local h1 = {
    highlight = function()
      return {}
    end,
  }
  local h2 = {
    highlight = function()
      return { { 0, 1, "hl" } }
    end,
  }
  local state = renderer_util.create_base_state({ highlighter = { h1, h2 } })
  -- The wrapped highlighter should have a .highlight method
  expect.equality(type(state.highlighter.highlight), "function")
  -- It should chain: h1 returns empty, so h2's result wins
  local spans = state.highlighter.highlight("a", "abc")
  expect.equality(spans, { { 0, 1, "hl" } })
end

T["create_base_state()"]["passes single highlighter through unchanged"] = function()
  local h = {
    highlight = function()
      return { { 0, 2, "hl" } }
    end,
  }
  local state = renderer_util.create_base_state({ highlighter = h })
  expect.equality(state.highlighter, h)
end

T["create_base_state()"]["passes nil highlighter through"] = function()
  local state = renderer_util.create_base_state({})
  expect.equality(state.highlighter, nil)
end

T["get_popup_win()"] = new_set()

T["get_popup_win()"]["returns nil when no window stored"] = function()
  renderer_util._last_popup_win = nil
  expect.equality(renderer_util.get_popup_win(), nil)
end

T["get_popup_win()"]["returns nil for invalid window handle"] = function()
  renderer_util._last_popup_win = -1
  expect.equality(renderer_util.get_popup_win(), nil)
  renderer_util._last_popup_win = nil
end

return T

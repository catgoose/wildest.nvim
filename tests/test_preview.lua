local MiniTest = require("mini.test")
local new_set = MiniTest.new_set
local expect = MiniTest.expect

local T = new_set()

local function get_preview()
  local preview = require("wildest.preview")
  preview._reset()
  return preview
end

T["setup()"] = new_set()

T["setup()"]["stores config correctly"] = function()
  local preview = get_preview()
  preview.setup({ width = "30%", border = "rounded", max_lines = 100, title = false })
  expect.equality(preview.is_active(), true)
end

T["setup()"]["defaults enabled to true"] = function()
  local preview = get_preview()
  preview.setup({})
  expect.equality(preview.is_active(), true)
end

T["setup()"]["respects enabled = false"] = function()
  local preview = get_preview()
  preview.setup({ enabled = false })
  expect.equality(preview.is_active(), false)
end

T["reserved_width()"] = new_set()

T["reserved_width()"]["returns 0 when not configured"] = function()
  local preview = get_preview()
  expect.equality(preview.reserved_width(), 0)
end

T["reserved_width()"]["returns 0 when configured but window not visible"] = function()
  local preview = get_preview()
  preview.setup({ width = "50%" })
  -- Window not open yet, so reserved_width should be 0
  expect.equality(preview.reserved_width(), 0)
end

T["reserved_width()"]["returns 0 when toggled off"] = function()
  local preview = get_preview()
  preview.setup({ enabled = true })
  preview.toggle() -- disable
  expect.equality(preview.reserved_width(), 0)
end

T["is_active()"] = new_set()

T["is_active()"]["false by default"] = function()
  local preview = get_preview()
  expect.equality(preview.is_active(), false)
end

T["is_active()"]["true after setup with enabled=true"] = function()
  local preview = get_preview()
  preview.setup({ enabled = true })
  expect.equality(preview.is_active(), true)
end

T["is_active()"]["false after toggle"] = function()
  local preview = get_preview()
  preview.setup({ enabled = true })
  preview.toggle()
  expect.equality(preview.is_active(), false)
end

T["toggle()"] = new_set()

T["toggle()"]["flips enabled state"] = function()
  local preview = get_preview()
  preview.setup({ enabled = true })
  expect.equality(preview.is_active(), true)
  preview.toggle()
  expect.equality(preview.is_active(), false)
  preview.toggle()
  expect.equality(preview.is_active(), true)
end

T["hide()"] = new_set()

T["hide()"]["safe to call when no window exists"] = function()
  local preview = get_preview()
  -- Should not error
  preview.hide()
end

T["hide()"]["safe to call when not configured"] = function()
  local preview = get_preview()
  preview.hide()
  expect.equality(preview.reserved_width(), 0)
end

T["setup()"]["stores position and anchor correctly"] = function()
  local preview = get_preview()
  preview.setup({ position = "left", anchor = "popup" })
  expect.equality(preview.is_active(), true)
  expect.equality(preview.is_screen_anchor(), false)
end

T["setup()"]["defaults position to right and anchor to screen"] = function()
  local preview = get_preview()
  preview.setup({})
  expect.equality(preview.is_screen_anchor(), true)
end

T["reserved_space()"] = new_set()

T["reserved_space()"]["returns all zeros when not configured"] = function()
  local preview = get_preview()
  local s = preview.reserved_space()
  expect.equality(s, { top = 0, right = 0, bottom = 0, left = 0 })
end

T["reserved_space()"]["returns all zeros when window not visible"] = function()
  local preview = get_preview()
  preview.setup({ position = "right", anchor = "screen" })
  local s = preview.reserved_space()
  expect.equality(s, { top = 0, right = 0, bottom = 0, left = 0 })
end

T["reserved_space()"]["returns all zeros for popup anchor"] = function()
  local preview = get_preview()
  preview.setup({ position = "right", anchor = "popup" })
  local s = preview.reserved_space()
  expect.equality(s, { top = 0, right = 0, bottom = 0, left = 0 })
end

T["reserved_space()"]["returns all zeros when toggled off"] = function()
  local preview = get_preview()
  preview.setup({ position = "right", anchor = "screen" })
  preview.toggle()
  local s = preview.reserved_space()
  expect.equality(s, { top = 0, right = 0, bottom = 0, left = 0 })
end

T["is_screen_anchor()"] = new_set()

T["is_screen_anchor()"]["returns false when not configured"] = function()
  local preview = get_preview()
  expect.equality(preview.is_screen_anchor(), false)
end

T["is_screen_anchor()"]["returns true for screen anchor"] = function()
  local preview = get_preview()
  preview.setup({ anchor = "screen" })
  expect.equality(preview.is_screen_anchor(), true)
end

T["is_screen_anchor()"]["returns false for popup anchor"] = function()
  local preview = get_preview()
  preview.setup({ anchor = "popup" })
  expect.equality(preview.is_screen_anchor(), false)
end

T["_detect_expand()"] = new_set()

T["_detect_expand()"]["detects file from expand field"] = function()
  local preview = get_preview()
  expect.equality(preview._detect_expand({ expand = "file" }), "file")
  expect.equality(preview._detect_expand({ expand = "file_in_path" }), "file")
  expect.equality(preview._detect_expand({ expand = "dir" }), "file")
end

T["_detect_expand()"]["detects buffer from expand field"] = function()
  local preview = get_preview()
  expect.equality(preview._detect_expand({ expand = "buffer" }), "buffer")
end

T["_detect_expand()"]["detects help from expand field"] = function()
  local preview = get_preview()
  expect.equality(preview._detect_expand({ expand = "help" }), "help")
end

T["_detect_expand()"]["detects from cmd heuristic"] = function()
  local preview = get_preview()
  expect.equality(preview._detect_expand({ cmd = "help" }), "help")
  expect.equality(preview._detect_expand({ cmd = "h" }), "help")
  expect.equality(preview._detect_expand({ cmd = "buffer" }), "buffer")
  expect.equality(preview._detect_expand({ cmd = "b" }), "buffer")
  expect.equality(preview._detect_expand({ cmd = "edit" }), "file")
  expect.equality(preview._detect_expand({ cmd = "e" }), "file")
end

T["_detect_expand()"]["returns nil for unknown"] = function()
  local preview = get_preview()
  expect.equality(preview._detect_expand({}), nil)
  expect.equality(preview._detect_expand({ cmd = "set" }), nil)
end

-- ─── _parse_dim() ──────────────────────────────────────────────────────────

T["_parse_dim()"] = new_set()

T["_parse_dim()"]["parses percentage string"] = function()
  local preview = get_preview()
  expect.equality(preview._parse_dim("50%", 200), 100)
  expect.equality(preview._parse_dim("25%", 200), 50)
  expect.equality(preview._parse_dim("100%", 80), 80)
end

T["_parse_dim()"]["clamps integer within total"] = function()
  local preview = get_preview()
  expect.equality(preview._parse_dim(40, 200), 40)
  expect.equality(preview._parse_dim(300, 200), 200)
  expect.equality(preview._parse_dim(0, 200), 1) -- min 1
end

T["_parse_dim()"]["floors percentage result"] = function()
  local preview = get_preview()
  -- 33% of 100 = 33.0
  expect.equality(preview._parse_dim("33%", 100), 33)
  -- 50% of 79 = 39.5 → 39
  expect.equality(preview._parse_dim("50%", 79), 39)
end

T["_parse_dim()"]["returns half total for non-parseable input"] = function()
  local preview = get_preview()
  expect.equality(preview._parse_dim("abc", 200), 100)
  expect.equality(preview._parse_dim(nil, 80), 40)
end

-- ─── _compute_win_config() ─────────────────────────────────────────────────
-- Standard test environment: 200 cols, 50 available rows

T["_compute_win_config()"] = new_set()

-- Helper: standard params for screen anchor
local function screen_params(position, opts)
  opts = opts or {}
  return {
    position = position,
    anchor = "screen",
    width = opts.width or "40%",
    height = opts.height or "40%",
    editor_cols = opts.editor_cols or 200,
    available_rows = opts.available_rows or 50,
    content_lines = opts.content_lines or 100,
    geom = nil,
  }
end

-- Helper: standard popup geometry (bordered popup at row=20, col=30, 60x15)
local function popup_geom(opts)
  opts = opts or {}
  return {
    row = opts.row or 20,
    col = opts.col or 30,
    width = opts.width or 60,
    height = opts.height or 15,
    border = opts.border or "rounded",
  }
end

-- Helper: standard params for popup anchor
local function popup_params(position, opts)
  opts = opts or {}
  return {
    position = position,
    anchor = "popup",
    width = opts.width or "40%",
    height = opts.height or "40%",
    editor_cols = opts.editor_cols or 200,
    available_rows = opts.available_rows or 50,
    content_lines = opts.content_lines or 100,
    geom = opts.geom or popup_geom(),
  }
end

-- ─── Screen anchor: right ──────────────────────────────────────────────────

T["_compute_win_config()"]["screen right: fills right edge"] = function()
  local preview = get_preview()
  local p = preview._compute_win_config(screen_params("right"))
  -- 40% of 200 = 80
  expect.equality(p.row, 0)
  expect.equality(p.col, 120) -- 200 - 80
  expect.equality(p.width, 78) -- 80 - 2 (border cols)
  expect.equality(p.height, 50) -- full available_rows
end

T["_compute_win_config()"]["screen right: width subtracts 2 for border"] = function()
  local preview = get_preview()
  local p = preview._compute_win_config(screen_params("right", { width = 40 }))
  expect.equality(p.width, 38) -- 40 - 2
end

-- ─── Screen anchor: left ───────────────────────────────────────────────────

T["_compute_win_config()"]["screen left: fills left edge"] = function()
  local preview = get_preview()
  local p = preview._compute_win_config(screen_params("left"))
  expect.equality(p.row, 0)
  expect.equality(p.col, 0)
  expect.equality(p.width, 78) -- 80 - 2
  expect.equality(p.height, 50)
end

-- ─── Screen anchor: top ────────────────────────────────────────────────────

T["_compute_win_config()"]["screen top: fills top edge"] = function()
  local preview = get_preview()
  local p = preview._compute_win_config(screen_params("top"))
  -- 40% of 50 = 20
  expect.equality(p.row, 0)
  expect.equality(p.col, 0)
  expect.equality(p.width, 198) -- 200 - 2 (border cols)
  expect.equality(p.height, 18) -- 20 - 2 (border rows)
end

T["_compute_win_config()"]["screen top: height subtracts 2 for border rows"] = function()
  local preview = get_preview()
  local p = preview._compute_win_config(screen_params("top", { height = 10 }))
  expect.equality(p.height, 8) -- 10 - 2
end

-- ─── Screen anchor: bottom ─────────────────────────────────────────────────

T["_compute_win_config()"]["screen bottom: fills bottom edge"] = function()
  local preview = get_preview()
  local p = preview._compute_win_config(screen_params("bottom"))
  -- 40% of 50 = 20, row = 50 - 20 + 1 = 31
  expect.equality(p.row, 31)
  expect.equality(p.col, 0)
  expect.equality(p.width, 198) -- 200 - 2
  expect.equality(p.height, 18) -- 20 - 2
end

T["_compute_win_config()"]["screen bottom: row places preview correctly"] = function()
  local preview = get_preview()
  local p = preview._compute_win_config(screen_params("bottom", { height = 10 }))
  -- h=10, row = 50 - 10 + 1 = 41
  -- preview top border at row 41, content rows 42..49, bottom border at 50
  -- total visual span: 41..50 = 10 rows (matches h)
  expect.equality(p.row, 41)
  expect.equality(p.height, 8) -- 10 - 2
end

-- ─── Screen anchor: no overlap between bottom preview and popup area ───────

T["_compute_win_config()"]["screen bottom: bottom border reaches available_rows"] = function()
  local preview = get_preview()
  local p = preview._compute_win_config(screen_params("bottom", { height = 20 }))
  -- h=20, content=18, row=31
  -- Visual: top border at 31, content 32..49, bottom border at 50
  -- Bottom border row = row + content + 1 = 31 + 18 + 1 = 50 = available_rows ✓
  local bottom_border = p.row + p.height + 1
  expect.equality(bottom_border, 50)
end

T["_compute_win_config()"]["screen top: top border at row 0"] = function()
  local preview = get_preview()
  local p = preview._compute_win_config(screen_params("top"))
  expect.equality(p.row, 0)
end

-- ─── Screen anchor: left/right symmetry ────────────────────────────────────

T["_compute_win_config()"]["screen left/right have same width and height"] = function()
  local preview = get_preview()
  local l = preview._compute_win_config(screen_params("left"))
  local r = preview._compute_win_config(screen_params("right"))
  expect.equality(l.width, r.width)
  expect.equality(l.height, r.height)
end

T["_compute_win_config()"]["screen top/bottom have same width and content height"] = function()
  local preview = get_preview()
  local t = preview._compute_win_config(screen_params("top"))
  local b = preview._compute_win_config(screen_params("bottom"))
  expect.equality(t.width, b.width)
  expect.equality(t.height, b.height)
end

-- ─── Popup anchor: returns nil without geometry ────────────────────────────

T["_compute_win_config()"]["popup anchor: returns nil without geometry"] = function()
  local preview = get_preview()
  local p = preview._compute_win_config({
    position = "right",
    anchor = "popup",
    width = "40%",
    height = "40%",
    editor_cols = 200,
    available_rows = 50,
    content_lines = 100,
    geom = nil,
  })
  expect.equality(p, nil)
end

-- ─── Popup anchor: right ───────────────────────────────────────────────────

T["_compute_win_config()"]["popup right: positions next to popup"] = function()
  local preview = get_preview()
  local geom = popup_geom() -- row=20, col=30, w=60, h=15, border="rounded"
  local p = preview._compute_win_config(popup_params("right", { geom = geom }))
  -- border_size=1 (popup has border), col = 30 + 60 + 1 = 91
  expect.equality(p.col, 91)
  expect.equality(p.row, 20) -- matches popup row
  expect.equality(p.width, 78) -- 80 - 2
end

T["_compute_win_config()"]["popup right: height capped by popup height"] = function()
  local preview = get_preview()
  -- popup height 15, content 100 → capped at 15
  local p = preview._compute_win_config(popup_params("right", { content_lines = 100 }))
  expect.equality(p.height, 15)
end

T["_compute_win_config()"]["popup right: height shrinks to content"] = function()
  local preview = get_preview()
  -- popup height 15, content 5 → uses 5
  local p = preview._compute_win_config(popup_params("right", { content_lines = 5 }))
  expect.equality(p.height, 5)
end

-- ─── Popup anchor: left ────────────────────────────────────────────────────

T["_compute_win_config()"]["popup left: positions before popup"] = function()
  local preview = get_preview()
  local geom = popup_geom() -- col=30, border=rounded
  local p = preview._compute_win_config(popup_params("left", { geom = geom }))
  -- w=80, border_size=1, col = 30 - 80 - 1 = -51
  expect.equality(p.col, -51)
  expect.equality(p.row, 20)
  expect.equality(p.width, 78) -- 80 - 2
end

T["_compute_win_config()"]["popup left: height shrinks to content"] = function()
  local preview = get_preview()
  local p = preview._compute_win_config(popup_params("left", { content_lines = 3 }))
  expect.equality(p.height, 3)
end

-- ─── Popup anchor: top ─────────────────────────────────────────────────────

T["_compute_win_config()"]["popup top: positions above popup"] = function()
  local preview = get_preview()
  local geom = popup_geom() -- row=20
  local p = preview._compute_win_config(popup_params("top", { geom = geom, content_lines = 10 }))
  -- h = min(20, 10) = 10, row = 20 - 10 - 2 = 8
  expect.equality(p.row, 8)
  expect.equality(p.col, 30) -- matches popup col
  expect.equality(p.height, 10)
end

T["_compute_win_config()"]["popup top: preview bottom border above popup top border"] = function()
  local preview = get_preview()
  local geom = popup_geom({ row = 20 })
  local p = preview._compute_win_config(popup_params("top", { geom = geom, content_lines = 10 }))
  -- preview bottom border at row + height + 1 = 8 + 10 + 1 = 19
  -- popup top border at 20
  -- 19 < 20 → no overlap ✓
  local preview_bottom = p.row + p.height + 1
  expect.equality(preview_bottom < geom.row, true)
end

T["_compute_win_config()"]["popup top: uses popup width"] = function()
  local preview = get_preview()
  local geom = popup_geom({ width = 80 })
  local p = preview._compute_win_config(popup_params("top", { geom = geom }))
  -- top/bottom use math.max(1, geom.width) directly
  expect.equality(p.width, 80)
end

-- ─── Popup anchor: bottom ──────────────────────────────────────────────────

T["_compute_win_config()"]["popup bottom: positions below popup"] = function()
  local preview = get_preview()
  local geom = popup_geom() -- row=20, h=15, border=rounded
  local p = preview._compute_win_config(popup_params("bottom", { geom = geom, content_lines = 8 }))
  -- border_size=1, row = 20 + 15 + 1 + 1 = 37
  expect.equality(p.row, 37)
  expect.equality(p.col, 30)
  expect.equality(p.height, 8)
end

T["_compute_win_config()"]["popup bottom: preview top border below popup bottom border"] = function()
  local preview = get_preview()
  local geom = popup_geom({ row = 20, height = 15 })
  local p = preview._compute_win_config(popup_params("bottom", { geom = geom, content_lines = 5 }))
  -- popup bottom border at 20 + 15 + 1 = 36
  -- preview top border at p.row = 37
  -- 37 > 36 → no overlap ✓
  local popup_bottom = geom.row + geom.height + 1
  expect.equality(p.row > popup_bottom, true)
end

-- ─── Popup anchor: borderless popup ────────────────────────────────────────

T["_compute_win_config()"]["popup right: borderless popup has no border_size offset"] = function()
  local preview = get_preview()
  local geom = popup_geom({ border = "none" })
  local p = preview._compute_win_config(popup_params("right", { geom = geom }))
  -- border_size=0, col = 30 + 60 + 0 = 90
  expect.equality(p.col, 90)
end

T["_compute_win_config()"]["popup top: borderless popup still no overlap"] = function()
  local preview = get_preview()
  local geom = popup_geom({ row = 20, border = "none" })
  local p = preview._compute_win_config(popup_params("top", { geom = geom, content_lines = 5 }))
  -- h=5, row = 20 - 5 - 2 = 13
  -- preview bottom border at 13 + 5 + 1 = 19
  -- popup starts at 20 (no border, content at row 20)
  -- 19 < 20 → no overlap ✓
  local preview_bottom = p.row + p.height + 1
  expect.equality(preview_bottom < geom.row, true)
end

-- ─── Popup anchor: content-aware sizing ────────────────────────────────────

T["_compute_win_config()"]["popup right: 1-line content gets height 1"] = function()
  local preview = get_preview()
  local p = preview._compute_win_config(popup_params("right", { content_lines = 1 }))
  expect.equality(p.height, 1)
end

T["_compute_win_config()"]["popup top: content-aware capped by config height"] = function()
  local preview = get_preview()
  -- height "40%" of 50 available = 20, content = 100
  local p = preview._compute_win_config(popup_params("top", { content_lines = 100 }))
  expect.equality(p.height, 20)
end

T["_compute_win_config()"]["popup top: content fewer than config height"] = function()
  local preview = get_preview()
  -- height "40%" of 50 = 20, content = 7
  local p = preview._compute_win_config(popup_params("top", { content_lines = 7 }))
  expect.equality(p.height, 7)
end

-- ─── Screen anchor: small editor ───────────────────────────────────────────

T["_compute_win_config()"]["screen right: minimum width 1 for tiny editor"] = function()
  local preview = get_preview()
  local p = preview._compute_win_config(screen_params("right", { editor_cols = 4, width = "50%" }))
  -- 50% of 4 = 2, width = max(1, 2-2) = max(1, 0) = 1
  expect.equality(p.width, 1)
end

T["_compute_win_config()"]["screen top: minimum height 1 for tiny editor"] = function()
  local preview = get_preview()
  local p = preview._compute_win_config(screen_params("top", { available_rows = 4, height = "50%" }))
  -- 50% of 4 = 2, height = max(1, 2-2) = 1
  expect.equality(p.height, 1)
end

-- ─── default_position() ────────────────────────────────────────────────────

T["default_position()"] = new_set()

T["default_position()"]["returns 4 values"] = function()
  local preview = get_preview()
  preview.setup({ anchor = "popup" }) -- no reserved space
  local renderer_util = require("wildest.renderer")
  local row, col, width, avail = renderer_util.default_position()
  expect.equality(type(row), "number")
  expect.equality(type(col), "number")
  expect.equality(type(width), "number")
  expect.equality(type(avail), "number")
end

T["default_position()"]["col is 0 when no left preview"] = function()
  local preview = get_preview()
  preview.setup({ anchor = "popup" })
  local renderer_util = require("wildest.renderer")
  local _, col = renderer_util.default_position()
  expect.equality(col, 0)
end

T["default_position()"]["avail is positive"] = function()
  local preview = get_preview()
  preview.setup({ anchor = "popup" })
  local renderer_util = require("wildest.renderer")
  local _, _, _, avail = renderer_util.default_position()
  expect.equality(avail >= 1, true)
end

-- ─── Popup geometry storage ────────────────────────────────────────────────

T["popup geometry"] = new_set()

T["popup geometry"]["stored by open_or_update_win"] = function()
  local renderer_util = require("wildest.renderer")
  -- Clear any prior state
  renderer_util._last_popup_geometry = nil
  -- Create a minimal state to test with
  local state = {
    buf = -1,
    win = -1,
    ns_id = -1,
    highlights = { default = "Normal" },
  }
  renderer_util.ensure_buf(state, "test_geom")
  local win_config = {
    relative = "editor",
    row = 10,
    col = 20,
    width = 40,
    height = 12,
    style = "minimal",
    border = "rounded",
    focusable = false,
    noautocmd = true,
  }
  renderer_util.open_or_update_win(state, win_config)
  expect.equality(renderer_util._last_popup_geometry ~= nil, true)
  expect.equality(renderer_util._last_popup_geometry.row, 10)
  expect.equality(renderer_util._last_popup_geometry.col, 20)
  expect.equality(renderer_util._last_popup_geometry.width, 40)
  expect.equality(renderer_util._last_popup_geometry.height, 12)
  expect.equality(renderer_util._last_popup_geometry.border, "rounded")
  -- Clean up
  renderer_util.hide_win(state)
end

T["popup geometry"]["cleared by hide_win"] = function()
  local renderer_util = require("wildest.renderer")
  renderer_util._last_popup_geometry = { row = 1, col = 2, width = 3, height = 4 }
  local state = { win = -1, page = { -1, -1 } }
  renderer_util.hide_win(state)
  expect.equality(renderer_util._last_popup_geometry, nil)
end

return T

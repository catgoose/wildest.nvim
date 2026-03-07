---@diagnostic disable: need-check-nil
local MiniTest = require("mini.test")
local new_set = MiniTest.new_set
local expect = MiniTest.expect

local T = new_set()

local function get_preview()
  local preview = require("wildest.preview")
  preview._reset()
  -- Reset gaps module so outer/inner default to 0
  require("wildest.gaps").setup(nil, nil)
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

T["setup()"]["stores priority correctly"] = function()
  local preview = get_preview()
  preview.setup({ priority = "preview" })
  expect.equality(preview.is_preview_priority(), true)
end

T["setup()"]["defaults priority to menu"] = function()
  local preview = get_preview()
  preview.setup({})
  expect.equality(preview.is_preview_priority(), false)
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

T["reserved_space()"]["popup anchor + right reserves right space"] = function()
  local preview = get_preview()
  preview.setup({ position = "right", anchor = "popup", width = "50%" })
  local s = preview.reserved_space()
  local expected_width = preview._parse_dim("50%", vim.o.columns)
  expect.equality(s.right, expected_width)
  expect.equality(s.top, 0)
  expect.equality(s.bottom, 0)
  expect.equality(s.left, 0)
end

T["reserved_space()"]["popup anchor + left reserves left space"] = function()
  local preview = get_preview()
  preview.setup({ position = "left", anchor = "popup", width = "50%" })
  local s = preview.reserved_space()
  local expected_width = preview._parse_dim("50%", vim.o.columns)
  expect.equality(s.left, expected_width)
  expect.equality(s.top, 0)
  expect.equality(s.bottom, 0)
  expect.equality(s.right, 0)
end

T["reserved_space()"]["popup anchor + top reserves top space"] = function()
  local preview = get_preview()
  preview.setup({ position = "top", anchor = "popup", height = "40%" })
  local s = preview.reserved_space()
  local height = vim.o.lines
  local reserved = vim.o.cmdheight + (vim.o.laststatus > 0 and 1 or 0)
  local available_rows = height - reserved - 1
  local expected_height = preview._parse_dim("40%", available_rows)
  expect.equality(s.top, expected_height)
  expect.equality(s.right, 0)
  expect.equality(s.bottom, 0)
  expect.equality(s.left, 0)
end

T["reserved_space()"]["popup anchor + bottom reserves bottom space"] = function()
  local preview = get_preview()
  preview.setup({ position = "bottom", anchor = "popup", height = "40%" })
  local s = preview.reserved_space()
  local height = vim.o.lines
  local reserved = vim.o.cmdheight + (vim.o.laststatus > 0 and 1 or 0)
  local available_rows = height - reserved - 1
  local expected_height = preview._parse_dim("40%", available_rows)
  expect.equality(s.bottom, expected_height)
  expect.equality(s.top, 0)
  expect.equality(s.right, 0)
  expect.equality(s.left, 0)
end

T["reserved_space()"]["returns all zeros when toggled off"] = function()
  local preview = get_preview()
  preview.setup({ position = "right", anchor = "screen" })
  preview.toggle()
  local s = preview.reserved_space()
  expect.equality(s, { top = 0, right = 0, bottom = 0, left = 0 })
end

T["reserved_space()"]["screen anchor + priority=preview reserves without window"] = function()
  local preview = get_preview()
  preview.setup({ position = "right", anchor = "screen", width = "50%", priority = "preview" })
  -- No window open, but priority=preview should still reserve space
  local s = preview.reserved_space()
  local expected_width = preview._parse_dim("50%", vim.o.columns)
  expect.equality(s.right, expected_width)
  expect.equality(s.top, 0)
  expect.equality(s.bottom, 0)
  expect.equality(s.left, 0)
end

T["reserved_space()"]["screen anchor + priority=menu requires window"] = function()
  local preview = get_preview()
  preview.setup({ position = "right", anchor = "screen", width = "50%", priority = "menu" })
  -- No window open, priority=menu → should return zeros
  local s = preview.reserved_space()
  expect.equality(s, { top = 0, right = 0, bottom = 0, left = 0 })
end

T["reserved_space()"]["popup anchor + priority=preview unchanged (already unconditional)"] = function()
  local preview = get_preview()
  preview.setup({ position = "right", anchor = "popup", width = "50%", priority = "preview" })
  local s = preview.reserved_space()
  local expected_width = preview._parse_dim("50%", vim.o.columns)
  expect.equality(s.right, expected_width)
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
    gap = opts.gap,
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
    gap = opts.gap,
    priority = opts.priority,
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
  -- border_size=1 (popup has border), col = 30 + 60 + 2 = 92
  expect.equality(p.col, 92)
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

T["_compute_win_config()"]["popup left: width clamped to available space"] = function()
  local preview = get_preview()
  local geom = popup_geom() -- col=30, border=rounded
  local p = preview._compute_win_config(popup_params("left", { geom = geom }))
  -- available = 30, w = min(80, 30) = 30
  expect.equality(p.col, 0) -- 30 - 30 = 0
  expect.equality(p.row, 20)
  expect.equality(p.width, 28) -- 30 - 2
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
  -- border_size=1, row = 20 + 15 + 2 = 37
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
  -- border_size=0, col = 30 + 60 + 0 = 90 (2*0 = 0)
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

T["_compute_win_config()"]["popup top: content-aware capped by available space"] = function()
  local preview = get_preview()
  -- height "40%" of 50 = 20, content = 100, available = 20 - 2 = 18
  local p = preview._compute_win_config(popup_params("top", { content_lines = 100 }))
  expect.equality(p.height, 18) -- clamped to available=18
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
  local p =
    preview._compute_win_config(screen_params("top", { available_rows = 4, height = "50%" }))
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

-- ─── _compute_win_config(): integer dimensions ──────────────────────────────

T["_compute_win_config()"]["screen right: integer width"] = function()
  local preview = get_preview()
  local p = preview._compute_win_config(screen_params("right", { width = 50 }))
  expect.equality(p.col, 150) -- 200 - 50
  expect.equality(p.width, 48) -- 50 - 2 (border)
  expect.equality(p.height, 50)
end

T["_compute_win_config()"]["screen left: integer width"] = function()
  local preview = get_preview()
  local p = preview._compute_win_config(screen_params("left", { width = 60 }))
  expect.equality(p.col, 0)
  expect.equality(p.width, 58) -- 60 - 2
end

T["_compute_win_config()"]["screen top: integer height"] = function()
  local preview = get_preview()
  local p = preview._compute_win_config(screen_params("top", { height = 15 }))
  expect.equality(p.row, 0)
  expect.equality(p.height, 13) -- 15 - 2
  expect.equality(p.width, 198) -- 200 - 2
end

T["_compute_win_config()"]["screen bottom: integer height"] = function()
  local preview = get_preview()
  local p = preview._compute_win_config(screen_params("bottom", { height = 15 }))
  -- row = 50 - 15 + 1 = 36
  expect.equality(p.row, 36)
  expect.equality(p.height, 13) -- 15 - 2
end

-- ─── _compute_win_config(): popup anchor edge positions ─────────────────────

T["_compute_win_config()"]["popup right: popup at col 0"] = function()
  local preview = get_preview()
  local geom = popup_geom({ col = 0, width = 40 })
  local p = preview._compute_win_config(popup_params("right", { geom = geom }))
  -- col = 0 + 40 + 2 = 42
  expect.equality(p.col, 42)
  expect.equality(p.row, 20)
end

T["_compute_win_config()"]["popup left: returns nil when popup at col 0"] = function()
  local preview = get_preview()
  local geom = popup_geom({ col = 0, width = 40 })
  local p = preview._compute_win_config(popup_params("left", { geom = geom }))
  -- available = 0 < MIN_PREVIEW_COLS → nil
  expect.equality(p, nil)
end

T["_compute_win_config()"]["popup top: returns nil when popup at row 0"] = function()
  local preview = get_preview()
  local geom = popup_geom({ row = 0 })
  local p = preview._compute_win_config(popup_params("top", { geom = geom, content_lines = 10 }))
  -- available = 0 - 2 = -2 < MIN_PREVIEW_ROWS → nil
  expect.equality(p, nil)
end

T["_compute_win_config()"]["popup bottom: height clamped near bottom of screen"] = function()
  local preview = get_preview()
  local geom = popup_geom({ row = 40, height = 5 })
  local p = preview._compute_win_config(popup_params("bottom", { geom = geom, content_lines = 3 }))
  -- start_row = 40 + 5 + 2 = 47, available = 50 - 47 - 2 = 1
  expect.equality(p.row, 47)
  expect.equality(p.height, 1) -- clamped from 3 to available=1
end

-- ─── _compute_win_config(): popup anchor borderless all positions ───────────

T["_compute_win_config()"]["popup left: borderless has no offset"] = function()
  local preview = get_preview()
  local geom = popup_geom({ col = 100, border = "none" })
  local p = preview._compute_win_config(popup_params("left", { geom = geom }))
  -- border_size=0, col = 100 - 80 = 20 (no border offset)
  expect.equality(p.col, 20)
end

T["_compute_win_config()"]["popup bottom: borderless has no offset"] = function()
  local preview = get_preview()
  local geom = popup_geom({ row = 10, height = 8, border = "none" })
  local p = preview._compute_win_config(popup_params("bottom", { geom = geom, content_lines = 5 }))
  -- border_size=0, row = 10 + 8 + 0 = 18 (2*0 = 0)
  expect.equality(p.row, 18)
  expect.equality(p.height, 5)
end

-- ─── _compute_win_config(): popup anchor very small geometry ────────────────

T["_compute_win_config()"]["popup right: tiny popup (1x1)"] = function()
  local preview = get_preview()
  local geom = popup_geom({ row = 10, col = 10, width = 1, height = 1, border = "none" })
  local p = preview._compute_win_config(popup_params("right", { geom = geom, content_lines = 50 }))
  expect.equality(p.row, 10)
  expect.equality(p.col, 11) -- 10 + 1 + 0
  expect.equality(p.height, 1) -- capped by popup height
end

T["_compute_win_config()"]["popup top: tiny popup (1x1) uses popup width"] = function()
  local preview = get_preview()
  local geom = popup_geom({ row = 25, col = 50, width = 1, height = 1, border = "none" })
  local p = preview._compute_win_config(popup_params("top", { geom = geom, content_lines = 5 }))
  expect.equality(p.width, 1) -- matches popup width
  expect.equality(p.height, 5)
end

-- ─── _compute_win_config(): popup anchor large content ──────────────────────

T["_compute_win_config()"]["popup right: content 0 lines gives height 1"] = function()
  local preview = get_preview()
  local p = preview._compute_win_config(popup_params("right", { content_lines = 0 }))
  expect.equality(p.height, 1) -- math.max(1, min(15, 0))
end

T["_compute_win_config()"]["popup bottom: content capped by available space"] = function()
  local preview = get_preview()
  -- height "40%" of 50 = 20, content = 500, start_row = 37, available = 50 - 37 - 2 = 11
  local p = preview._compute_win_config(popup_params("bottom", { content_lines = 500 }))
  expect.equality(p.height, 11) -- clamped to available=11
end

-- ─── Popup anchor: clamping to available screen space ─────────────────────

T["_compute_win_config()"]["popup right: width clamped near right edge"] = function()
  local preview = get_preview()
  local geom = popup_geom({ col = 170, width = 20 }) -- border=rounded
  local p = preview._compute_win_config(popup_params("right", { geom = geom }))
  -- start_col = 170 + 20 + 2 = 192, available = 200 - 192 = 8
  expect.equality(p.col, 192)
  expect.equality(p.width, 6) -- min(80, 8) - 2 = 6
end

T["_compute_win_config()"]["popup right: returns nil when no space"] = function()
  local preview = get_preview()
  local geom = popup_geom({ col = 180, width = 20 }) -- border=rounded
  local p = preview._compute_win_config(popup_params("right", { geom = geom }))
  -- start_col = 180 + 20 + 2 = 202, available = 200 - 202 = -2 < 3 → nil
  expect.equality(p, nil)
end

T["_compute_win_config()"]["popup right: exact minimum (3 cols) still shows"] = function()
  local preview = get_preview()
  local geom = popup_geom({ col = 175, width = 20 }) -- border=rounded
  local p = preview._compute_win_config(popup_params("right", { geom = geom }))
  -- start_col = 175 + 20 + 2 = 197, available = 200 - 197 = 3 = MIN_PREVIEW_COLS
  expect.equality(p.col, 197)
  expect.equality(p.width, 1) -- min(80, 3) - 2 = 1
end

T["_compute_win_config()"]["popup right: 2 cols available returns nil"] = function()
  local preview = get_preview()
  local geom = popup_geom({ col = 176, width = 20 }) -- border=rounded
  local p = preview._compute_win_config(popup_params("right", { geom = geom }))
  -- start_col = 176 + 20 + 2 = 198, available = 200 - 198 = 2 < 3 → nil
  expect.equality(p, nil)
end

T["_compute_win_config()"]["popup left: moderate space clamped"] = function()
  local preview = get_preview()
  local geom = popup_geom({ col = 50 }) -- border=rounded
  local p = preview._compute_win_config(popup_params("left", { geom = geom }))
  -- available = 50, w = min(80, 50) = 50
  expect.equality(p.col, 0) -- 50 - 50 = 0
  expect.equality(p.width, 48) -- 50 - 2
end

T["_compute_win_config()"]["popup left: exact minimum (3 cols) still shows"] = function()
  local preview = get_preview()
  local geom = popup_geom({ col = 3 }) -- border=rounded, available = 3
  local p = preview._compute_win_config(popup_params("left", { geom = geom }))
  expect.equality(p.col, 0) -- 3 - 3 = 0
  expect.equality(p.width, 1) -- min(80, 3) - 2 = 1
end

T["_compute_win_config()"]["popup top: returns nil when popup at row 1"] = function()
  local preview = get_preview()
  local geom = popup_geom({ row = 1 })
  local p = preview._compute_win_config(popup_params("top", { geom = geom, content_lines = 10 }))
  -- available = 1 - 2 = -1 < MIN_PREVIEW_ROWS → nil
  expect.equality(p, nil)
end

T["_compute_win_config()"]["popup top: exact minimum (1 row) still shows"] = function()
  local preview = get_preview()
  local geom = popup_geom({ row = 3 })
  local p = preview._compute_win_config(popup_params("top", { geom = geom, content_lines = 100 }))
  -- available = 3 - 2 = 1 = MIN_PREVIEW_ROWS
  expect.equality(p.row, 0) -- 3 - 1 - 2 = 0
  expect.equality(p.height, 1) -- min(20, 100, 1) = 1
end

T["_compute_win_config()"]["popup bottom: returns nil when no space"] = function()
  local preview = get_preview()
  local geom = popup_geom({ row = 45, height = 3 }) -- border=rounded
  local p = preview._compute_win_config(popup_params("bottom", { geom = geom, content_lines = 5 }))
  -- start_row = 45 + 3 + 2 = 50, available = 50 - 50 - 2 = -2 < 1 → nil
  expect.equality(p, nil)
end

T["_compute_win_config()"]["popup bottom: exact minimum (1 row) still shows"] = function()
  local preview = get_preview()
  local geom = popup_geom({ row = 40, height = 5 }) -- border=rounded
  -- start_row = 40 + 5 + 2 = 47, available = 50 - 47 - 2 = 1
  local p =
    preview._compute_win_config(popup_params("bottom", { geom = geom, content_lines = 100 }))
  expect.equality(p.row, 47)
  expect.equality(p.height, 1) -- min(20, 100, 1) = 1
end

T["_compute_win_config()"]["popup left: content exactly matches popup height"] = function()
  local preview = get_preview()
  -- popup height = 15, content = 15
  local p = preview._compute_win_config(popup_params("left", { content_lines = 15 }))
  expect.equality(p.height, 15)
end

-- ─── _compute_win_config(): screen anchor varying editor sizes ──────────────

T["_compute_win_config()"]["screen right: large editor (400 cols)"] = function()
  local preview = get_preview()
  local p =
    preview._compute_win_config(screen_params("right", { editor_cols = 400, width = "25%" }))
  -- 25% of 400 = 100
  expect.equality(p.col, 300) -- 400 - 100
  expect.equality(p.width, 98) -- 100 - 2
end

T["_compute_win_config()"]["screen bottom: large editor (100 rows)"] = function()
  local preview = get_preview()
  local p =
    preview._compute_win_config(screen_params("bottom", { available_rows = 100, height = "10%" }))
  -- 10% of 100 = 10, row = 100 - 10 + 1 = 91
  expect.equality(p.row, 91)
  expect.equality(p.height, 8) -- 10 - 2
end

T["_compute_win_config()"]["screen left: 100% width fills entire editor minus border"] = function()
  local preview = get_preview()
  local p = preview._compute_win_config(screen_params("left", { editor_cols = 80, width = "100%" }))
  expect.equality(p.col, 0)
  expect.equality(p.width, 78) -- 80 - 2
end

T["_compute_win_config()"]["screen top: 100% height fills all available rows minus border"] = function()
  local preview = get_preview()
  local p =
    preview._compute_win_config(screen_params("top", { available_rows = 30, height = "100%" }))
  expect.equality(p.row, 0)
  expect.equality(p.height, 28) -- 30 - 2
end

-- ─── _compute_win_config(): priority="preview" ───────────────────────────────

T["_compute_win_config()"]["popup right: priority=preview uses configured height, not popup height"] = function()
  local preview = get_preview()
  -- popup height 15, height "40%" of 50 = 20, content 100
  -- with priority=menu: h = min(15, 100) = 15
  -- with priority=preview: h = min(20, 100) = 20
  local p = preview._compute_win_config(
    popup_params("right", { content_lines = 100, priority = "preview" })
  )
  expect.equality(p.height, 20)
end

T["_compute_win_config()"]["popup right: priority=menu caps to popup height (default)"] = function()
  local preview = get_preview()
  local p =
    preview._compute_win_config(popup_params("right", { content_lines = 100, priority = "menu" }))
  expect.equality(p.height, 15) -- capped to popup geom.height
end

T["_compute_win_config()"]["popup right: priority=preview still shrinks to content"] = function()
  local preview = get_preview()
  -- content 5 < configured height (20) → uses content
  local p =
    preview._compute_win_config(popup_params("right", { content_lines = 5, priority = "preview" }))
  expect.equality(p.height, 5)
end

T["_compute_win_config()"]["popup left: priority=preview uses configured height"] = function()
  local preview = get_preview()
  local geom = popup_geom({ col = 100 })
  local p = preview._compute_win_config(
    popup_params("left", { geom = geom, content_lines = 100, priority = "preview" })
  )
  -- height "40%" of 50 = 20
  expect.equality(p.height, 20)
end

T["_compute_win_config()"]["popup left: priority=menu caps to popup height"] = function()
  local preview = get_preview()
  local geom = popup_geom({ col = 100 })
  local p = preview._compute_win_config(
    popup_params("left", { geom = geom, content_lines = 100, priority = "menu" })
  )
  expect.equality(p.height, 15)
end

T["_compute_win_config()"]["popup top/bottom: priority does not change behavior"] = function()
  local preview = get_preview()
  -- top/bottom already use configured dimensions, not popup height
  local p_menu =
    preview._compute_win_config(popup_params("top", { content_lines = 5, priority = "menu" }))
  local p_prev =
    preview._compute_win_config(popup_params("top", { content_lines = 5, priority = "preview" }))
  expect.equality(p_menu.height, p_prev.height)
end

-- ─── _parse_dim(): edge cases ───────────────────────────────────────────────

T["_parse_dim()"]["negative integer clamps to 1"] = function()
  local preview = get_preview()
  expect.equality(preview._parse_dim(-5, 100), 1)
end

T["_parse_dim()"]["1% of small total is at least 1"] = function()
  local preview = get_preview()
  -- 1% of 3 = 0.03 → floor = 0 → max(1, 0) = 1
  expect.equality(preview._parse_dim("1%", 3), 1)
end

T["_parse_dim()"]["0% returns 1 (minimum)"] = function()
  local preview = get_preview()
  expect.equality(preview._parse_dim("0%", 200), 1)
end

T["_parse_dim()"]["integer equal to total returns total"] = function()
  local preview = get_preview()
  expect.equality(preview._parse_dim(50, 50), 50)
end

T["_parse_dim()"]["integer 1 returns 1"] = function()
  local preview = get_preview()
  expect.equality(preview._parse_dim(1, 200), 1)
end

T["_parse_dim()"]["boolean falls back to half total"] = function()
  local preview = get_preview()
  expect.equality(preview._parse_dim(true, 60), 30)
end

-- ─── update(): state behavior ───────────────────────────────────────────────

T["update()"] = new_set()

T["update()"]["does nothing when not configured"] = function()
  local preview = get_preview()
  -- Should not error
  preview.update({ selected = 0 }, { value = { "foo" }, data = {} })
end

T["update()"]["does nothing when disabled"] = function()
  local preview = get_preview()
  preview.setup({ enabled = false })
  -- Should not error
  preview.update({ selected = 0 }, { value = { "foo" }, data = {} })
end

T["update()"]["hides when no candidate selected"] = function()
  local preview = get_preview()
  preview.setup({})
  -- selected = -1 means no selection → should hide (not error)
  preview.update({ selected = -1 }, { value = { "foo", "bar" }, data = {} })
end

T["update()"]["hides when selected is out of range"] = function()
  local preview = get_preview()
  preview.setup({})
  -- selected = 5 but only 2 candidates
  preview.update({ selected = 5 }, { value = { "foo", "bar" }, data = {} })
end

T["update()"]["hides when candidates list is empty"] = function()
  local preview = get_preview()
  preview.setup({})
  preview.update({ selected = 0 }, { value = {}, data = {} })
end

-- ─── _reset(): state cleanup ────────────────────────────────────────────────

T["_reset()"] = new_set()

T["_reset()"]["clears active state"] = function()
  local preview = get_preview()
  preview.setup({ enabled = true })
  expect.equality(preview.is_active(), true)
  preview._reset()
  expect.equality(preview.is_active(), false)
end

T["_reset()"]["is safe to call multiple times"] = function()
  local preview = get_preview()
  preview._reset()
  preview._reset()
  preview._reset()
  expect.equality(preview.is_active(), false)
end

-- ─── get_geometry() ─────────────────────────────────────────────────────────

T["get_geometry()"] = new_set()

T["get_geometry()"]["returns visible=false when no window"] = function()
  local preview = get_preview()
  local g = preview.get_geometry()
  expect.equality(g.visible, false)
  expect.equality(g.row, 0)
  expect.equality(g.col, 0)
  expect.equality(g.width, 0)
  expect.equality(g.height, 0)
end

-- ─── apply_geometry() ───────────────────────────────────────────────────────

T["apply_geometry()"] = new_set()

T["apply_geometry()"]["safe to call when no window"] = function()
  local preview = get_preview()
  -- Should not error
  preview.apply_geometry({ row = 0, col = 0, width = 10, height = 5 })
end

-- ─── center_col() ───────────────────────────────────────────────────────────

T["center_col()"] = new_set()

T["center_col()"]["centers narrow content"] = function()
  local renderer_util = require("wildest.renderer")
  -- content 40, editor 100, col 0 → (100-40)/2 = 30
  expect.equality(renderer_util.center_col(0, 40, 100), 30)
end

T["center_col()"]["returns col unchanged when content fills width"] = function()
  local renderer_util = require("wildest.renderer")
  expect.equality(renderer_util.center_col(0, 100, 100), 0)
end

T["center_col()"]["returns col unchanged when content exceeds width"] = function()
  local renderer_util = require("wildest.renderer")
  expect.equality(renderer_util.center_col(0, 120, 100), 0)
end

T["center_col()"]["accounts for non-zero col offset"] = function()
  local renderer_util = require("wildest.renderer")
  -- col=10, content 40, editor 100 → 10 + (100-40)/2 = 40
  expect.equality(renderer_util.center_col(10, 40, 100), 40)
end

T["center_col()"]["floors fractional centering"] = function()
  local renderer_util = require("wildest.renderer")
  -- content 41, editor 100 → (100-41)/2 = 29.5 → floor = 29
  expect.equality(renderer_util.center_col(0, 41, 100), 29)
end

-- ─── parse_dimension() ──────────────────────────────────────────────────────

T["parse_dimension()"] = new_set()

T["parse_dimension()"]["returns number as-is"] = function()
  local renderer_util = require("wildest.renderer")
  expect.equality(renderer_util.parse_dimension(42, 200), 42)
  expect.equality(renderer_util.parse_dimension(0, 200), 0)
end

T["parse_dimension()"]["parses percentage string"] = function()
  local renderer_util = require("wildest.renderer")
  expect.equality(renderer_util.parse_dimension("50%", 200), 100)
  expect.equality(renderer_util.parse_dimension("75%", 80), 60)
end

T["parse_dimension()"]["returns total for non-parseable input"] = function()
  local renderer_util = require("wildest.renderer")
  expect.equality(renderer_util.parse_dimension("abc", 200), 200)
  expect.equality(renderer_util.parse_dimension(nil, 80), 80)
end

-- ─── parse_margin() ─────────────────────────────────────────────────────────

T["parse_margin()"] = new_set()

T["parse_margin()"]["auto centers content"] = function()
  local renderer_util = require("wildest.renderer")
  -- total=200, content=80 → (200-80)/2 = 60
  expect.equality(renderer_util.parse_margin("auto", 200, 80), 60)
end

T["parse_margin()"]["returns number as-is"] = function()
  local renderer_util = require("wildest.renderer")
  expect.equality(renderer_util.parse_margin(15, 200, 80), 15)
end

T["parse_margin()"]["parses percentage"] = function()
  local renderer_util = require("wildest.renderer")
  expect.equality(renderer_util.parse_margin("10%", 200, 80), 20)
end

T["parse_margin()"]["returns 0 for non-parseable input"] = function()
  local renderer_util = require("wildest.renderer")
  expect.equality(renderer_util.parse_margin("xyz", 200, 80), 0)
  expect.equality(renderer_util.parse_margin(nil, 200, 80), 0)
end

-- ─── _normalize_gap() ─────────────────────────────────────────────────────

T["_normalize_gap()"] = new_set()

T["_normalize_gap()"]["number → uniform table"] = function()
  local preview = get_preview()
  local g = preview._normalize_gap(3)
  expect.equality(g, { top = 3, right = 3, bottom = 3, left = 3, between = 3 })
end

T["_normalize_gap()"]["nil → all zeros"] = function()
  local preview = get_preview()
  local g = preview._normalize_gap(nil)
  expect.equality(g, { top = 0, right = 0, bottom = 0, left = 0, between = 0 })
end

T["_normalize_gap()"]["table with all keys"] = function()
  local preview = get_preview()
  local g = preview._normalize_gap({ top = 1, right = 2, bottom = 3, left = 4, between = 5 })
  expect.equality(g, { top = 1, right = 2, bottom = 3, left = 4, between = 5 })
end

T["_normalize_gap()"]["partial table defaults missing to 0"] = function()
  local preview = get_preview()
  local g = preview._normalize_gap({ top = 2, between = 3 })
  expect.equality(g, { top = 2, right = 0, bottom = 0, left = 0, between = 3 })
end

T["_normalize_gap()"]["negative number clamps to 0"] = function()
  local preview = get_preview()
  local g = preview._normalize_gap(-5)
  expect.equality(g, { top = 0, right = 0, bottom = 0, left = 0, between = 0 })
end

T["_normalize_gap()"]["negative table values clamp to 0"] = function()
  local preview = get_preview()
  local g = preview._normalize_gap({ top = -1, right = 2, bottom = -3, left = 0, between = -1 })
  expect.equality(g, { top = 0, right = 2, bottom = 0, left = 0, between = 0 })
end

T["_normalize_gap()"]["zero number → all zeros"] = function()
  local preview = get_preview()
  local g = preview._normalize_gap(0)
  expect.equality(g, { top = 0, right = 0, bottom = 0, left = 0, between = 0 })
end

T["_normalize_gap()"]["string input → all zeros"] = function()
  local preview = get_preview()
  local g = preview._normalize_gap("invalid")
  expect.equality(g, { top = 0, right = 0, bottom = 0, left = 0, between = 0 })
end

-- ─── is_preview_priority() ──────────────────────────────────────────────────

T["is_preview_priority()"] = new_set()

T["is_preview_priority()"]["false when not configured"] = function()
  local preview = get_preview()
  expect.equality(preview.is_preview_priority(), false)
end

T["is_preview_priority()"]["false by default (menu priority)"] = function()
  local preview = get_preview()
  preview.setup({})
  expect.equality(preview.is_preview_priority(), false)
end

T["is_preview_priority()"]["true when priority=preview"] = function()
  local preview = get_preview()
  preview.setup({ priority = "preview" })
  expect.equality(preview.is_preview_priority(), true)
end

T["is_preview_priority()"]["false when priority=menu"] = function()
  local preview = get_preview()
  preview.setup({ priority = "menu" })
  expect.equality(preview.is_preview_priority(), false)
end

-- ─── setup() gap integration ─────────────────────────────────────────────

T["setup()"]["gap stored as normalized table from number"] = function()
  local preview = get_preview()
  preview.setup({ gap = 2 })
  -- Verify via reserved_space (popup anchor right, gap=2 uniform)
  -- The gap is stored internally; test through behavior
  expect.equality(preview.is_active(), true)
end

-- ─── reserved_space() with gap ───────────────────────────────────────────

T["reserved_space()"]["popup anchor + right with gap adds between and edge"] = function()
  local preview = get_preview()
  require("wildest.gaps").setup(3, 3)
  preview.setup({ position = "right", anchor = "popup", width = "50%" })
  local s = preview.reserved_space()
  local expected_width = preview._parse_dim("50%", vim.o.columns)
  -- right = outer.right + width + inner = 3 + width + 3
  expect.equality(s.right, expected_width + 3 + 3)
  expect.equality(s.top, 3)
  expect.equality(s.bottom, 3)
  expect.equality(s.left, 3)
end

T["reserved_space()"]["popup anchor + left with gap adds between and edge"] = function()
  local preview = get_preview()
  require("wildest.gaps").setup(2, 2)
  preview.setup({ position = "left", anchor = "popup", width = "50%" })
  local s = preview.reserved_space()
  local expected_width = preview._parse_dim("50%", vim.o.columns)
  -- left = outer.left + width + inner = 2 + width + 2
  expect.equality(s.left, expected_width + 2 + 2)
  expect.equality(s.top, 2)
  expect.equality(s.bottom, 2)
  expect.equality(s.right, 2)
end

-- ─── _compute_win_config() with gap ──────────────────────────────────────

T["_compute_win_config()"]["popup right: between gap shifts start_col"] = function()
  local preview = get_preview()
  local gap = { top = 0, right = 0, bottom = 0, left = 0, between = 5 }
  local geom = popup_geom() -- row=20, col=30, w=60, h=15, border=rounded
  local p = preview._compute_win_config(popup_params("right", { geom = geom, gap = gap }))
  -- border_size=1, col = 30 + 60 + 2 + 5 = 97
  expect.equality(p.col, 97)
  expect.equality(p.row, 20)
end

T["_compute_win_config()"]["popup right: right gap reduces available space"] = function()
  local preview = get_preview()
  require("wildest.gaps").setup({ top = 0, right = 10, bottom = 0, left = 0 }, 0)
  local geom = popup_geom({ col = 170, width = 20 }) -- border=rounded
  local p = preview._compute_win_config(popup_params("right", { geom = geom }))
  -- start_col = 170 + 20 + 2 = 192, avail = 200 - 192 - 10 = -2 < 3 → nil
  expect.equality(p, nil)
end

T["_compute_win_config()"]["popup left: between gap shifts col"] = function()
  local preview = get_preview()
  local gap = { top = 0, right = 0, bottom = 0, left = 0, between = 3 }
  local geom = popup_geom({ col = 50 }) -- border=rounded
  local p = preview._compute_win_config(popup_params("left", { geom = geom, gap = gap }))
  -- avail = 50 - 3 - 0 = 47, w = min(80, 47) = 47
  -- col = 50 - 47 - 3 = 0
  expect.equality(p.col, 0)
  expect.equality(p.width, 45) -- 47 - 2
end

T["_compute_win_config()"]["popup left: left gap reduces available space"] = function()
  local preview = get_preview()
  require("wildest.gaps").setup({ top = 0, right = 0, bottom = 0, left = 5 }, 0)
  local geom = popup_geom({ col = 7 }) -- border=rounded
  local p = preview._compute_win_config(popup_params("left", { geom = geom }))
  -- avail = 7 - 0 - 5 = 2 < 3 → nil
  expect.equality(p, nil)
end

T["_compute_win_config()"]["popup top: between gap shifts row"] = function()
  local preview = get_preview()
  local gap = { top = 0, right = 0, bottom = 0, left = 0, between = 2 }
  local geom = popup_geom({ row = 20 })
  local p =
    preview._compute_win_config(popup_params("top", { geom = geom, gap = gap, content_lines = 5 }))
  -- h=5, row = 20 - 5 - 2 - 2 = 11
  expect.equality(p.row, 11)
  expect.equality(p.height, 5)
end

T["_compute_win_config()"]["popup bottom: between gap shifts start_row"] = function()
  local preview = get_preview()
  local gap = { top = 0, right = 0, bottom = 0, left = 0, between = 3 }
  local geom = popup_geom() -- row=20, h=15, border=rounded
  local p = preview._compute_win_config(
    popup_params("bottom", { geom = geom, gap = gap, content_lines = 5 })
  )
  -- border_size=1, start_row = 20 + 15 + 2 + 3 = 40
  expect.equality(p.row, 40)
end

T["_compute_win_config()"]["popup bottom: bottom gap reduces available space"] = function()
  local preview = get_preview()
  require("wildest.gaps").setup({ top = 0, right = 0, bottom = 5, left = 0 }, 0)
  local geom = popup_geom({ row = 40, height = 5 }) -- border=rounded
  local p = preview._compute_win_config(
    popup_params("bottom", { geom = geom, content_lines = 3 })
  )
  -- start_row = 40 + 5 + 2 + 0 = 47, avail = 50 - 47 - 2 - 5 = -4 < 1 → nil
  expect.equality(p, nil)
end

T["_compute_win_config()"]["screen right: gap insets from edges"] = function()
  local preview = get_preview()
  require("wildest.gaps").setup({ top = 2, right = 3, bottom = 2, left = 0 }, 0)
  local p = preview._compute_win_config(screen_params("right"))
  -- w = 80, col = 200 - 80 - 3 = 117
  expect.equality(p.col, 117)
  expect.equality(p.row, 2)
  expect.equality(p.height, 46) -- 50 - 2 - 2
  expect.equality(p.width, 78) -- 80 - 2 (border)
end

T["_compute_win_config()"]["screen left: gap insets from left edge"] = function()
  local preview = get_preview()
  require("wildest.gaps").setup({ top = 1, right = 0, bottom = 1, left = 5 }, 0)
  local p = preview._compute_win_config(screen_params("left"))
  expect.equality(p.col, 5)
  expect.equality(p.row, 1)
  expect.equality(p.height, 48) -- 50 - 1 - 1
end

T["_compute_win_config()"]["screen top: gap insets from top and sides"] = function()
  local preview = get_preview()
  require("wildest.gaps").setup({ top = 3, right = 4, bottom = 0, left = 4 }, 0)
  local p = preview._compute_win_config(screen_params("top"))
  expect.equality(p.row, 3)
  expect.equality(p.col, 4)
  -- width = max(1, 200 - 2 - 4 - 4) = 190
  expect.equality(p.width, 190)
end

T["_compute_win_config()"]["screen bottom: gap insets from bottom and sides"] = function()
  local preview = get_preview()
  require("wildest.gaps").setup({ top = 0, right = 2, bottom = 3, left = 2 }, 0)
  local p = preview._compute_win_config(screen_params("bottom"))
  -- h = 20, row = 50 - 20 + 1 - 3 = 28
  expect.equality(p.row, 28)
  expect.equality(p.col, 2)
  -- width = max(1, 200 - 2 - 2 - 2) = 194
  expect.equality(p.width, 194)
end

T["_compute_win_config()"]["no gap param defaults to zero gaps"] = function()
  local preview = get_preview()
  -- Omitting gap entirely should behave like the original
  local p = preview._compute_win_config(screen_params("right"))
  expect.equality(p.row, 0)
  expect.equality(p.col, 120) -- 200 - 80
  expect.equality(p.width, 78)
  expect.equality(p.height, 50)
end

return T

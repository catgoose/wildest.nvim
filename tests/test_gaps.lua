local MiniTest = require("mini.test")
local new_set = MiniTest.new_set
local expect = MiniTest.expect

local T = new_set()

local function get_gaps()
  local gaps = require("wildest.gaps")
  gaps.setup(nil, nil) -- reset
  return gaps
end

-- ─── setup() ────────────────────────────────────────────────────────────────

T["setup()"] = new_set()

T["setup()"]["nil resets to zero"] = function()
  local gaps = get_gaps()
  gaps.setup(nil, nil)
  expect.equality(gaps.gutter(), { top = 0, right = 0, bottom = 0, left = 0 })
  expect.equality(gaps.gap(), 0)
end

T["setup()"]["gutter number sets uniform edges"] = function()
  local gaps = get_gaps()
  gaps.setup(3, nil)
  expect.equality(gaps.gutter(), { top = 3, right = 3, bottom = 3, left = 3 })
  expect.equality(gaps.gap(), 0)
end

T["setup()"]["gap number sets between-window spacing"] = function()
  local gaps = get_gaps()
  gaps.setup(nil, 2)
  expect.equality(gaps.gutter(), { top = 0, right = 0, bottom = 0, left = 0 })
  expect.equality(gaps.gap(), 2)
end

T["setup()"]["gutter and gap together"] = function()
  local gaps = get_gaps()
  gaps.setup(3, 1)
  expect.equality(gaps.gutter(), { top = 3, right = 3, bottom = 3, left = 3 })
  expect.equality(gaps.gap(), 1)
end

T["setup()"]["gutter 0 sets all to zero"] = function()
  local gaps = get_gaps()
  gaps.setup(0, 0)
  expect.equality(gaps.gutter(), { top = 0, right = 0, bottom = 0, left = 0 })
  expect.equality(gaps.gap(), 0)
end

T["setup()"]["negative gutter clamps to zero"] = function()
  local gaps = get_gaps()
  gaps.setup(-5, -3)
  expect.equality(gaps.gutter(), { top = 0, right = 0, bottom = 0, left = 0 })
  expect.equality(gaps.gap(), 0)
end

T["setup()"]["gutter table per-edge"] = function()
  local gaps = get_gaps()
  gaps.setup({ top = 1, right = 2, bottom = 3, left = 4 }, 5)
  expect.equality(gaps.gutter(), { top = 1, right = 2, bottom = 3, left = 4 })
  expect.equality(gaps.gap(), 5)
end

T["setup()"]["gutter table with partial keys defaults missing to 0"] = function()
  local gaps = get_gaps()
  gaps.setup({ top = 2, left = 3 }, nil)
  expect.equality(gaps.gutter(), { top = 2, right = 0, bottom = 0, left = 3 })
  expect.equality(gaps.gap(), 0)
end

T["setup()"]["negative values in gutter table clamp to zero"] = function()
  local gaps = get_gaps()
  gaps.setup({ top = -1, right = 2, bottom = -3, left = 4 }, nil)
  expect.equality(gaps.gutter(), { top = 0, right = 2, bottom = 0, left = 4 })
end

T["setup()"]["empty gutter table resets to zero"] = function()
  local gaps = get_gaps()
  gaps.setup(3, 3) -- set first
  gaps.setup({}, nil)
  expect.equality(gaps.gutter(), { top = 0, right = 0, bottom = 0, left = 0 })
  expect.equality(gaps.gap(), 0)
end

-- ─── _normalize_edges() ─────────────────────────────────────────────────────

T["_normalize_edges()"] = new_set()

T["_normalize_edges()"]["number returns uniform edges"] = function()
  local gaps = get_gaps()
  expect.equality(gaps._normalize_edges(4), { top = 4, right = 4, bottom = 4, left = 4 })
end

T["_normalize_edges()"]["nil returns zero edges"] = function()
  local gaps = get_gaps()
  expect.equality(gaps._normalize_edges(nil), { top = 0, right = 0, bottom = 0, left = 0 })
end

T["_normalize_edges()"]["table with all keys"] = function()
  local gaps = get_gaps()
  expect.equality(
    gaps._normalize_edges({ top = 1, right = 2, bottom = 3, left = 4 }),
    { top = 1, right = 2, bottom = 3, left = 4 }
  )
end

T["_normalize_edges()"]["table with missing keys defaults to 0"] = function()
  local gaps = get_gaps()
  expect.equality(gaps._normalize_edges({ top = 5 }), { top = 5, right = 0, bottom = 0, left = 0 })
end

return T

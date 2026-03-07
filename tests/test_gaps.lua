local MiniTest = require("mini.test")
local new_set = MiniTest.new_set
local expect = MiniTest.expect

local T = new_set()

local function get_gaps()
  local gaps = require("wildest.gaps")
  gaps.setup(nil) -- reset
  return gaps
end

-- ─── setup() ────────────────────────────────────────────────────────────────

T["setup()"] = new_set()

T["setup()"]["nil resets to zero"] = function()
  local gaps = get_gaps()
  gaps.setup(nil)
  expect.equality(gaps.outer(), { top = 0, right = 0, bottom = 0, left = 0 })
  expect.equality(gaps.inner(), 0)
end

T["setup()"]["number sets uniform outer and inner"] = function()
  local gaps = get_gaps()
  gaps.setup(3)
  expect.equality(gaps.outer(), { top = 3, right = 3, bottom = 3, left = 3 })
  expect.equality(gaps.inner(), 3)
end

T["setup()"]["number 0 sets all to zero"] = function()
  local gaps = get_gaps()
  gaps.setup(0)
  expect.equality(gaps.outer(), { top = 0, right = 0, bottom = 0, left = 0 })
  expect.equality(gaps.inner(), 0)
end

T["setup()"]["negative number clamps to zero"] = function()
  local gaps = get_gaps()
  gaps.setup(-5)
  expect.equality(gaps.outer(), { top = 0, right = 0, bottom = 0, left = 0 })
  expect.equality(gaps.inner(), 0)
end

T["setup()"]["table with outer number and inner"] = function()
  local gaps = get_gaps()
  gaps.setup({ outer = 2, inner = 1 })
  expect.equality(gaps.outer(), { top = 2, right = 2, bottom = 2, left = 2 })
  expect.equality(gaps.inner(), 1)
end

T["setup()"]["table with outer table per-edge"] = function()
  local gaps = get_gaps()
  gaps.setup({ outer = { top = 1, right = 2, bottom = 3, left = 4 }, inner = 5 })
  expect.equality(gaps.outer(), { top = 1, right = 2, bottom = 3, left = 4 })
  expect.equality(gaps.inner(), 5)
end

T["setup()"]["table with partial outer defaults missing edges to 0"] = function()
  local gaps = get_gaps()
  gaps.setup({ outer = { top = 2, left = 3 } })
  expect.equality(gaps.outer(), { top = 2, right = 0, bottom = 0, left = 3 })
  expect.equality(gaps.inner(), 0)
end

T["setup()"]["table with only inner"] = function()
  local gaps = get_gaps()
  gaps.setup({ inner = 4 })
  expect.equality(gaps.outer(), { top = 0, right = 0, bottom = 0, left = 0 })
  expect.equality(gaps.inner(), 4)
end

T["setup()"]["table with only outer number"] = function()
  local gaps = get_gaps()
  gaps.setup({ outer = 5 })
  expect.equality(gaps.outer(), { top = 5, right = 5, bottom = 5, left = 5 })
  expect.equality(gaps.inner(), 0)
end

T["setup()"]["negative values in table clamp to zero"] = function()
  local gaps = get_gaps()
  gaps.setup({ outer = { top = -1, right = 2, bottom = -3, left = 4 }, inner = -2 })
  expect.equality(gaps.outer(), { top = 0, right = 2, bottom = 0, left = 4 })
  expect.equality(gaps.inner(), 0)
end

T["setup()"]["empty table resets to zero"] = function()
  local gaps = get_gaps()
  gaps.setup(3) -- set first
  gaps.setup({})
  expect.equality(gaps.outer(), { top = 0, right = 0, bottom = 0, left = 0 })
  expect.equality(gaps.inner(), 0)
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

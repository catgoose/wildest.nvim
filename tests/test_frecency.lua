local MiniTest = require("mini.test")
local new_set = MiniTest.new_set
local expect = MiniTest.expect

local T = new_set()

local frecency = require("wildest.frecency")

-- score() -----------------------------------------------------------------------

T["score()"] = new_set()

T["score()"]["returns 0 for unknown key"] = function()
  local score = frecency.score("nonexistent_key_12345", {})
  expect.equality(score, 0)
end

T["score()"]["returns 0 for empty data"] = function()
  local score = frecency.score("anything", {})
  expect.equality(score, 0)
end

T["score()"]["scores recent timestamps higher"] = function()
  local now = os.time()
  local data = {
    recent = { count = 1, timestamps = { now } },
    old = { count = 1, timestamps = { now - 30 * 24 * 3600 - 1 } },
  }
  local recent_score = frecency.score("recent", data)
  local old_score = frecency.score("old", data)
  expect.equality(recent_score > old_score, true)
end

T["score()"]["accumulates score from multiple timestamps"] = function()
  local now = os.time()
  local data = {
    multi = { count = 3, timestamps = { now, now - 100, now - 200 } },
    single = { count = 1, timestamps = { now } },
  }
  local multi_score = frecency.score("multi", data)
  local single_score = frecency.score("single", data)
  expect.equality(multi_score > single_score, true)
end

T["score()"]["respects time bucket boundaries"] = function()
  local now = os.time()
  -- Within 4 hours = weight 100
  local data_4h = { key = { count = 1, timestamps = { now - 3600 } } }
  -- Within 24 hours but beyond 4 hours = weight 80
  local data_24h = { key = { count = 1, timestamps = { now - 12 * 3600 } } }

  local score_4h = frecency.score("key", data_4h)
  local score_24h = frecency.score("key", data_24h)
  expect.equality(score_4h, 100)
  expect.equality(score_24h, 80)
end

T["score()"]["uses custom weights"] = function()
  local now = os.time()
  local data = { key = { count = 1, timestamps = { now } } }
  local custom_weights = {
    { age = math.huge, weight = 42 },
  }
  local score = frecency.score("key", data, custom_weights)
  expect.equality(score, 42)
end

-- boost() -----------------------------------------------------------------------

T["boost()"] = new_set()

T["boost()"]["returns empty table for empty candidates"] = function()
  local boost_fn = frecency.boost()
  local result = boost_fn({}, {})
  expect.equality(result, {})
end

T["boost()"]["returns nil for nil candidates"] = function()
  local boost_fn = frecency.boost()
  local result = boost_fn({}, nil)
  expect.equality(result, nil)
end

T["boost()"]["preserves all candidates"] = function()
  local boost_fn = frecency.boost()
  local input = { "alpha", "beta", "gamma" }
  local result = boost_fn({}, input)
  expect.equality(#result, 3)
  -- All items should be present
  local found = {}
  for _, c in ipairs(result) do
    found[c] = true
  end
  expect.equality(found["alpha"], true)
  expect.equality(found["beta"], true)
  expect.equality(found["gamma"], true)
end

-- scorer() ----------------------------------------------------------------------

T["scorer()"] = new_set()

T["scorer()"]["returns a function"] = function()
  local fn = frecency.scorer()
  expect.equality(type(fn), "function")
end

T["scorer()"]["scorer returns 0 for unknown items"] = function()
  local fn = frecency.scorer()
  local score = fn("totally_unknown_item_xyz", {})
  expect.equality(score, 0)
end

return T

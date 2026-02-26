local MiniTest = require("mini.test")
local new_set = MiniTest.new_set
local expect = MiniTest.expect

local T = new_set()

local cache = require("wildest.cache")

T["dict_cache()"] = new_set()

T["dict_cache()"]["get/set basic operations"] = function()
  local c = cache.dict_cache()
  expect.equality(c.get("key"), nil)
  c.set("key", "value")
  expect.equality(c.get("key"), "value")
end

T["dict_cache()"]["has() checks existence"] = function()
  local c = cache.dict_cache()
  expect.equality(c.has("key"), false)
  c.set("key", 42)
  expect.equality(c.has("key"), true)
end

T["dict_cache()"]["clear() removes all entries"] = function()
  local c = cache.dict_cache()
  c.set("a", 1)
  c.set("b", 2)
  c.clear()
  expect.equality(c.has("a"), false)
  expect.equality(c.has("b"), false)
end

T["dict_cache()"]["overwrites existing keys"] = function()
  local c = cache.dict_cache()
  c.set("key", "old")
  c.set("key", "new")
  expect.equality(c.get("key"), "new")
end

T["mru_cache()"] = new_set()

T["mru_cache()"]["basic get/set"] = function()
  local c = cache.mru_cache(3)
  c.set("a", 1)
  c.set("b", 2)
  expect.equality(c.get("a"), 1)
  expect.equality(c.get("b"), 2)
end

T["mru_cache()"]["evicts oldest when at capacity"] = function()
  local c = cache.mru_cache(2)
  c.set("a", 1)
  c.set("b", 2)
  c.set("c", 3) -- 'a' should be evicted
  expect.equality(c.has("a"), false)
  expect.equality(c.get("b"), 2)
  expect.equality(c.get("c"), 3)
end

T["mru_cache()"]["accessing refreshes entry"] = function()
  local c = cache.mru_cache(2)
  c.set("a", 1)
  c.set("b", 2)
  c.get("a") -- refresh 'a', now 'b' is oldest
  c.set("c", 3) -- 'b' should be evicted, not 'a'
  expect.equality(c.get("a"), 1)
  expect.equality(c.has("b"), false)
  expect.equality(c.get("c"), 3)
end

T["mru_cache()"]["has() checks existence"] = function()
  local c = cache.mru_cache(5)
  expect.equality(c.has("key"), false)
  c.set("key", "val")
  expect.equality(c.has("key"), true)
end

T["mru_cache()"]["clear() removes all entries"] = function()
  local c = cache.mru_cache(5)
  c.set("a", 1)
  c.set("b", 2)
  c.clear()
  expect.equality(c.has("a"), false)
  expect.equality(c.has("b"), false)
end

T["mru_cache()"]["capacity of 1 works"] = function()
  local c = cache.mru_cache(1)
  c.set("a", 1)
  expect.equality(c.get("a"), 1)
  c.set("b", 2)
  expect.equality(c.has("a"), false)
  expect.equality(c.get("b"), 2)
end

return T

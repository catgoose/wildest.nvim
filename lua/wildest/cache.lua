---@mod wildest.cache Cache
---@brief [[
---Cache implementations for wildest.nvim.
---Provides dictionary and MRU (Most Recently Used) caches.
---@brief ]]

local M = {}

---@class wildest.DictCache
---@field _data table
local DictCache = {}
DictCache.__index = DictCache

function DictCache:get(key)
  return self._data[key]
end

function DictCache:set(key, value)
  self._data[key] = value
end

function DictCache:has(key)
  return self._data[key] ~= nil
end

function DictCache:clear()
  self._data = {}
end

---Create a simple dictionary cache.
---@return wildest.DictCache
function M.dict_cache()
  return setmetatable({ _data = {} }, DictCache)
end

---@class wildest.MRUCache : wildest.DictCache
---@field _order string[]
---@field _max_size integer
local MRUCache = setmetatable({}, { __index = DictCache })
MRUCache.__index = MRUCache

-- O(n) scan is intentional: max_size is small (~30) so a linear
-- search is simpler and faster than maintaining an auxiliary hash.
local function touch(self, key)
  for i, k in ipairs(self._order) do
    if k == key then
      table.remove(self._order, i)
      break
    end
  end
  table.insert(self._order, key)
end

local function evict(self)
  while #self._order > self._max_size do
    local oldest = table.remove(self._order, 1)
    self._data[oldest] = nil
  end
end

function MRUCache:get(key)
  if self._data[key] ~= nil then
    touch(self, key)
    return self._data[key]
  end
  return nil
end

function MRUCache:set(key, value)
  self._data[key] = value
  touch(self, key)
  evict(self)
end

function MRUCache:clear()
  self._data = {}
  self._order = {}
end

--- Create an MRU (Most Recently Used) cache with a max size
---@param max_size integer maximum number of entries
---@return wildest.MRUCache
function M.mru_cache(max_size)
  return setmetatable({ _data = {}, _order = {}, _max_size = max_size }, MRUCache)
end

return M

---@mod wildest.cache Cache
---@brief [[
---Cache implementations for wildest.nvim.
---Provides dictionary and MRU (Most Recently Used) caches.
---@brief ]]

local M = {}

---Create a simple dictionary cache.
---@return table cache object with get/set/clear/has methods
function M.dict_cache()
  local data = {}

  return {
    get = function(key)
      return data[key]
    end,
    set = function(key, value)
      data[key] = value
    end,
    has = function(key)
      return data[key] ~= nil
    end,
    clear = function()
      data = {}
    end,
  }
end

--- Create an MRU (Most Recently Used) cache with a max size
---@param max_size integer maximum number of entries
---@return table cache object with get/set/clear/has methods
function M.mru_cache(max_size)
  local data = {}
  local order = {} -- keys in order of use, most recent at end

  -- O(n) scan is intentional: max_size is small (~30) so a linear
  -- search is simpler and faster than maintaining an auxiliary hash.
  local function touch(key)
    for i, k in ipairs(order) do
      if k == key then
        table.remove(order, i)
        break
      end
    end
    table.insert(order, key)
  end

  local function evict()
    while #order > max_size do
      local oldest = table.remove(order, 1)
      data[oldest] = nil
    end
  end

  return {
    get = function(key)
      if data[key] ~= nil then
        touch(key)
        return data[key]
      end
      return nil
    end,
    set = function(key, value)
      data[key] = value
      touch(key)
      evict()
    end,
    has = function(key)
      return data[key] ~= nil
    end,
    clear = function()
      data = {}
      order = {}
    end,
  }
end

return M

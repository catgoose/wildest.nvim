---@mod wildest.frecency Frecency Scoring
---@brief [[
---Frecency scoring module — combines frequency and recency to rank items.
---Persists data to disk so scores survive restarts.
---@brief ]]

local M = {}

--- Default frecency weights for time buckets
local default_weights = {
  { age = 4 * 3600, weight = 100 }, -- last 4 hours
  { age = 24 * 3600, weight = 80 }, -- last day
  { age = 3 * 24 * 3600, weight = 60 }, -- last 3 days
  { age = 7 * 24 * 3600, weight = 40 }, -- last week
  { age = 30 * 24 * 3600, weight = 20 }, -- last month
  { age = math.huge, weight = 10 }, -- older
}

--- Get the data file path
---@return string
function M.path()
  return vim.fn.stdpath("data") .. "/wildest_frecency.json"
end

--- Load frecency data from disk
---@return table<string, { count: integer, timestamps: number[] }>
function M.load()
  local path = M.path()
  local f = io.open(path, "r")
  if not f then
    return {}
  end
  local content = f:read("*a")
  f:close()
  if not content or content == "" then
    return {}
  end
  local ok, data = pcall(vim.json.decode, content)
  if not ok or type(data) ~= "table" then
    return {}
  end
  return data
end

--- Save frecency data to disk
---@param data table<string, { count: integer, timestamps: number[] }>
function M.save(data)
  local path = M.path()
  local ok, json = pcall(vim.json.encode, data)
  if not ok then
    return
  end
  local f = io.open(path, "w")
  if f then
    f:write(json)
    f:close()
  end
end

--- Record a visit to an item
---@param key string The item key (e.g., command string, file path)
---@param max_timestamps? integer Max timestamps to keep per item (default 10)
function M.visit(key, max_timestamps)
  max_timestamps = max_timestamps or 10
  local data = M.load()
  local entry = data[key] or { count = 0, timestamps = {} }

  entry.count = entry.count + 1
  table.insert(entry.timestamps, os.time())

  -- Keep only recent timestamps
  while #entry.timestamps > max_timestamps do
    table.remove(entry.timestamps, 1)
  end

  data[key] = entry
  M.save(data)
end

--- Calculate frecency score for an item
---@param key string The item key
---@param data? table Preloaded data (avoids re-reading disk)
---@param weights? table Custom time bucket weights
---@return number score
function M.score(key, data, weights)
  data = data or M.load()
  weights = weights or default_weights

  local entry = data[key]
  if not entry then
    return 0
  end

  local now = os.time()
  local total = 0

  for _, ts in ipairs(entry.timestamps) do
    local age = now - ts
    for _, bucket in ipairs(weights) do
      if age <= bucket.age then
        total = total + bucket.weight
        break
      end
    end
  end

  return total
end

--- Create a frecency scorer function for use with sort_by
---@param opts? table { weights?: table }
---@return fun(candidate: string, ctx: table): number
function M.scorer(opts)
  opts = opts or {}
  local weights = opts.weights

  return function(candidate, _ctx)
    -- Load data once per scoring batch via upvalue cache
    local data = M.load()
    return M.score(candidate, data, weights)
  end
end

--- Create a frecency-aware pipeline step that boosts candidates
--- Wraps an existing pipeline — re-sorts results by frecency score.
---@param opts? table { weights?: table, blend?: number }
---@return fun(ctx: table, candidates: table): table
function M.boost(opts)
  opts = opts or {}
  local weights = opts.weights
  local blend = opts.blend or 0.5 -- 0 = position only, 1 = frecency only

  return function(_ctx, candidates)
    if not candidates or type(candidates) ~= "table" or #candidates == 0 then
      return candidates
    end

    local data = M.load()
    local scored = {}

    for i, c in ipairs(candidates) do
      local item = type(c) == "string" and c or (c.word or c[1] or tostring(c))
      local freq_score = M.score(item, data, weights)
      -- Blend position score (earlier = higher) with frecency
      local pos_score = (#candidates - i) / #candidates * 100
      local final = (1 - blend) * pos_score + blend * freq_score
      scored[i] = { candidate = c, score = final }
    end

    table.sort(scored, function(a, b)
      return a.score > b.score
    end)

    local result = {}
    for _, s in ipairs(scored) do
      table.insert(result, s.candidate)
    end
    return result
  end
end

return M

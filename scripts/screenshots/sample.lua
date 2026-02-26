-- Example: wildest.nvim configuration
-- This file is used as background content for screenshots

local M = {}

--- Default configuration for the completion engine
M.defaults = {
  modes = { ":", "/", "?" },
  trigger = "auto",
  noselect = true,
  interval = 100,
  num_workers = 2,
}

--- Merge user config with defaults
---@param opts table
---@return table
function M.setup(opts)
  local config = vim.tbl_deep_extend("force", M.defaults, opts or {})

  if config.pipeline == nil then
    vim.notify("[wildest] pipeline is required", vim.log.levels.ERROR)
    return config
  end

  if config.renderer == nil then
    vim.notify("[wildest] renderer is required", vim.log.levels.ERROR)
    return config
  end

  -- Create autocommands for cmdline lifecycle
  local augroup = vim.api.nvim_create_augroup("wildest", { clear = true })

  vim.api.nvim_create_autocmd("CmdlineEnter", {
    group = augroup,
    callback = function()
      local cmdtype = vim.fn.getcmdtype()
      M.state.start(cmdtype)
    end,
  })

  vim.api.nvim_create_autocmd("CmdlineChanged", {
    group = augroup,
    callback = function()
      local cmdline = vim.fn.getcmdline()
      if M.state.is_active() then
        M.state.on_change(cmdline)
      end
    end,
  })

  vim.api.nvim_create_autocmd("CmdlineLeave", {
    group = augroup,
    callback = function()
      M.state.stop()
    end,
  })

  return config
end

--- Pipeline step: filter candidates by fuzzy match score
---@param candidates string[]
---@param query string
---@return string[]
function M.fuzzy_filter(candidates, query)
  if query == "" then
    return candidates
  end

  local scored = {}
  for _, candidate in ipairs(candidates) do
    local score = M.fzy_score(candidate, query)
    if score > 0 then
      table.insert(scored, { candidate = candidate, score = score })
    end
  end

  table.sort(scored, function(a, b)
    return a.score > b.score
  end)

  local result = {}
  for _, entry in ipairs(scored) do
    table.insert(result, entry.candidate)
  end
  return result
end

return M

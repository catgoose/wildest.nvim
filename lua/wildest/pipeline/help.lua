---@mod wildest.pipeline.help Help Tag Completion
---@brief [[
---Help tag completion pipeline.
---@brief ]]

local result = require("wildest.pipeline.result")
local util = require("wildest.util")

local M = {}

--- Create a help tag completion pipeline
--- Completes help tags for `:help` commands with fuzzy matching.
---
---@param opts? table { fuzzy?: boolean, max_results?: integer }
---@return table pipeline array
function M.help_pipeline(opts)
  opts = opts or {}
  local max_results = opts.max_results or 200

  local function help_complete(ctx, input)
    if not input or input == "" then
      return false
    end
    if ctx.cmdtype ~= ":" then
      return false
    end

    -- Extract help argument
    local arg = input:match("^%s*h%a*%s+(.+)$")
    if not arg then
      return false
    end

    local ok, results = pcall(vim.fn.getcompletion, arg, "help")
    if not ok or not results or #results == 0 then
      return false
    end

    results = util.take(results, max_results)

    ctx.arg = arg
    return results
  end

  local pipeline = { help_complete }

  if opts.fuzzy then
    table.insert(pipeline, require("wildest.filter").fuzzy_filter())
  end

  table.insert(pipeline, result.result())
  return pipeline
end

return M

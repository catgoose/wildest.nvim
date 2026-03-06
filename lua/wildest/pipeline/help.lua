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
---@param opts? table { fuzzy?: boolean, max_results?: integer, help_cache?: boolean, engine?: "fast"|"vim"|table }
---@return table pipeline array
function M.help_pipeline(opts)
  opts = opts or {}
  local max_results = opts.max_results or 200

  -- Resolve help_cache from engine or legacy option
  local use_cache = opts.help_cache or false
  if not use_cache and opts.engine then
    if opts.engine == "fast" then
      use_cache = true
    elseif type(opts.engine) == "table" and opts.engine.help then
      use_cache = true
      -- Configure help_cache with custom command if provided
      local hc_opts = require("wildest.engine").to_help_cache_opts(opts.engine.help)
      if hc_opts and next(hc_opts) then
        require("wildest.pipeline.help_cache").configure(hc_opts)
      end
    end
  end

  local function help_complete(ctx, input)
    if not input or input == "" then
      return false
    end
    if ctx.cmdtype ~= ":" then
      return false
    end

    -- Extract help argument (may be empty after the space)
    local arg = input:match("^%s*h%a*%s+(.+)$")
    if not arg then
      if input:match("^%s*h%a*%s+$") then
        arg = ""
      else
        return false
      end
    end

    local results
    if use_cache then
      results = require("wildest.pipeline.help_cache").filter(arg)
    else
      local ok, tags = pcall(vim.fn.getcompletion, arg, "help")
      if ok then
        results = tags
      end
    end

    if not results or #results == 0 then
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

  table.insert(pipeline, result.result({ data = { expand = "help" } }))
  return pipeline
end

return M

---@mod wildest.pipeline.lua_complete Lua Expression Completion
---@brief [[
---Lua expression completion pipeline.
---@brief ]]

local result = require("wildest.pipeline.result")
local util = require("wildest.util")

local M = {}

--- Create a Lua completion pipeline
--- Completes Lua expressions for `:lua`, `:=`, and Lua cmdline contexts.
--- Completes module paths (require('...')), table fields, and globals.
---
---@param opts? table { max_results?: integer }
---@return table pipeline array
function M.lua_pipeline(opts)
  opts = opts or {}
  local max_results = opts.max_results or 200

  --- Extract the Lua expression being completed
  ---@param input string
  ---@return string|nil expr, string prefix
  local function extract_lua_expr(input)
    -- :lua expr, := expr, :lua= expr
    local expr = input:match("^%s*lua%s+(.*)$")
      or input:match("^%s*=%s*(.*)$")
      or input:match("^%s*lua=%s*(.*)$")
    if not expr then
      return nil, ""
    end
    return expr, expr
  end

  --- Get completions for a Lua expression
  ---@param expr string
  ---@return string[]
  local function complete_lua(expr)
    -- Try vim.fn.getcompletion with 'lua' type
    local ok, results = pcall(vim.fn.getcompletion, expr, "lua")
    if ok and results and #results > 0 then
      return util.take(results, max_results)
    end

    -- Fallback: try to complete table fields manually
    local base, partial = expr:match("^(.+)%.([%w_]*)$")
    if not base then
      -- Complete globals
      partial = expr:match("^([%w_]*)$")
      if not partial then
        return {}
      end
      base = "_G"
    end

    -- Safely evaluate the base expression
    local eval_ok, tbl = pcall(function()
      return assert(load("return " .. base))()
    end)
    if not eval_ok or type(tbl) ~= "table" then
      return {}
    end

    local completions = {}
    local partial_lower = (partial or ""):lower()
    for key, _ in pairs(tbl) do
      if type(key) == "string" then
        if partial_lower == "" or key:lower():sub(1, #partial_lower) == partial_lower then
          if base == "_G" then
            table.insert(completions, key)
          else
            table.insert(completions, base .. "." .. key)
          end
        end
      end
    end

    table.sort(completions)
    return util.take(completions, max_results)
  end

  local function lua_complete_step(ctx, input)
    if not input or input == "" then
      return false
    end
    if ctx.cmdtype ~= ":" then
      return false
    end

    local expr = extract_lua_expr(input)
    if not expr then
      return false
    end

    local completions = complete_lua(expr)
    if #completions == 0 then
      return false
    end

    ctx.arg = expr
    -- Set query to just the partial after the last dot so highlighting
    -- matches the distinguishing suffix, not the common prefix.
    local last_dot = expr:find("%.[^.]*$")
    ctx.query = last_dot and expr:sub(last_dot + 1) or expr
    return completions
  end

  local pipeline = { lua_complete_step }

  if opts.fuzzy then
    table.insert(pipeline, require("wildest.filter").fuzzy_filter())
  end

  table.insert(pipeline, result.result())
  return pipeline
end

return M

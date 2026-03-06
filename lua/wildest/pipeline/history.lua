---@mod wildest.pipeline.history History Completion
---@brief [[
---Command and search history completion.
---@brief ]]

local M = {}

--- Create a command/search history pipeline step
--- Returns recent history entries matching the current input.
---
--- Example:
---   w.history_pipeline()                     -- auto-detect by cmdtype
---   w.history_pipeline({ max = 50 })         -- limit to 50 entries
---   w.history_pipeline({ cmdtype = ':' })    -- force command history
---   w.history_pipeline({ prefix = true })    -- prefix matching only
---
---@param opts? table { max?: integer, cmdtype?: string, prefix?: boolean }
---@return fun(ctx: table, input: string): table|false
function M.history(opts)
  opts = opts or {}
  local max = opts.max or 100
  local use_prefix = opts.prefix or false

  return function(ctx, input)
    local log = require("wildest.log")
    local histtype = opts.cmdtype or ctx.cmdtype or ":"

    local entries = {}
    local seen = {}
    local hist_nr = vim.fn.histnr(histtype)

    log.log("history", "query", { input = input, histtype = histtype, hist_nr = hist_nr })

    for i = hist_nr, math.max(1, hist_nr - max + 1), -1 do
      local entry = vim.fn.histget(histtype, i)
      if entry and entry ~= "" then
        entry = entry:gsub("\n", " ")
      end
      if entry and entry ~= "" and not seen[entry] then
        local matches = false
        if not input or input == "" then
          matches = true
        elseif use_prefix then
          matches = entry:lower():sub(1, #input) == input:lower()
        else
          matches = entry:lower():find(input:lower(), 1, true) ~= nil
        end
        if matches then
          seen[entry] = true
          table.insert(entries, entry)
          if #entries >= max then
            break
          end
        end
      end
    end

    log.log("history", "result", { input = input, count = #entries })

    if #entries == 0 then
      return false
    end
    return entries
  end
end

return M

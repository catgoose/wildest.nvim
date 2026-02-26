---@mod wildest.pipeline.history History Completion
---@brief [[
---Command and search history completion.
---@brief ]]

local util = require("wildest.util")

local M = {}

--- Create a command/search history pipeline step
--- Returns recent history entries matching the current input.
---
--- Example:
---   w.history_pipeline()                     -- auto-detect by cmdtype
---   w.history_pipeline({ max = 50 })         -- limit to 50 entries
---   w.history_pipeline({ cmdtype = ':' })    -- force command history
---
---@param opts? table { max?: integer, cmdtype?: string }
---@return fun(ctx: table, input: string): table|false
function M.history(opts)
  opts = opts or {}
  local max = opts.max or 100

  return function(ctx, input)
    local histtype = opts.cmdtype or ctx.cmdtype or ":"

    local entries = {}
    local seen = {}
    local hist_nr = vim.fn.histnr(histtype)

    for i = hist_nr, math.max(1, hist_nr - max + 1), -1 do
      local entry = vim.fn.histget(histtype, i)
      if entry and entry ~= "" then
        entry = entry:gsub("\n", " ")
      end
      if entry and entry ~= "" and not seen[entry] then
        if not input or input == "" or entry:lower():find(input:lower(), 1, true) then
          seen[entry] = true
          table.insert(entries, entry)
          if #entries >= max then
            break
          end
        end
      end
    end

    if #entries == 0 then
      return false
    end
    return entries
  end
end

return M

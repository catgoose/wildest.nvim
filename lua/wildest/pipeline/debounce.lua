---@mod wildest.pipeline.debounce Debounce Timing
---@brief [[
---Debounce timing pipeline step.
---@brief ]]

local pipeline_mod = require("wildest.pipeline")

local M = {}

-- Track all active debounce timers for cleanup
local active_timers = {}

--- Cancel all active debounce timers (called on CmdlineLeave)
---@return nil
function M.cancel_all()
  for timer in pairs(active_timers) do
    if not timer:is_closing() then
      timer:stop()
      timer:close()
    end
  end
  active_timers = {}
end

--- Create a debounce pipeline function
--- Delays pipeline execution by the given interval. If a new input
--- arrives before the timer fires, the previous timer is cancelled.
---@param interval integer delay in milliseconds
---@return function pipeline function
function M.debounce(interval)
  local timer = nil

  return function(ctx, x)
    return function(debounce_ctx)
      if timer then
        active_timers[timer] = nil
        if not timer:is_closing() then
          timer:stop()
          timer:close()
        end
      end

      timer = vim.uv.new_timer()
      active_timers[timer] = true
      timer:start(
        interval,
        0,
        vim.schedule_wrap(function()
          active_timers[timer] = nil
          if not timer:is_closing() then
            timer:close()
          end
          timer = nil
          pipeline_mod.resolve(debounce_ctx, x)
        end)
      )
    end
  end
end

return M

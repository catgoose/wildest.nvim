---@mod wildest.renderer.components.spinner Loading Spinner Component
---@brief [[
---Loading spinner component.
---@brief ]]

local BaseComponent = require("wildest.renderer.components.base")
local M = {}

local spinner_frames = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }

--- Create a spinner component
---@param opts? table { frames?: string[], hl?: string, interval?: integer, done?: string }
---@return table component
function M.new(opts)
  opts = opts or {}
  local frames = opts.frames or spinner_frames
  local hl = opts.hl or "WildestSpinner"
  local interval = opts.interval or 100
  local done_char = opts.done or " "

  local component = setmetatable({}, { __index = BaseComponent })
  local frame_idx = 1
  local timer = nil

  function component:start()
    if timer then
      return
    end
    frame_idx = 1
    timer = vim.uv.new_timer()
    timer:start(
      0,
      interval,
      vim.schedule_wrap(function()
        frame_idx = (frame_idx % #frames) + 1
      end)
    )
  end

  function component:stop()
    if timer then
      timer:stop()
      timer:close()
      timer = nil
    end
  end

  function component:render(ctx)
    if ctx.done then
      return { { done_char, hl } }
    end

    if not timer then
      self:start()
    end

    return { { frames[frame_idx], hl } }
  end

  return component
end

return M

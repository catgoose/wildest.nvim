---@mod wildest.renderer.components.empty_message_with_spinner Empty Message With Animated Spinner
---@brief [[
---Empty message with animated spinner.
---@brief ]]

local BaseComponent = require("wildest.renderer.components.base")
local M = {}

local spinner_frames = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }

--- Create a combined empty message + spinner component
--- Shows a spinner animation alongside a message when there are no results
---
---@param opts? table
---@return table component
function M.new(opts)
  opts = opts or {}
  local frames = opts.frames or spinner_frames
  local message = opts.message or " Searching... "
  local delay = opts.delay or 100
  local interval = opts.interval or 100
  local done_char = opts.done or " "
  local spinner_hl = opts.spinner_hl or "WildestSpinner"
  local message_hl = opts.hl or "WarningMsg"

  local component = setmetatable({}, { __index = BaseComponent })
  local frame_idx = 1
  local timer = nil
  local started_at = nil

  function component:start()
    if timer then
      return
    end
    frame_idx = 1
    started_at = vim.uv.now()
    timer = vim.uv.new_timer()
    timer:start(
      delay,
      interval,
      vim.schedule_wrap(function()
        frame_idx = (frame_idx % #frames) + 1
      end)
    )
  end

  function component:stop()
    if timer then
      if not timer:is_closing() then
        timer:stop()
        timer:close()
      end
      timer = nil
    end
    started_at = nil
  end

  function component:render(ctx)
    -- Only show when there are no results
    if ctx.total and ctx.total > 0 then
      self:stop()
      return {}
    end

    local spinner_char
    if ctx.done then
      self:stop()
      spinner_char = done_char
    else
      if not timer then
        self:start()
      end
      -- Don't show spinner during initial delay
      if started_at and (vim.uv.now() - started_at) < delay then
        spinner_char = " "
      else
        spinner_char = frames[frame_idx]
      end
    end

    local msg = message
    if type(message) == "function" then
      msg = message(ctx, spinner_char, spinner_hl)
      if type(msg) == "table" then
        -- Function returned chunks directly
        return msg
      end
    end

    return {
      { spinner_char, spinner_hl },
      { msg, message_hl },
    }
  end

  return component
end

return M

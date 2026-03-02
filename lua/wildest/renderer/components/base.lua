---@mod wildest.renderer.components.base Base Component Class
---@brief [[
---Base class for all wildest renderer components.
---Provides default render, render_left, and render_right methods.
---@brief ]]

---@class wildest.BaseComponent
local BaseComponent = {}
BaseComponent.__index = BaseComponent

--- Extract the candidate string for the current index from the render context.
---@param ctx table render context
---@return string candidate
function BaseComponent.get_candidate(ctx)
  if ctx.result and ctx.result.value and ctx.index ~= nil then
    return ctx.result.value[ctx.index + 1] or ""
  end
  return ""
end

---@param _ctx table render context
---@return table[] chunks
function BaseComponent:render(_ctx)
  return {}
end

---@param ctx table render context
---@return table[] chunks
function BaseComponent:render_left(ctx)
  return self:render(ctx)
end

---@param ctx table render context
---@return table[] chunks
function BaseComponent:render_right(ctx)
  return self:render(ctx)
end

return BaseComponent

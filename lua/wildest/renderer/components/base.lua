---@mod wildest.renderer.components.base Base Component Class
---@brief [[
---Base class for all wildest renderer components.
---Provides default render, render_left, and render_right methods.
---@brief ]]

---@class wildest.BaseComponent
local BaseComponent = {}
BaseComponent.__index = BaseComponent

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

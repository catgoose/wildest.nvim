---@mod wildest.renderer.mux Renderer Multiplexer
---@brief [[
---Renderer multiplexer — routes by cmdtype.
---@brief ]]

local log = require("wildest.log")

local M = {}

--- Create a renderer mux that routes by cmdtype
---@param routes table map from cmdtype to renderer
---@return table renderer object
function M.new(routes)
  local renderer = {}
  local active_renderer = nil

  function renderer:render(ctx, result)
    local cmdtype = ctx.cmdtype or ":"
    local target = routes[cmdtype]
    log.log("mux", "render", { cmdtype = cmdtype, has_target = (target ~= nil) })

    if active_renderer and active_renderer ~= target then
      pcall(active_renderer.hide, active_renderer)
    end
    active_renderer = target

    if target then
      log.log("mux", "render_delegate")
      target:render(ctx, result)
      log.log("mux", "render_delegate_done")
    else
      log.log("mux", "render_no_target")
    end
  end

  function renderer:hide()
    log.log("mux", "hide")
    if active_renderer then
      pcall(active_renderer.hide, active_renderer)
      active_renderer = nil
    end
    for _, r in pairs(routes) do
      pcall(r.hide, r)
    end
  end

  return renderer
end

return M

---@mod wildest.renderer.mux Renderer Multiplexer
---@brief [[
---Renderer multiplexer — routes by cmdtype or predicate list.
---
---Supports two routing formats:
---  Dict: `{ [":"] = renderer1, ["/"] = renderer2 }` — routes by cmdtype/route key
---  List: `{ {check_fn, renderer}, ... }` — first check_fn(ctx) returning true wins
---@brief ]]

local log = require("wildest.log")

local M = {}

--- Create a renderer mux that routes by cmdtype or predicate list
---@param routes table dict or list of {check_fn, renderer} pairs
---@return table renderer object
function M.new(routes)
  local renderer = {}
  local active_renderer = nil
  local is_list = vim.islist(routes)

  --- Resolve target renderer from routes
  local function resolve_target(ctx)
    if is_list then
      for _, entry in ipairs(routes) do
        if entry[1](ctx) then
          return entry[2]
        end
      end
      return nil
    end
    local route_key = ctx.route or ctx.cmdtype or ":"
    return routes[route_key] or routes[ctx.cmdtype or ":"]
  end

  function renderer:render(ctx, result)
    local target = resolve_target(ctx)
    log.log("mux", "render", { has_target = (target ~= nil) })

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
    -- Hide all unique renderers
    local seen = {}
    if is_list then
      for _, entry in ipairs(routes) do
        local r = entry[2]
        if not seen[r] then
          seen[r] = true
          pcall(r.hide, r)
        end
      end
    else
      for _, r in pairs(routes) do
        if not seen[r] then
          seen[r] = true
          pcall(r.hide, r)
        end
      end
    end
  end

  return renderer
end

return M

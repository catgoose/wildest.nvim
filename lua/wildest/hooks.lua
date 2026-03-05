--- Event hook registry for wildest.nvim.
--- Supports multiple listeners per event via wildest.on() / wildest.off().

local M = {}

---@type table<string, fun(...)[]>
local listeners = {}

--- Valid event names.
local valid_events = {
  enter = true,
  leave = true,
  draw = true,
  results = true,
  error = true,
  select = true,
  accept = true,
}

--- Register a listener for an event.
---@param event string Event name
---@param fn fun(...) Callback
function M.on(event, fn)
  if not valid_events[event] then
    vim.notify(
      string.format("[wildest] Unknown hook event: %s", event),
      vim.log.levels.WARN
    )
    return
  end
  if not listeners[event] then
    listeners[event] = {}
  end
  table.insert(listeners[event], fn)
end

--- Remove a listener for an event.
---@param event string Event name
---@param fn fun(...) The same function reference passed to on()
function M.off(event, fn)
  local list = listeners[event]
  if not list then
    return
  end
  for i = #list, 1, -1 do
    if list[i] == fn then
      table.remove(list, i)
      break
    end
  end
end

--- Fire all listeners for an event.
---@param event string Event name
---@param ... any Arguments passed to listeners
function M.fire(event, ...)
  local list = listeners[event]
  if not list then
    return
  end
  for _, fn in ipairs(list) do
    local ok, err = pcall(fn, ...)
    if not ok then
      vim.notify(
        string.format("[wildest] Hook %s error: %s", event, tostring(err)),
        vim.log.levels.WARN
      )
    end
  end
end

--- Remove all listeners (used in tests or teardown).
function M.clear()
  listeners = {}
end

return M

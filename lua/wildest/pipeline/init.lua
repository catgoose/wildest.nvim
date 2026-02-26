---@mod wildest.pipeline Pipeline Engine
---@brief [[
---Async-aware pipeline execution engine.
---
---Each pipeline step is a function `(ctx, input) -> result` where result can be:
---- A value: passed to the next step
---- A function: async step, receives `(resolve, reject)` via context
---- `false`: pipeline failed (branch combinator tries next)
---- `true`: pipeline says "hide" (no results to show)
---@brief ]]

---@alias wildest.PipelineStep fun(ctx: wildest.PipelineContext, input: any): any
---@alias wildest.Pipeline wildest.PipelineStep[]

---@class wildest.PipelineContext
---@field run_id integer Monotonic pipeline run counter
---@field session_id integer Session counter
---@field input string Current cmdline input
---@field cmdtype string Current cmdtype (':', '/', '?')
---@field mode string Alias for cmdtype
---@field handler_id? integer Async handler ID (set by pipeline engine)
---@field arg? string Extracted argument portion of input

---@class wildest.PipelineResult
---@field value any[] Completion candidates
---@field data? table Metadata (input, arg, etc.)
---@field output? fun(data: table, candidate: any): string Output transform

local log = require("wildest.log")

local M = {}

local handler_id = 0
local handlers = {}

--- Generate a unique handler ID
---@return integer
local function next_id()
  handler_id = handler_id + 1
  return handler_id
end

--- Register a handler for async pipeline resolution
---@param on_finish fun(ctx: table, x: any)
---@param on_error fun(ctx: table, err: any)
---@return integer handler_id
function M.register_handler(on_finish, on_error)
  local id = next_id()
  handlers[id] = { on_finish = on_finish, on_error = on_error }
  log.log("pipeline", "register_handler", { id = id })
  return id
end

--- Remove a handler
---@param id integer
function M.remove_handler(id)
  handlers[id] = nil
end

--- Clear all handlers (called on CmdlineLeave)
function M.clear_handlers()
  handlers = {}
end

--- Resolve an async pipeline step
---@param ctx table pipeline context
---@param x any result value
function M.resolve(ctx, x)
  local id = ctx.handler_id
  log.log(
    "pipeline",
    "resolve",
    { handler_id = id, has_handler = (id ~= nil and handlers[id] ~= nil) }
  )
  if not id or not handlers[id] then
    return
  end
  local handler = handlers[id]
  handlers[id] = nil
  log.log("pipeline", "resolve_dispatch", { handler_id = id })
  handler.on_finish(ctx, x)
end

--- Reject an async pipeline step
---@param ctx table pipeline context
---@param err any error value
function M.reject(ctx, err)
  local id = ctx.handler_id
  log.log("pipeline", "reject", { handler_id = id, err = tostring(err) })
  if not id or not handlers[id] then
    return
  end
  local handler = handlers[id]
  handlers[id] = nil
  log.log("pipeline", "reject_dispatch", { handler_id = id })
  handler.on_error(ctx, err)
end

--- Run a pipeline (array of functions) with initial input
---@param pipeline table|function array of pipeline functions, or single function
---@param on_finish fun(ctx: table, x: any)
---@param on_error fun(ctx: table, err: any)
---@param ctx table context with run_id, session_id, input, etc.
---@param x any initial input
function M.run(pipeline, on_finish, on_error, ctx, x)
  if type(pipeline) == "function" then
    pipeline = { pipeline }
  end

  log.log("pipeline", "run", { steps = #pipeline, input_type = type(x) })

  local function run_step(i, value)
    if i > #pipeline then
      log.log("pipeline", "run_finished", { step = i })
      on_finish(ctx, value)
      return
    end

    log.log("pipeline", "run_step", { step = i, value_type = type(value) })
    local step_fn = pipeline[i]
    local ok_call, result = pcall(step_fn, ctx, value)

    if not ok_call then
      log.log("pipeline", "run_step_error", { step = i, err = tostring(result) })
      on_error(ctx, result)
      return
    end

    log.log("pipeline", "run_step_result", {
      step = i,
      result_type = type(result),
      is_false = (result == false),
      is_true = (result == true),
    })

    if result == false then
      on_error(ctx, false)
      return
    end

    if result == true then
      on_finish(ctx, true)
      return
    end

    if type(result) == "function" then
      log.log("pipeline", "run_step_async", { step = i })
      local id = M.register_handler(function(rctx, rval)
        run_step(i + 1, rval)
      end, on_error)
      ctx.handler_id = id
      local async_ok, async_err = pcall(result, ctx)
      if not async_ok then
        M.remove_handler(id)
        log.log("pipeline", "run_step_async_error", { step = i, err = tostring(async_err) })
        on_error(ctx, async_err)
      end
      return
    end

    run_step(i + 1, result)
  end

  run_step(1, x)
end

return M

---@mod wildest.state Session State
---@brief [[
---Single source of truth for the current completion session state.
---Manages the lifecycle of CmdlineEnter -> CmdlineChanged -> CmdlineLeave,
---selection stepping, pipeline execution, and renderer drawing.
---@brief ]]

local config = require("wildest.config")
local debounce_mod = require("wildest.pipeline.debounce")
local file_finder = require("wildest.file_finder")
local log = require("wildest.log")
local pipeline_mod = require("wildest.pipeline")

local M = {}

---@class wildest.State
---@field enabled boolean Whether wildest is globally enabled
---@field active boolean Whether a completion session is active
---@field hidden boolean Whether the renderer is hidden
---@field session_id integer Monotonic session counter
---@field run_id integer Monotonic pipeline run counter
---@field selected integer Selected candidate index (-1 = no selection)
---@field result? wildest.PipelineResult Current pipeline result
---@field error? any Current pipeline error
---@field previous_cmdline string Last seen cmdline text
---@field replaced_cmdline? string Cmdline text set by completion
---@field completion_stack table Stack for nested completions
---@field cmdtype string Current cmdtype (':', '/', '?')
---@field draw_done boolean Whether current frame has been drawn
---@field suppress_change boolean Suppress next CmdlineChanged from our setcmdline
---@field triggered boolean For trigger='tab': has Tab been pressed?
---@field pipeline_timer? uv_timer_t Timeout timer for pipeline

--- State table — single source of truth
local state = {
  enabled = false,
  active = false,
  hidden = false,
  session_id = 0,
  run_id = 0,
  selected = -1,
  result = nil,
  error = nil,
  previous_cmdline = "",
  replaced_cmdline = nil,
  completion_stack = {},
  cmdtype = "",
  draw_done = false,
  suppress_change = false,
  triggered = false,
  pipeline_timer = nil,
}

--- Zero out session-scoped fields shared between start() and stop()
local function reset_session_fields()
  state.hidden = false
  state.selected = -1
  state.result = nil
  state.error = nil
  state.previous_cmdline = ""
  state.replaced_cmdline = nil
  state.completion_stack = {}
  state.draw_done = false
end

--- Get the current state table (read-only — do not mutate)
---@return wildest.State
function M.get()
  return state
end

--- Check if wildest is currently active
---@return boolean
function M.is_active()
  return state.enabled and state.active
end

--- Start a new session (called on CmdlineEnter)
---@param cmdtype string the command type (':', '/', '?')
function M.start(cmdtype)
  local cfg = config.get()
  log.log("state", "start", { cmdtype = cmdtype, enabled = state.enabled })

  local mode_enabled = false
  for _, m in ipairs(cfg.modes) do
    if m == cmdtype then
      mode_enabled = true
      break
    end
  end
  if not mode_enabled then
    log.log("state", "start_mode_disabled", { cmdtype = cmdtype })
    return
  end

  state.active = true
  state.session_id = state.session_id + 1
  state.run_id = state.run_id + 1
  state.cmdtype = cmdtype
  reset_session_fields()

  -- Suppress native wildmenu/pum so it doesn't appear behind wildest
  state._saved_wildmenu = vim.o.wildmenu
  state._saved_wildoptions = vim.o.wildoptions
  vim.o.wildmenu = false
  vim.o.wildoptions = ""
  state.triggered = (cfg.trigger ~= "tab")
  log.log("state", "start_done", { session_id = state.session_id, triggered = state.triggered })

  if state.triggered and cfg.min_input == 0 then
    M.run_pipeline("")
  end
end

--- Stop the current session (called on CmdlineLeave)
function M.stop()
  log.log("state", "stop", { active = state.active })
  if not state.active then
    return
  end

  state.active = false
  reset_session_fields()
  state.triggered = false

  -- Restore native wildmenu options
  if state._saved_wildmenu ~= nil then
    vim.o.wildmenu = state._saved_wildmenu
    vim.o.wildoptions = state._saved_wildoptions
    state._saved_wildmenu = nil
    state._saved_wildoptions = nil
  end

  if state.pipeline_timer then
    if not state.pipeline_timer:is_closing() then
      state.pipeline_timer:stop()
      state.pipeline_timer:close()
    end
    state.pipeline_timer = nil
  end

  pipeline_mod.clear_handlers()
  debounce_mod.cancel_all()
  file_finder.cancel()

  local cfg = config.get()
  if cfg.renderer then
    vim.schedule(function()
      log.log("state", "stop_hide_renderer")
      pcall(cfg.renderer.hide, cfg.renderer)
    end)
  end
end

--- Called when cmdline input changes
---@param cmdline string current cmdline content
function M.on_change(cmdline)
  log.log("state", "on_change", { cmdline = cmdline, active = state.active })
  if not state.active then
    return
  end

  if state.suppress_change then
    log.log("state", "on_change_suppressed")
    state.suppress_change = false
    return
  end

  if cmdline == state.previous_cmdline then
    log.log("state", "on_change_same")
    return
  end

  state.previous_cmdline = cmdline
  state.selected = -1
  state.replaced_cmdline = nil
  state.completion_stack = {}
  state.draw_done = false

  if not state.triggered then
    log.log("state", "on_change_not_triggered")
    return
  end

  local cfg = config.get()
  if #cmdline < cfg.min_input then
    log.log("state", "on_change_below_min_input", { len = #cmdline, min_input = cfg.min_input })
    state.hidden = true
    state.result = nil
    M.draw()
    return
  end

  M.run_pipeline(cmdline)
end

--- Trigger completions (for trigger='tab' mode)
function M.trigger()
  state.triggered = true
  if state.previous_cmdline ~= "" then
    M.run_pipeline(state.previous_cmdline)
  end
end

--- Check if a command should be skipped
---@param input string
---@return boolean
local function should_skip(input)
  local cfg = config.get()
  if not cfg.skip_commands or #cfg.skip_commands == 0 then
    return false
  end
  local cmd = input:match("^%s*(%S+)")
  if not cmd then
    return false
  end
  cmd = cmd:gsub("!$", "")
  for _, skip in ipairs(cfg.skip_commands) do
    if cmd == skip then
      return true
    end
  end
  return false
end

--- Run the pipeline with current input
---@param input string
function M.run_pipeline(input)
  log.log("state", "run_pipeline", { input = input })

  if should_skip(input) then
    log.log("state", "run_pipeline_skipped")
    state.result = nil
    state.hidden = true
    M.draw()
    return
  end

  if state.cmdtype == ":" and vim.o.inccommand ~= "" then
    local is_sub = input:match("^[%%%d%.,';/$?]*%s*s[^a-z]")
      or input:match("^[%%%d%.,';/$?]*%s*su[bp]")
    if is_sub then
      log.log("state", "run_pipeline_inccommand_skip")
      state.result = nil
      state.hidden = true
      M.draw()
      return
    end
  end

  state.run_id = state.run_id + 1
  local run_id = state.run_id
  local session_id = state.session_id

  local cfg = config.get()
  if not cfg.pipeline then
    log.log("state", "run_pipeline_no_pipeline")
    return
  end

  local ctx = {
    run_id = run_id,
    session_id = session_id,
    input = input,
    cmdtype = state.cmdtype,
    mode = state.cmdtype,
  }

  local pipeline = cfg.pipeline
  if type(pipeline) == "function" then
    pipeline = { pipeline }
  end

  if state.pipeline_timer then
    if not state.pipeline_timer:is_closing() then
      state.pipeline_timer:stop()
      state.pipeline_timer:close()
    end
    state.pipeline_timer = nil
  end

  if cfg.pipeline_timeout and cfg.pipeline_timeout > 0 then
    state.pipeline_timer = vim.uv.new_timer()
    state.pipeline_timer:start(
      cfg.pipeline_timeout,
      0,
      vim.schedule_wrap(function()
        if state.pipeline_timer and not state.pipeline_timer:is_closing() then
          state.pipeline_timer:close()
          state.pipeline_timer = nil
        end
        if run_id == state.run_id then
          pipeline_mod.clear_handlers()
        end
      end)
    )
  end

  log.log(
    "state",
    "run_pipeline_exec",
    { run_id = run_id, pipeline_type = type(pipeline), pipeline_len = #pipeline }
  )
  pipeline_mod.run(pipeline, function(_ctx, result)
    log.log("state", "pipeline_on_finish_cb", { run_id = run_id })
    M.on_finish(ctx, result)
  end, function(_ctx, err)
    log.log("state", "pipeline_on_error_cb", { run_id = run_id, err = tostring(err) })
    M.on_error(ctx, err)
  end, ctx, input)
  log.log("state", "run_pipeline_returned")
end

--- Called when pipeline finishes successfully
---@param ctx table
---@param result any
function M.on_finish(ctx, result)
  local result_type = type(result)
  local result_len = (result_type == "table" and result.value) and #result.value
    or (result_type == "table" and #result)
    or 0
  log.log("state", "on_finish", {
    result_type = result_type,
    result_len = result_len,
    active = state.active,
    run_id = ctx.run_id,
    state_run_id = state.run_id,
  })

  if ctx.run_id ~= state.run_id then
    log.log("state", "on_finish_stale_run")
    return
  end
  if ctx.session_id ~= state.session_id then
    log.log("state", "on_finish_stale_session")
    return
  end
  if not state.active then
    log.log("state", "on_finish_not_active")
    return
  end

  if result == true then
    state.hidden = true
    state.result = nil
    M.draw()
    return
  end

  state.hidden = false

  if type(result) == "table" and result.value then
    state.result = result
  else
    local candidates = result
    if type(result) ~= "table" then
      candidates = {}
    end
    state.result = { value = candidates, data = { input = ctx.input } }
  end

  state.error = nil

  local cfg = config.get()
  if not cfg.noselect and state.result and #state.result.value > 0 then
    state.selected = 0
  end

  log.log("state", "on_finish_draw", { num_candidates = state.result and #state.result.value or 0 })
  M.draw()
end

--- Called when pipeline errors
---@param ctx table
---@param err any
function M.on_error(ctx, err)
  log.log("state", "on_error", { err = tostring(err) })
  if ctx.run_id ~= state.run_id then
    return
  end
  if ctx.session_id ~= state.session_id then
    return
  end
  if not state.active then
    return
  end

  state.result = nil
  state.error = err
  state.hidden = false
  M.draw()
end

--- Draw the current state using the configured renderer
function M.draw()
  if not state.active then
    log.log("state", "draw_not_active")
    return
  end

  local run_id = state.run_id
  local session_id = state.session_id
  log.log("state", "draw_schedule", { run_id = run_id })

  vim.schedule(function()
    log.log("state", "draw_callback_fired", { run_id = run_id, state_run_id = state.run_id })

    if run_id ~= state.run_id then
      log.log("state", "draw_stale_run")
      return
    end
    if session_id ~= state.session_id then
      log.log("state", "draw_stale_session")
      return
    end
    if not state.active then
      log.log("state", "draw_not_active_in_timer")
      return
    end

    local cfg = config.get()
    if not cfg.renderer then
      log.log("state", "draw_no_renderer")
      return
    end

    local ctx = {
      selected = state.selected,
      run_id = state.run_id,
      session_id = state.session_id,
      cmdtype = state.cmdtype,
      done = true,
      input = state.previous_cmdline,
    }

    if state.hidden then
      log.log("state", "draw_hidden")
      pcall(cfg.renderer.hide, cfg.renderer)
      return
    end

    local result = state.result or { value = {}, data = {} }

    if #result.value == 0 then
      log.log("state", "draw_empty")
      pcall(cfg.renderer.hide, cfg.renderer)
      return
    end

    log.log("state", "draw_render_start", { num = #result.value })
    local ok, err = pcall(cfg.renderer.render, cfg.renderer, ctx, result)
    if not ok then
      log.log("state", "draw_render_error", { err = tostring(err) })
    else
      log.log("state", "draw_render_ok")
      vim.cmd("redraw")
    end
  end)
end

--- Compute the longest common prefix of candidates
---@param candidates string[]
---@return string
local function longest_common_prefix(candidates)
  if #candidates == 0 then
    return ""
  end
  if #candidates == 1 then
    return candidates[1]
  end

  local prefix = candidates[1]
  for i = 2, #candidates do
    local c = candidates[i]
    local j = 0
    while j < #prefix and j < #c do
      if prefix:sub(j + 1, j + 1):lower() ~= c:sub(j + 1, j + 1):lower() then
        break
      end
      j = j + 1
    end
    prefix = prefix:sub(1, j)
    if prefix == "" then
      break
    end
  end
  return prefix
end

--- Step selection by n positions (positive = next, negative = previous)
---@param n integer
function M.step(n)
  if not state.active then
    return
  end

  if not state.triggered then
    M.trigger()
    return
  end

  if not state.result or #state.result.value == 0 then
    return
  end

  local cfg = config.get()
  local count = #state.result.value

  if cfg.longest_prefix and state.selected == -1 and n > 0 then
    local candidates = state.result.value
    local lcp = longest_common_prefix(candidates)
    if lcp ~= "" and #lcp > #(state.result.data and state.result.data.arg or "") then
      if state.result.output then
        local full = state.result.output(state.result.data, lcp)
        if type(full) == "string" and full ~= state.previous_cmdline then
          M.feedkeys_cmdline(full)
          state.replaced_cmdline = full
          M.draw()
          return
        end
      end
    end
  end

  if state.selected == -1 then
    if n > 0 then
      state.selected = 0
    else
      state.selected = count - 1
    end
  else
    state.selected = state.selected + n
    if state.selected < -1 then
      state.selected = count - 1
    elseif state.selected >= count then
      state.selected = -1
    end
  end

  if state.selected == -1 then
    M.feedkeys_cmdline(state.previous_cmdline)
    state.replaced_cmdline = nil
  else
    local candidate = state.result.value[state.selected + 1]
    if state.result.output then
      candidate = state.result.output(state.result.data, candidate)
    end
    if type(candidate) == "string" and candidate ~= "" then
      state.replaced_cmdline = candidate
      M.feedkeys_cmdline(candidate)
    end
  end

  M.draw()
end

--- Scroll selection by n positions, clamping at boundaries
---@param n integer positive = down, negative = up
function M.scroll(n)
  if not state.active then
    return
  end

  if not state.triggered then
    M.trigger()
    return
  end

  if not state.result or #state.result.value == 0 then
    return
  end

  local count = #state.result.value

  if state.selected == -1 then
    if n > 0 then
      state.selected = 0
    else
      state.selected = count - 1
    end
  else
    state.selected = state.selected + n
    if state.selected < 0 then
      state.selected = 0
    elseif state.selected >= count then
      state.selected = count - 1
    end
  end

  local candidate = state.result.value[state.selected + 1]
  if state.result.output then
    candidate = state.result.output(state.result.data, candidate)
  end
  if type(candidate) == "string" and candidate ~= "" then
    state.replaced_cmdline = candidate
    M.feedkeys_cmdline(candidate)
  end

  M.draw()
end

--- Replace the current cmdline with the given text
---@param text string
function M.feedkeys_cmdline(text)
  state.suppress_change = true
  vim.fn.setcmdline(text)
end

--- Accept current completion
function M.accept_completion()
  if not state.active then
    return
  end
  if state.selected == -1 then
    return
  end

  state.previous_cmdline = vim.fn.getcmdline()
  state.replaced_cmdline = nil
  state.selected = -1
  state.completion_stack = {}

  M.run_pipeline(state.previous_cmdline)
end

--- Reject current completion (restore original)
function M.reject_completion()
  if not state.active then
    return
  end

  if state.replaced_cmdline then
    M.feedkeys_cmdline(state.previous_cmdline)
    state.replaced_cmdline = nil
  end
  state.selected = -1

  M.draw()
end

--- Close the popup but stay in cmdline mode
function M.close()
  if not state.active then
    return
  end

  if state.replaced_cmdline then
    M.feedkeys_cmdline(state.previous_cmdline)
    state.replaced_cmdline = nil
  end
  state.selected = -1
  state.hidden = true
  state.result = nil

  M.draw()
end

--- Dismiss popup and restore original input (like close but also untriggers for tab mode)
function M.dismiss()
  if not state.active then
    return
  end

  if state.replaced_cmdline then
    M.feedkeys_cmdline(state.previous_cmdline)
    state.replaced_cmdline = nil
  end
  state.selected = -1
  state.hidden = true
  state.result = nil

  local cfg = config.get()
  if cfg.trigger == "tab" then
    state.triggered = false
  end

  M.draw()
end

--- Accept selection and execute the command
function M.confirm()
  if not state.active then
    return false
  end
  if state.selected == -1 then
    return false
  end

  -- The cmdline already has the selected candidate from step/scroll,
  -- just feed <CR> to execute
  local raw = vim.api.nvim_replace_termcodes("<CR>", true, false, true)
  vim.api.nvim_feedkeys(raw, "in", false)
  return true
end

--- Enable wildest
function M.enable()
  state.enabled = true
end

--- Disable wildest
function M.disable()
  state.enabled = false
  if state.active then
    M.stop()
  end
end

--- Toggle wildest
function M.toggle()
  if state.enabled then
    M.disable()
  else
    M.enable()
  end
end

return M

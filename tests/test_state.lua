local MiniTest = require("mini.test")
local new_set = MiniTest.new_set
local expect = MiniTest.expect

local T = new_set()

local function setup_state(candidates)
  local state_mod = require("wildest.state")
  local config = require("wildest.config")
  config.setup({ modes = { ":" }, pipeline = { function() end }, noselect = true })

  local s = state_mod.get()
  s.enabled = true
  s.active = true
  s.triggered = true
  s.cmdtype = ":"
  s.result = { value = candidates or {}, data = { input = "", arg = "" } }
  s.selected = -1
  s.marked = {}
  s.previous_cmdline = ""
  s.replaced_cmdline = nil
  return state_mod
end

local function teardown_state()
  local s = require("wildest.state").get()
  s.active = false
  s.enabled = false
  s.result = nil
  s.marked = {}
  s.selected = -1
  s.replaced_cmdline = nil
  s.previous_cmdline = ""
  s.triggered = false
end

-- ── step ─────────────────────────────────────────────────────────

T["step"] = new_set({ hooks = { post_case = teardown_state } })

T["step"]["selects first candidate when stepping forward from no selection"] = function()
  local state = setup_state({ "alpha", "beta", "gamma" })
  state.step(1)
  expect.equality(state.get().selected, 0)
end

T["step"]["selects last candidate when stepping backward from no selection"] = function()
  local state = setup_state({ "alpha", "beta", "gamma" })
  state.step(-1)
  expect.equality(state.get().selected, 2)
end

T["step"]["wraps forward past last to no selection"] = function()
  local state = setup_state({ "alpha", "beta" })
  state.step(1) -- 0
  state.step(1) -- 1
  state.step(1) -- -1 (wrap)
  expect.equality(state.get().selected, -1)
end

T["step"]["wraps backward past no selection to last"] = function()
  local state = setup_state({ "alpha", "beta" })
  state.step(1) -- 0
  state.step(-1) -- -1
  state.step(-1) -- 1 (wrap)
  expect.equality(state.get().selected, 1)
end

T["step"]["no-ops when not active"] = function()
  local state = setup_state({ "alpha" })
  state.get().active = false
  state.step(1)
  expect.equality(state.get().selected, -1)
end

T["step"]["no-ops with empty results"] = function()
  local state = setup_state({})
  state.step(1)
  expect.equality(state.get().selected, -1)
end

T["step"]["no-ops with nil result"] = function()
  local state = setup_state({ "alpha" })
  state.get().result = nil
  state.step(1)
  expect.equality(state.get().selected, -1)
end

T["step"]["cycles through all candidates"] = function()
  local state = setup_state({ "a", "b", "c" })
  local visited = {}
  for _ = 1, 3 do
    state.step(1)
    visited[#visited + 1] = state.get().selected
  end
  expect.equality(visited, { 0, 1, 2 })
end

-- ── scroll ───────────────────────────────────────────────────────

T["scroll"] = new_set({ hooks = { post_case = teardown_state } })

T["scroll"]["selects first when scrolling forward from no selection"] = function()
  local state = setup_state({ "alpha", "beta", "gamma" })
  state.scroll(1)
  expect.equality(state.get().selected, 0)
end

T["scroll"]["selects last when scrolling backward from no selection"] = function()
  local state = setup_state({ "alpha", "beta", "gamma" })
  state.scroll(-1)
  expect.equality(state.get().selected, 2)
end

T["scroll"]["clamps at end instead of wrapping"] = function()
  local state = setup_state({ "alpha", "beta" })
  state.scroll(1) -- 0
  state.scroll(1) -- 1
  state.scroll(1) -- 1 (clamped)
  expect.equality(state.get().selected, 1)
end

T["scroll"]["clamps at start instead of wrapping"] = function()
  local state = setup_state({ "alpha", "beta" })
  state.scroll(1) -- 0
  state.scroll(-1) -- 0 (clamped)
  state.scroll(-1) -- 0 (clamped)
  expect.equality(state.get().selected, 0)
end

T["scroll"]["jumps multiple positions"] = function()
  local state = setup_state({ "a", "b", "c", "d", "e" })
  state.scroll(3) -- 0 -> jump from -1, lands on 0 (first scroll from -1 always picks 0 or last)
  -- After first scroll from -1, selected = 0
  -- Now scroll by 3
  state.scroll(3) -- 0 + 3 = 3
  expect.equality(state.get().selected, 3)
end

T["scroll"]["clamps large forward jump"] = function()
  local state = setup_state({ "a", "b", "c" })
  state.scroll(1) -- 0
  state.scroll(100)
  expect.equality(state.get().selected, 2)
end

T["scroll"]["clamps large backward jump"] = function()
  local state = setup_state({ "a", "b", "c" })
  state.scroll(1) -- 0
  state.scroll(-100)
  expect.equality(state.get().selected, 0)
end

T["scroll"]["no-ops when not active"] = function()
  local state = setup_state({ "alpha" })
  state.get().active = false
  state.scroll(1)
  expect.equality(state.get().selected, -1)
end

T["scroll"]["no-ops with empty results"] = function()
  local state = setup_state({})
  state.scroll(1)
  expect.equality(state.get().selected, -1)
end

-- ── mark ─────────────────────────────────────────────────────────

T["mark"] = new_set({ hooks = { post_case = teardown_state } })

T["mark"]["marks first candidate when none selected"] = function()
  local state = setup_state({ "alpha", "beta" })
  state.mark(1)
  local s = state.get()
  expect.equality(s.marked[0], true)
end

T["mark"]["advances after marking"] = function()
  local state = setup_state({ "alpha", "beta", "gamma" })
  state.mark(1) -- selects 0, marks 0, advances to 1
  expect.equality(state.get().selected, 1)
end

T["mark"]["stays at end when advancing past last"] = function()
  local state = setup_state({ "alpha", "beta" })
  state.mark(1) -- selects 0, marks, advances to 1
  state.mark(1) -- marks 1, can't advance past end
  expect.equality(state.get().selected, 1)
  expect.equality(state.get().marked[0], true)
  expect.equality(state.get().marked[1], true)
end

T["mark"]["toggles mark on double-mark"] = function()
  local state = setup_state({ "alpha", "beta" })
  state.step(1) -- select 0
  state.mark(0) -- mark 0, no advance (n=0 won't move)
  expect.equality(state.get().marked[0], true)
  state.mark(0) -- toggle off
  expect.equality(state.get().marked[0], nil)
end

T["mark"]["no-ops when not active"] = function()
  local state = setup_state({ "alpha" })
  state.get().active = false
  state.mark(1)
  expect.equality(state.get().selected, -1)
end

T["mark"]["no-ops with empty results"] = function()
  local state = setup_state({})
  state.mark(1)
  expect.equality(#state.get_marked(), 0)
end

-- ── unmark ───────────────────────────────────────────────────────

T["unmark"] = new_set({ hooks = { post_case = teardown_state } })

T["unmark"]["unmarks current candidate"] = function()
  local state = setup_state({ "alpha", "beta" })
  state.mark(1) -- mark 0, advance to 1
  state.get().selected = 0
  state.unmark(1)
  expect.equality(state.get().marked[0], nil)
end

T["unmark"]["advances after unmarking"] = function()
  local state = setup_state({ "alpha", "beta", "gamma" })
  state.mark(1) -- mark 0, advance to 1
  state.get().selected = 0
  state.unmark(1) -- unmark 0, advance to 1
  expect.equality(state.get().selected, 1)
end

T["unmark"]["no-ops when nothing selected"] = function()
  local state = setup_state({ "alpha" })
  state.unmark(1)
  expect.equality(state.get().selected, -1)
end

T["unmark"]["no-ops when not active"] = function()
  local state = setup_state({ "alpha" })
  state.get().active = false
  state.unmark(1)
  expect.equality(state.get().selected, -1)
end

-- ── get_marked / clear_marks ─────────────────────────────────────

T["get_marked"] = new_set({ hooks = { post_case = teardown_state } })

T["get_marked"]["returns empty when nothing marked"] = function()
  setup_state({ "alpha", "beta" })
  local state = require("wildest.state")
  expect.equality(state.get_marked(), {})
end

T["get_marked"]["returns sorted indices"] = function()
  local state = setup_state({ "a", "b", "c", "d" })
  local s = state.get()
  s.marked[2] = true
  s.marked[0] = true
  s.marked[3] = true
  local indices = state.get_marked()
  expect.equality(indices, { 0, 2, 3 })
end

T["clear_marks"] = new_set({ hooks = { post_case = teardown_state } })

T["clear_marks"]["clears all marks"] = function()
  local state = setup_state({ "a", "b", "c" })
  state.mark(1) -- mark 0
  state.mark(1) -- mark 1
  state.clear_marks()
  expect.equality(state.get_marked(), {})
end

-- ── accept_completion ────────────────────────────────────────────

T["accept_completion"] = new_set({ hooks = { post_case = teardown_state } })

T["accept_completion"]["resets selection to -1"] = function()
  local state = setup_state({ "alpha", "beta" })
  state.step(1)
  expect.equality(state.get().selected, 0)
  state.accept_completion()
  expect.equality(state.get().selected, -1)
end

T["accept_completion"]["clears replaced_cmdline"] = function()
  local state = setup_state({ "alpha", "beta" })
  state.step(1)
  state.accept_completion()
  expect.equality(state.get().replaced_cmdline, nil)
end

T["accept_completion"]["no-ops when nothing selected"] = function()
  local state = setup_state({ "alpha" })
  state.accept_completion()
  expect.equality(state.get().selected, -1)
end

T["accept_completion"]["no-ops when not active"] = function()
  local state = setup_state({ "alpha" })
  state.step(1)
  state.get().active = false
  state.accept_completion()
  -- selected stays as-is since the function returned early
  expect.equality(state.get().selected, 0)
end

-- ── reject_completion ────────────────────────────────────────────

T["reject_completion"] = new_set({ hooks = { post_case = teardown_state } })

T["reject_completion"]["resets selection to -1"] = function()
  local state = setup_state({ "alpha", "beta" })
  state.step(1)
  state.reject_completion()
  expect.equality(state.get().selected, -1)
end

T["reject_completion"]["clears replaced_cmdline"] = function()
  local state = setup_state({ "alpha" })
  state.step(1)
  state.reject_completion()
  expect.equality(state.get().replaced_cmdline, nil)
end

T["reject_completion"]["no-ops when not active"] = function()
  local state = setup_state({ "alpha" })
  state.step(1)
  state.get().active = false
  state.reject_completion()
  expect.equality(state.get().selected, 0)
end

-- ── enable / disable / toggle ────────────────────────────────────

T["toggle"] = new_set({ hooks = { post_case = teardown_state } })

T["toggle"]["enables when disabled"] = function()
  local state = require("wildest.state")
  local config = require("wildest.config")
  config.setup({ modes = { ":" }, pipeline = { function() end } })
  state.get().enabled = false
  state.toggle()
  expect.equality(state.get().enabled, true)
end

T["toggle"]["disables when enabled"] = function()
  local state = require("wildest.state")
  local config = require("wildest.config")
  config.setup({ modes = { ":" }, pipeline = { function() end } })
  state.get().enabled = true
  state.toggle()
  expect.equality(state.get().enabled, false)
end

-- ── single candidate ─────────────────────────────────────────────

T["single candidate"] = new_set({ hooks = { post_case = teardown_state } })

T["single candidate"]["step forward selects it"] = function()
  local state = setup_state({ "only" })
  state.step(1)
  expect.equality(state.get().selected, 0)
end

T["single candidate"]["step forward again wraps to -1"] = function()
  local state = setup_state({ "only" })
  state.step(1)
  state.step(1)
  expect.equality(state.get().selected, -1)
end

T["single candidate"]["scroll clamps to it"] = function()
  local state = setup_state({ "only" })
  state.scroll(1)
  state.scroll(1)
  expect.equality(state.get().selected, 0)
end

-- ── dynamic config (function values) ────────────────────────────

T["dynamic config"] = new_set({ hooks = { post_case = teardown_state } })

T["dynamic config"]["noselect as function selects first when false"] = function()
  local config = require("wildest.config")
  config.setup({
    modes = { ":" },
    pipeline = { function() end },
    noselect = function(cmdtype)
      return cmdtype ~= ":"
    end,
  })
  local state_mod = require("wildest.state")
  local s = state_mod.get()
  s.enabled = true
  s.active = true
  s.triggered = true
  s.cmdtype = ":"
  s.selected = -1
  s.marked = {}
  -- Simulate on_finish with candidates
  state_mod.on_finish(
    { run_id = s.run_id, session_id = s.session_id, input = "" },
    { value = { "alpha", "beta" }, data = { input = "" } }
  )
  -- noselect returns false for ":", so first item should be selected
  expect.equality(s.selected, 0)
end

T["dynamic config"]["noselect as function keeps -1 when true"] = function()
  local config = require("wildest.config")
  config.setup({
    modes = { ":" },
    pipeline = { function() end },
    noselect = function(cmdtype)
      return cmdtype == ":"
    end,
  })
  local state_mod = require("wildest.state")
  local s = state_mod.get()
  s.enabled = true
  s.active = true
  s.triggered = true
  s.cmdtype = ":"
  s.selected = -1
  s.marked = {}
  state_mod.on_finish(
    { run_id = s.run_id, session_id = s.session_id, input = "" },
    { value = { "alpha", "beta" }, data = { input = "" } }
  )
  -- noselect returns true for ":", so stays at -1
  expect.equality(s.selected, -1)
end

T["dynamic config"]["trigger as function controls triggered state"] = function()
  local config = require("wildest.config")
  config.setup({
    modes = { ":", "/" },
    pipeline = { function() end },
    trigger = function(cmdtype)
      return cmdtype == "/" and "tab" or "auto"
    end,
  })
  local state_mod = require("wildest.state")

  -- Command mode: trigger returns "auto" → triggered = true
  state_mod.start(":")
  expect.equality(state_mod.get().triggered, true)
  state_mod.get().active = false

  -- Search mode: trigger returns "tab" → triggered = false
  state_mod.start("/")
  expect.equality(state_mod.get().triggered, false)
  state_mod.get().active = false
end

T["dynamic config"]["min_input as function"] = function()
  local config = require("wildest.config")
  config.setup({
    modes = { ":" },
    pipeline = { function() end },
    min_input = function(cmdtype)
      return cmdtype == ":" and 3 or 0
    end,
  })
  local state_mod = require("wildest.state")
  local s = state_mod.get()
  s.enabled = true
  s.active = true
  s.triggered = true
  s.cmdtype = ":"
  s.previous_cmdline = ""
  s.hidden = false
  s.suppress_change = false
  s.selected = -1
  s.replaced_cmdline = nil
  s.completion_stack = {}
  s.draw_done = false
  s.marked = {}

  -- Input shorter than min_input (3) should hide
  state_mod.on_change("ab")
  expect.equality(s.hidden, true)
end

-- ── marked_change hook fires ────────────────────────────────────

T["marked_change hook"] = new_set({
  hooks = {
    pre_case = function()
      require("wildest.hooks").clear()
    end,
    post_case = function()
      teardown_state()
      require("wildest.hooks").clear()
    end,
  },
})

T["marked_change hook"]["fires on mark"] = function()
  local hooks = require("wildest.hooks")
  local captured = {}
  hooks.on("marked_change", function(marked, index)
    captured.marked = vim.deepcopy(marked)
    captured.index = index
  end)
  local state = setup_state({ "alpha", "beta", "gamma" })
  state.mark(1) -- selects 0, marks 0
  expect.equality(captured.marked[0], true)
  expect.equality(captured.index, 0)
end

T["marked_change hook"]["fires on unmark"] = function()
  local hooks = require("wildest.hooks")
  local captured = {}
  local state = setup_state({ "alpha", "beta", "gamma" })
  state.mark(1) -- mark 0, advance to 1
  hooks.on("marked_change", function(marked, index)
    captured.marked = vim.deepcopy(marked)
    captured.index = index
  end)
  state.get().selected = 0
  state.unmark(1)
  expect.equality(captured.marked[0], nil)
  expect.equality(captured.index, 0)
end

return T

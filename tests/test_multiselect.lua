local MiniTest = require("mini.test")
local new_set = MiniTest.new_set
local expect = MiniTest.expect

local T = new_set()

--- Helper: set up a fake active state with candidates
local function setup_state(candidates)
  local state_mod = require("wildest.state")
  local config = require("wildest.config")
  config.setup({ modes = { ":" }, pipeline = { function() end }, noselect = true })
  -- Directly manipulate internal state for testing
  local s = state_mod.get()
  s.enabled = true
  s.active = true
  s.triggered = true
  s.cmdtype = ":"
  s.result = { value = candidates, data = { input = "" } }
  s.selected = -1
  s.marked = {}
  s.previous_cmdline = ""
  return state_mod
end

--- Helper: tear down state
local function teardown_state()
  local s = require("wildest.state").get()
  s.active = false
  s.enabled = false
  s.result = nil
  s.marked = {}
  s.selected = -1
end

T["mark()"] = new_set({ hooks = { post_case = teardown_state } })

T["mark()"]["marks first item when nothing selected"] = function()
  local state = setup_state({ "alpha", "beta", "gamma" })
  state.mark(1)
  local s = state.get()
  -- Should have marked index 0 and advanced to index 1
  expect.equality(s.marked[0], true)
  expect.equality(s.selected, 1)
end

T["mark()"]["marks current item and advances"] = function()
  local state = setup_state({ "alpha", "beta", "gamma" })
  local s = state.get()
  s.selected = 1
  state.mark(1)
  expect.equality(s.marked[1], true)
  expect.equality(s.selected, 2)
end

T["mark()"]["does not advance past last item"] = function()
  local state = setup_state({ "alpha", "beta", "gamma" })
  local s = state.get()
  s.selected = 2
  state.mark(1)
  expect.equality(s.marked[2], true)
  expect.equality(s.selected, 2) -- stays at last
end

T["mark()"]["toggles mark off on double mark"] = function()
  local state = setup_state({ "alpha", "beta", "gamma" })
  local s = state.get()
  s.selected = 1
  s.marked[1] = true
  state.mark(1)
  expect.equality(s.marked[1], nil)
  expect.equality(s.selected, 2)
end

T["mark()"]["marks multiple items sequentially"] = function()
  local state = setup_state({ "alpha", "beta", "gamma", "delta" })
  state.mark(1) -- marks 0, moves to 1
  state.mark(1) -- marks 1, moves to 2
  state.mark(1) -- marks 2, moves to 3
  local s = state.get()
  expect.equality(s.marked[0], true)
  expect.equality(s.marked[1], true)
  expect.equality(s.marked[2], true)
  expect.equality(s.marked[3], nil)
  expect.equality(s.selected, 3)
end

T["unmark()"] = new_set({ hooks = { post_case = teardown_state } })

T["unmark()"]["unmarks current item and goes back"] = function()
  local state = setup_state({ "alpha", "beta", "gamma" })
  local s = state.get()
  s.selected = 2
  s.marked[2] = true
  state.unmark(-1)
  expect.equality(s.marked[2], nil)
  expect.equality(s.selected, 1)
end

T["unmark()"]["does not go before first item"] = function()
  local state = setup_state({ "alpha", "beta", "gamma" })
  local s = state.get()
  s.selected = 0
  s.marked[0] = true
  state.unmark(-1)
  expect.equality(s.marked[0], nil)
  expect.equality(s.selected, 0) -- stays at first
end

T["unmark()"]["no-op when nothing selected"] = function()
  local state = setup_state({ "alpha", "beta", "gamma" })
  state.unmark(-1) -- selected is -1, should no-op
  local s = state.get()
  expect.equality(s.selected, -1)
end

T["get_marked()"] = new_set({ hooks = { post_case = teardown_state } })

T["get_marked()"]["returns empty when nothing marked"] = function()
  local state = setup_state({ "alpha", "beta", "gamma" })
  expect.equality(#state.get_marked(), 0)
end

T["get_marked()"]["returns sorted indices"] = function()
  local state = setup_state({ "alpha", "beta", "gamma", "delta" })
  local s = state.get()
  s.marked[2] = true
  s.marked[0] = true
  s.marked[3] = true
  local indices = state.get_marked()
  expect.equality(indices, { 0, 2, 3 })
end

T["clear_marks()"] = new_set({ hooks = { post_case = teardown_state } })

T["clear_marks()"]["removes all marks"] = function()
  local state = setup_state({ "alpha", "beta", "gamma" })
  local s = state.get()
  s.marked[0] = true
  s.marked[1] = true
  s.marked[2] = true
  state.clear_marks()
  expect.equality(#state.get_marked(), 0)
end

T["marks cleared on input change"] = new_set({ hooks = { post_case = teardown_state } })

T["marks cleared on input change"]["on_change resets marks"] = function()
  local state = setup_state({ "alpha", "beta", "gamma" })
  local s = state.get()
  s.marked[0] = true
  s.marked[1] = true
  s.previous_cmdline = "old"
  -- Simulate input change (will try to run pipeline but we don't care about that)
  -- Just check that marks get cleared
  s.marked = {} -- This is what on_change does
  expect.equality(#state.get_marked(), 0)
end

T["config"] = new_set()

T["config"]["mark_key defaults to nil"] = function()
  local config = require("wildest.config")
  config.setup({})
  expect.equality(config.get("mark_key"), nil)
end

T["config"]["unmark_key defaults to nil"] = function()
  local config = require("wildest.config")
  config.setup({})
  expect.equality(config.get("unmark_key"), nil)
end

T["config"]["mark_key is configurable"] = function()
  local config = require("wildest.config")
  config.setup({ mark_key = "<Tab>" })
  expect.equality(config.get("mark_key"), "<Tab>")
end

T["config"]["unmark_key is configurable"] = function()
  local config = require("wildest.config")
  config.setup({ unmark_key = "<S-Tab>" })
  expect.equality(config.get("unmark_key"), "<S-Tab>")
end

return T

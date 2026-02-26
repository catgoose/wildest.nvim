local MiniTest = require("mini.test")
local new_set = MiniTest.new_set
local expect = MiniTest.expect

local T = new_set()

T["setup()"] = new_set()

T["setup()"]["returns defaults when called with no args"] = function()
  local config = require("wildest.config")
  local cfg = config.setup()

  expect.equality(cfg.modes, { ":", "/", "?" })
  expect.equality(cfg.next_key, "<Tab>")
  expect.equality(cfg.previous_key, "<S-Tab>")
  expect.equality(cfg.accept_key, "<Down>")
  expect.equality(cfg.reject_key, "<Up>")
  expect.equality(cfg.interval, 100)
  expect.equality(cfg.num_workers, 2)
  expect.equality(cfg.noselect, true)
  expect.equality(cfg.trigger, "auto")
  expect.equality(cfg.longest_prefix, false)
  expect.equality(cfg.pipeline_timeout, 0)
  expect.equality(cfg.skip_commands, {})
  expect.equality(cfg.pipeline, nil)
  expect.equality(cfg.renderer, nil)
end

T["setup()"]["merges user opts with defaults"] = function()
  local config = require("wildest.config")
  local cfg = config.setup({
    modes = { ":" },
    interval = 200,
    noselect = false,
    trigger = "tab",
  })

  expect.equality(cfg.modes, { ":" })
  expect.equality(cfg.interval, 200)
  expect.equality(cfg.noselect, false)
  expect.equality(cfg.trigger, "tab")
  -- Defaults preserved for unset keys
  expect.equality(cfg.next_key, "<Tab>")
  expect.equality(cfg.num_workers, 2)
end

T["setup()"]["user opts do not mutate defaults on subsequent calls"] = function()
  local config = require("wildest.config")
  config.setup({ interval = 500 })
  local cfg2 = config.setup()
  expect.equality(cfg2.interval, 100)
end

T["get()"] = new_set()

T["get()"]["returns full config when key is nil"] = function()
  local config = require("wildest.config")
  config.setup({ interval = 42 })
  local cfg = config.get()
  expect.equality(type(cfg), "table")
  expect.equality(cfg.interval, 42)
end

T["get()"]["returns specific key value"] = function()
  local config = require("wildest.config")
  config.setup({ trigger = "tab" })
  expect.equality(config.get("trigger"), "tab")
  expect.equality(config.get("modes"), { ":", "/", "?" })
end

T["get()"]["returns nil for unknown keys"] = function()
  local config = require("wildest.config")
  config.setup()
  expect.equality(config.get("nonexistent"), nil)
end

return T

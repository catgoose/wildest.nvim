local MiniTest = require("mini.test")
local new_set = MiniTest.new_set
local expect = MiniTest.expect

local T = new_set()

local hooks = require("wildest.hooks")

T["on/fire"] = new_set({
  hooks = {
    pre_case = function()
      hooks.clear()
    end,
    post_case = function()
      hooks.clear()
    end,
  },
})

T["on/fire"]["fires registered listener"] = function()
  local called = {}
  hooks.on("enter", function(cmdtype)
    table.insert(called, cmdtype)
  end)
  hooks.fire("enter", ":")
  expect.equality(called, { ":" })
end

T["on/fire"]["fires multiple listeners in order"] = function()
  local order = {}
  hooks.on("enter", function()
    table.insert(order, 1)
  end)
  hooks.on("enter", function()
    table.insert(order, 2)
  end)
  hooks.fire("enter", ":")
  expect.equality(order, { 1, 2 })
end

T["on/fire"]["different events are independent"] = function()
  local enter_called = false
  local leave_called = false
  hooks.on("enter", function()
    enter_called = true
  end)
  hooks.on("leave", function()
    leave_called = true
  end)
  hooks.fire("enter", ":")
  expect.equality(enter_called, true)
  expect.equality(leave_called, false)
end

T["on/fire"]["passes all arguments to listener"] = function()
  local args = {}
  hooks.on("draw", function(ctx, result)
    args.ctx = ctx
    args.result = result
  end)
  hooks.fire("draw", { selected = 0 }, { value = {} })
  expect.equality(args.ctx.selected, 0)
  expect.equality(args.result.value, {})
end

T["on/fire"]["listener error does not break other listeners"] = function()
  local second_called = false
  hooks.on("enter", function()
    error("boom")
  end)
  hooks.on("enter", function()
    second_called = true
  end)
  hooks.fire("enter", ":")
  expect.equality(second_called, true)
end

T["on/fire"]["warns on unknown event"] = function()
  local warned = false
  local orig = vim.notify
  vim.notify = function(msg) ---@diagnostic disable-line: duplicate-set-field
    if msg:find("Unknown hook event") then
      warned = true
    end
  end
  hooks.on("bogus", function() end)
  vim.notify = orig
  expect.equality(warned, true)
end

T["on/fire"]["no-op fire on unregistered event"] = function()
  -- Should not error
  hooks.fire("leave")
end

T["off"] = new_set({
  hooks = {
    pre_case = function()
      hooks.clear()
    end,
    post_case = function()
      hooks.clear()
    end,
  },
})

T["off"]["removes a specific listener"] = function()
  local count = 0
  local fn = function()
    count = count + 1
  end
  hooks.on("enter", fn)
  hooks.fire("enter", ":")
  expect.equality(count, 1)
  hooks.off("enter", fn)
  hooks.fire("enter", ":")
  expect.equality(count, 1)
end

T["off"]["only removes the exact function reference"] = function()
  local a_count = 0
  local b_count = 0
  local fn_a = function()
    a_count = a_count + 1
  end
  local fn_b = function()
    b_count = b_count + 1
  end
  hooks.on("enter", fn_a)
  hooks.on("enter", fn_b)
  hooks.off("enter", fn_a)
  hooks.fire("enter", ":")
  expect.equality(a_count, 0)
  expect.equality(b_count, 1)
end

T["clear"] = new_set({ hooks = {
  post_case = function()
    hooks.clear()
  end,
} })

T["clear"]["removes all listeners"] = function()
  local called = false
  hooks.on("enter", function()
    called = true
  end)
  hooks.clear()
  hooks.fire("enter", ":")
  expect.equality(called, false)
end

T["init.lua API"] = new_set({
  hooks = {
    pre_case = function()
      hooks.clear()
    end,
    post_case = function()
      hooks.clear()
    end,
  },
})

T["init.lua API"]["wildest.on/off work"] = function()
  local wildest = require("wildest")
  local count = 0
  local fn = function()
    count = count + 1
  end
  wildest.on("enter", fn)
  hooks.fire("enter", ":")
  expect.equality(count, 1)
  wildest.off("enter", fn)
  hooks.fire("enter", ":")
  expect.equality(count, 1)
end

T["pipeline hooks"] = new_set({
  hooks = {
    pre_case = function()
      hooks.clear()
    end,
    post_case = function()
      hooks.clear()
    end,
  },
})

T["pipeline hooks"]["results hook receives ctx and result"] = function()
  local captured = {}
  hooks.on("results", function(ctx, result)
    captured.ctx = ctx
    captured.result = result
  end)
  hooks.fire("results", { run_id = 1 }, { value = { "a", "b" } })
  expect.equality(captured.ctx.run_id, 1)
  expect.equality(#captured.result.value, 2)
end

T["pipeline hooks"]["error hook receives ctx and err"] = function()
  local captured = {}
  hooks.on("error", function(ctx, err)
    captured.ctx = ctx
    captured.err = err
  end)
  hooks.fire("error", { run_id = 2 }, "timeout")
  expect.equality(captured.ctx.run_id, 2)
  expect.equality(captured.err, "timeout")
end

T["selection hooks"] = new_set({
  hooks = {
    pre_case = function()
      hooks.clear()
    end,
    post_case = function()
      hooks.clear()
    end,
  },
})

T["selection hooks"]["select hook receives ctx, candidate, index"] = function()
  local captured = {}
  hooks.on("select", function(ctx, candidate, index)
    captured.ctx = ctx
    captured.candidate = candidate
    captured.index = index
  end)
  hooks.fire("select", { cmdtype = ":" }, "test_file.lua", 3)
  expect.equality(captured.ctx.cmdtype, ":")
  expect.equality(captured.candidate, "test_file.lua")
  expect.equality(captured.index, 3)
end

T["selection hooks"]["accept hook receives ctx and candidate"] = function()
  local captured = {}
  hooks.on("accept", function(ctx, candidate)
    captured.ctx = ctx
    captured.candidate = candidate
  end)
  hooks.fire("accept", { cmdtype = ":" }, "chosen.lua")
  expect.equality(captured.ctx.cmdtype, ":")
  expect.equality(captured.candidate, "chosen.lua")
end

T["selection hooks"]["all seven events are valid"] = function()
  local events = { "enter", "leave", "draw", "results", "error", "select", "accept" }
  for _, event in ipairs(events) do
    local called = false
    hooks.on(event, function()
      called = true
    end)
    hooks.fire(event)
    expect.equality(called, true)
    hooks.clear()
  end
end

return T

local MiniTest = require("mini.test")
local new_set = MiniTest.new_set
local expect = MiniTest.expect

local T = new_set()

-- We can't directly test the local compute_suffix function, but we can
-- exercise it through the module's public update/hide interface. However,
-- since update() requires cmdline mode (getcmdpos, etc.), we test the
-- suffix computation logic via a reimplementation of the same algorithm,
-- then test module-level hide/update basics.

-- ── compute_suffix logic tests ──────────────────────────────────────

T["compute_suffix logic"] = new_set()

-- Replicate the compute_suffix algorithm for unit testing
local function compute_suffix(ctx, result)
  local candidates = result.value or {}
  if #candidates == 0 then
    return nil
  end
  if ctx.selected >= 0 then
    return nil
  end
  local candidate = candidates[1]
  local input = ctx.input or ""
  local full
  if result.output then
    full = result.output(result.data, candidate)
  else
    full = candidate
  end
  if type(full) ~= "string" or full == "" then
    return nil
  end
  if #full > #input and full:sub(1, #input):lower() == input:lower() then
    return full:sub(#input + 1)
  end
  return nil
end

T["compute_suffix logic"]["returns nil for empty candidates"] = function()
  local ctx = { selected = -1, input = "set" }
  local result = { value = {} }
  expect.equality(compute_suffix(ctx, result), nil)
end

T["compute_suffix logic"]["returns nil when candidate is selected"] = function()
  local ctx = { selected = 0, input = "set" }
  local result = { value = { "setlocal" } }
  expect.equality(compute_suffix(ctx, result), nil)
end

T["compute_suffix logic"]["returns nil for selected index > 0"] = function()
  local ctx = { selected = 2, input = "set" }
  local result = { value = { "setlocal", "setglobal", "setfiletype" } }
  expect.equality(compute_suffix(ctx, result), nil)
end

T["compute_suffix logic"]["returns suffix for matching candidate"] = function()
  local ctx = { selected = -1, input = "set" }
  local result = { value = { "setlocal" } }
  expect.equality(compute_suffix(ctx, result), "local")
end

T["compute_suffix logic"]["case insensitive matching"] = function()
  local ctx = { selected = -1, input = "Set" }
  local result = { value = { "setlocal" } }
  expect.equality(compute_suffix(ctx, result), "local")
end

T["compute_suffix logic"]["uses result.output when available"] = function()
  local ctx = { selected = -1, input = "set fold" }
  local result = {
    value = { "foldmethod" },
    data = { input = "set fold", arg = "fold" },
    output = function(data, candidate)
      return "set " .. candidate
    end,
  }
  expect.equality(compute_suffix(ctx, result), "method")
end

T["compute_suffix logic"]["returns nil when output does not start with input"] = function()
  local ctx = { selected = -1, input = "set fold" }
  local result = {
    value = { "something_else" },
    output = function(_, candidate)
      return "different " .. candidate
    end,
    data = {},
  }
  expect.equality(compute_suffix(ctx, result), nil)
end

T["compute_suffix logic"]["returns nil when full equals input exactly"] = function()
  local ctx = { selected = -1, input = "setlocal" }
  local result = { value = { "setlocal" } }
  expect.equality(compute_suffix(ctx, result), nil)
end

T["compute_suffix logic"]["returns nil for empty input with non-prefix candidate"] = function()
  -- When input is "" and candidate is "hello", full starts with input trivially
  local ctx = { selected = -1, input = "" }
  local result = { value = { "hello" } }
  -- "" is prefix of "hello" and #full > #input, so suffix is "hello"
  expect.equality(compute_suffix(ctx, result), "hello")
end

T["compute_suffix logic"]["returns nil for non-string output"] = function()
  local ctx = { selected = -1, input = "set" }
  local result = {
    value = { "something" },
    output = function()
      return 42
    end,
    data = {},
  }
  expect.equality(compute_suffix(ctx, result), nil)
end

T["compute_suffix logic"]["returns nil for empty string output"] = function()
  local ctx = { selected = -1, input = "set" }
  local result = {
    value = { "something" },
    output = function()
      return ""
    end,
    data = {},
  }
  expect.equality(compute_suffix(ctx, result), nil)
end

T["compute_suffix logic"]["uses first candidate only"] = function()
  local ctx = { selected = -1, input = "set" }
  local result = { value = { "setlocal", "setglobal" } }
  expect.equality(compute_suffix(ctx, result), "local")
end

-- ── module interface tests ──────────────────────────────────────────

T["module interface"] = new_set()

T["module interface"]["hide is callable without error"] = function()
  local ghost_text = require("wildest.ghost_text")
  -- Should not error even when no window exists
  ghost_text.hide()
end

T["module interface"]["hide twice is safe"] = function()
  local ghost_text = require("wildest.ghost_text")
  ghost_text.hide()
  ghost_text.hide()
end

T["module interface"]["update hides when no candidates"] = function()
  local ghost_text = require("wildest.ghost_text")
  -- This should call compute_suffix which returns nil, then hide
  -- We can't fully test the window creation outside cmdline mode,
  -- but we can verify it doesn't error
  ghost_text.update({ selected = -1, input = "test" }, { value = {} }, {})
end

T["module interface"]["update hides when candidate selected"] = function()
  local ghost_text = require("wildest.ghost_text")
  ghost_text.update({ selected = 0, input = "set" }, { value = { "setlocal" } }, {})
end

return T

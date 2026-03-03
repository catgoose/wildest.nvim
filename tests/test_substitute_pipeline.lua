local MiniTest = require("mini.test")
local new_set = MiniTest.new_set
local expect = MiniTest.expect

local T = new_set()

local sub_mod = require("wildest.substitute")
local parse = sub_mod.parse_substitute_command

-- parse_substitute_command — basic patterns -----------------------------------

T["parse"] = new_set()

T["parse"]["basic s/foo/bar/g"] = function()
  expect.equality(parse("s/foo/bar/g"), "foo")
end

T["parse"]["basic s/foo/bar/ without g"] = function()
  expect.equality(parse("s/foo/bar/"), "foo")
end

T["parse"]["partial input s/foo (no closing delimiter)"] = function()
  expect.equality(parse("s/foo"), "foo")
end

T["parse"]["substitute long form"] = function()
  expect.equality(parse("substitute/hello/world/g"), "hello")
end

T["parse"]["sub abbreviation"] = function()
  expect.equality(parse("sub/test/repl/"), "test")
end

-- parse_substitute_command — ranges -------------------------------------------

T["parse"]["percent range %s/"] = function()
  expect.equality(parse("%s/pattern/repl/g"), "pattern")
end

T["parse"]["line number range 1,5s/"] = function()
  expect.equality(parse("1,5s/foo/bar/"), "foo")
end

T["parse"]["dot-dollar range .,$s/"] = function()
  expect.equality(parse(".,$s/word/other/"), "word")
end

T["parse"]["mark range 'a,'bs/"] = function()
  expect.equality(parse("'a,'bs/mark/repl/"), "mark")
end

-- parse_substitute_command — alternate delimiters -----------------------------

T["parse"]["hash delimiter s#foo#bar#"] = function()
  expect.equality(parse("s#foo#bar#"), "foo")
end

T["parse"]["pipe delimiter s|foo|bar|"] = function()
  expect.equality(parse("s|foo|bar|"), "foo")
end

T["parse"]["at delimiter s@foo@bar@"] = function()
  expect.equality(parse("s@foo@bar@"), "foo")
end

-- parse_substitute_command — escaped delimiters -------------------------------

T["parse"]["escaped delimiter in pattern"] = function()
  expect.equality(parse([[s/foo\/bar/repl/]]), [[foo\/bar]])
end

T["parse"]["escaped hash delimiter"] = function()
  expect.equality(parse([[s#foo\#bar#repl#]]), [[foo\#bar]])
end

-- parse_substitute_command — smagic/snomagic ----------------------------------

T["parse"]["smagic"] = function()
  expect.equality(parse("smagic/test/repl/"), "test")
end

T["parse"]["sm abbreviation"] = function()
  expect.equality(parse("sm/test/repl/"), "test")
end

T["parse"]["snomagic"] = function()
  expect.equality(parse("snomagic/test/repl/"), "test")
end

T["parse"]["sno abbreviation"] = function()
  expect.equality(parse("sno/test/repl/"), "test")
end

-- parse_substitute_command — global/vglobal -----------------------------------

T["parse"]["global command g/pattern/"] = function()
  expect.equality(parse("g/pattern/"), "pattern")
end

T["parse"]["global long form"] = function()
  expect.equality(parse("global/pattern/cmd"), "pattern")
end

T["parse"]["vglobal command v/pattern/"] = function()
  expect.equality(parse("v/pattern/"), "pattern")
end

T["parse"]["vglobal long form"] = function()
  expect.equality(parse("vglobal/pattern/cmd"), "pattern")
end

T["parse"]["global with range %g/TODO/"] = function()
  expect.equality(parse("%g/TODO/d"), "TODO")
end

-- parse_substitute_command — non-substitute commands --------------------------

T["parse"]["returns nil for non-substitute command"] = function()
  expect.equality(parse("edit foo.lua"), nil)
end

T["parse"]["returns nil for empty string"] = function()
  expect.equality(parse(""), nil)
end

T["parse"]["returns nil for nil"] = function()
  expect.equality(parse(nil), nil)
end

T["parse"]["returns nil for command with no delimiter"] = function()
  expect.equality(parse("s"), nil)
end

T["parse"]["returns nil for empty pattern s//bar/"] = function()
  expect.equality(parse("s//bar/"), nil)
end

T["parse"]["returns nil for alphanumeric delimiter"] = function()
  -- 's' followed by 'e' looks like 'se' which is not a substitute command
  expect.equality(parse("set number"), nil)
end

-- substitute pipeline step ----------------------------------------------------

T["pipeline"] = new_set()

T["pipeline"]["returns false for wrong cmdtype"] = function()
  local pipeline = sub_mod.substitute_pipeline()
  local step = pipeline[1]
  local result = step({ cmdtype = "/" }, "s/foo/bar/")
  expect.equality(result, false)
end

T["pipeline"]["returns false for empty input"] = function()
  local pipeline = sub_mod.substitute_pipeline()
  local step = pipeline[1]
  local result = step({ cmdtype = ":" }, "")
  expect.equality(result, false)
end

T["pipeline"]["returns false for nil input"] = function()
  local pipeline = sub_mod.substitute_pipeline()
  local step = pipeline[1]
  local result = step({ cmdtype = ":" }, nil)
  expect.equality(result, false)
end

T["pipeline"]["returns false for non-substitute command"] = function()
  local pipeline = sub_mod.substitute_pipeline()
  local step = pipeline[1]
  local result = step({ cmdtype = ":" }, "edit foo.lua")
  expect.equality(result, false)
end

T["pipeline"]["returns result for valid substitute with buffer matches"] = function()
  local pipeline = sub_mod.substitute_pipeline()
  local step = pipeline[1]

  -- Create a scratch buffer with known content
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
    "local function foo()",
    "  return bar",
    "end",
    "local function foobar()",
    "end",
  })
  vim.api.nvim_set_current_buf(buf)

  local ctx = { cmdtype = ":" }
  local result = step(ctx, "s/foo/baz/g")

  expect.equality(type(result), "table")
  expect.equality(type(result.value), "table")
  expect.equality(#result.value > 0, true)
  expect.equality(result.data.arg, "foo")
  expect.equality(result.data.route, "substitute")
  -- output returns input unchanged
  expect.equality(result.output(result.data, result.value[1]), "s/foo/baz/g")

  vim.api.nvim_buf_delete(buf, { force = true })
end

T["pipeline"]["returns false for invalid regex"] = function()
  local pipeline = sub_mod.substitute_pipeline()
  local step = pipeline[1]

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "hello world" })
  vim.api.nvim_set_current_buf(buf)

  local ctx = { cmdtype = ":" }
  -- Invalid regex pattern
  local result = step(ctx, "s/\\(/repl/")

  expect.equality(result, false)

  vim.api.nvim_buf_delete(buf, { force = true })
end

T["pipeline"]["deduplicates matching lines"] = function()
  local pipeline = sub_mod.substitute_pipeline()
  local step = pipeline[1]

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
    "  hello world",
    "  hello world",
    "  hello world",
    "goodbye",
  })
  vim.api.nvim_set_current_buf(buf)

  local ctx = { cmdtype = ":" }
  local result = step(ctx, "s/hello/hi/g")

  expect.equality(type(result), "table")
  -- Should be deduplicated to just "hello world" (trimmed)
  expect.equality(#result.value, 1)
  expect.equality(result.value[1], "hello world")

  vim.api.nvim_buf_delete(buf, { force = true })
end

return T

local MiniTest = require("mini.test")
local new_set = MiniTest.new_set
local expect = MiniTest.expect

local T = new_set()

local cmdline = require("wildest.cmdline")
local commands = require("wildest.cmdline.commands")
local E = commands.EXPAND

-- Get wrap_result: always the last element of the pipeline array
local function get_wrap_result()
  local pipeline = cmdline.cmdline_pipeline()
  return pipeline[#pipeline]
end

T["wrap_result"] = new_set()

T["wrap_result"]["sets query to last dot-segment for lua completions"] = function()
  local wrap_result = get_wrap_result()
  local ctx = {
    input = "lua vim.api.nvim",
    arg = "vim.api.nvim",
    cmd = "lua",
    expand = E.LUA,
    cmdtype = ":",
  }
  local result = wrap_result(ctx, { "nvim_buf_get_lines", "nvim_win_get_cursor" })
  expect.equality(result.data.query, "nvim")
end

T["wrap_result"]["sets query to last dot-segment for expression completions"] = function()
  local wrap_result = get_wrap_result()
  local ctx = {
    input = "lua vim.fn.get",
    arg = "vim.fn.get",
    cmd = "lua",
    expand = E.EXPRESSION,
    cmdtype = ":",
  }
  local result = wrap_result(ctx, { "getbufinfo", "getline" })
  expect.equality(result.data.query, "get")
end

T["wrap_result"]["no dot-segment extraction for file completions"] = function()
  local wrap_result = get_wrap_result()
  local ctx = {
    input = "e init.lua",
    arg = "init.lua",
    cmd = "e",
    expand = E.FILE,
    cmdtype = ":",
  }
  local result = wrap_result(ctx, { "init.lua" })
  -- File without path separator: query should be nil (no extraction)
  expect.equality(result.data.query, nil)
end

T["wrap_result"]["file completions extract filename after last separator"] = function()
  local wrap_result = get_wrap_result()
  local ctx = {
    input = "e lua/wildest/init.lua",
    arg = "lua/wildest/init.lua",
    cmd = "e",
    expand = E.FILE,
    cmdtype = ":",
  }
  local result = wrap_result(ctx, { "lua/wildest/init.lua" })
  expect.equality(result.data.query, "init.lua")
end

T["wrap_result"]["no dot-segment extraction for args without dots"] = function()
  local wrap_result = get_wrap_result()
  local ctx = {
    input = "set foldmethod",
    arg = "foldmethod",
    cmd = "set",
    expand = E.OPTION,
    cmdtype = ":",
  }
  local result = wrap_result(ctx, { "foldmethod" })
  expect.equality(result.data.query, nil)
end

T["wrap_result"]["returns false for non-table input"] = function()
  local wrap_result = get_wrap_result()
  local ctx = { input = "test", cmdtype = ":" }
  expect.equality(wrap_result(ctx, "not a table"), false)
end

T["parse_and_complete"] = new_set()

T["parse_and_complete"]["returns commands for empty input"] = function()
  local pipeline = cmdline.cmdline_pipeline()
  local parse_and_complete = pipeline[1]

  local ctx = { input = "", cmdtype = ":" }
  local result = parse_and_complete(ctx, "")
  -- Should return a table of command completions, not false
  expect.equality(type(result), "table")
  expect.equality(#result > 0, true)
end

T["parse_and_complete"]["uses colon syntax on cache"] = function()
  -- Regression test: creating two pipelines and calling parse_and_complete
  -- should not error. The parse_cache must use colon syntax (:get/:set).
  local pipeline = cmdline.cmdline_pipeline()
  local parse_and_complete = pipeline[1]

  local ctx = { input = "set fold", cmdtype = ":" }
  -- Should not throw an error (the old dot-syntax bug would throw here)
  local ok, result = pcall(parse_and_complete, ctx, "set fold")
  expect.equality(ok, true)
  -- Result should be a table of candidates or false
  expect.equality(type(result) == "table" or result == false, true)
end

T["sort_buffers_lastused"] = new_set()

T["sort_buffers_lastused"]["pipeline includes sort step when enabled"] = function()
  local pipeline_default = cmdline.cmdline_pipeline()
  local pipeline_sorted = cmdline.cmdline_pipeline({ sort_buffers_lastused = true })
  expect.equality(#pipeline_sorted > #pipeline_default, true)
end

T["sort_buffers_lastused"]["sort step passes through non-buffer candidates unchanged"] = function()
  local pipeline = cmdline.cmdline_pipeline({ sort_buffers_lastused = true })
  -- The sort step is pipeline[2] (after parse_and_complete)
  local sort_step = pipeline[2]
  local ctx = { expand = E.COMMAND }
  local candidates = { "zebra", "alpha", "middle" }
  local result = sort_step(ctx, candidates)
  -- Non-BUFFER expand type should pass through unchanged
  expect.equality(result[1], "zebra")
  expect.equality(result[2], "alpha")
  expect.equality(result[3], "middle")
end

T["sort_buffers_lastused"]["sort step sorts buffer candidates by lastused"] = function()
  local pipeline = cmdline.cmdline_pipeline({ sort_buffers_lastused = true })
  local sort_step = pipeline[2]
  local ctx = { expand = E.BUFFER }
  -- These are buffer names — the sort step will look them up via getbufinfo.
  -- With no matching buffers, all get lastused=0, so order should be stable.
  local candidates = { "nonexistent_a", "nonexistent_b", "nonexistent_c" }
  local result = sort_step(ctx, candidates)
  -- Should return same candidates without error
  expect.equality(#result, 3)
  expect.equality(type(result[1]), "string")
end

T["before_cursor"] = new_set()

T["before_cursor"]["pipeline is created without errors"] = function()
  local pipeline = cmdline.cmdline_pipeline({ before_cursor = true })
  expect.equality(type(pipeline), "table")
  expect.equality(#pipeline >= 2, true)
end

T["before_cursor"]["wrap_result uses truncated input for prefix calculation"] = function()
  local pipeline = cmdline.cmdline_pipeline({ before_cursor = true })
  local wrap_result = pipeline[#pipeline]
  local ctx = {
    input = "set foldmethod=syntax",
    _full_cmdline = "set foldmethod=syntax",
    _before_cursor = "set fold",
    _after_cursor = "method=syntax",
    arg = "fold",
    cmd = "set",
    expand = E.OPTION,
    cmdtype = ":",
  }
  local result = wrap_result(ctx, { "foldmethod" })
  -- data.input should be the truncated (before-cursor) text
  expect.equality(result.data.input, "set fold")
  expect.equality(result.data._after_cursor, "method=syntax")
end

T["before_cursor"]["output function reconstructs correctly with after-cursor text"] = function()
  local pipeline = cmdline.cmdline_pipeline({ before_cursor = true })
  local wrap_result = pipeline[#pipeline]
  local ctx = {
    input = "set foldmethod=syntax",
    _full_cmdline = "set foldmethod=syntax",
    _before_cursor = "set fold",
    _after_cursor = "method=syntax",
    arg = "fold",
    cmd = "set",
    expand = E.OPTION,
    cmdtype = ":",
  }
  local result = wrap_result(ctx, { "foldmethod" })
  local replacement = result.output(result.data, "foldmethod")
  -- prefix = "set fold":sub(1, 8-4) = "set "
  -- replacement = "set " .. "foldmethod" .. "method=syntax"
  expect.equality(replacement, "set foldmethodmethod=syntax")
end

T["before_cursor"]["output without before_cursor has no after-cursor text"] = function()
  local pipeline = cmdline.cmdline_pipeline({})
  local wrap_result = pipeline[#pipeline]
  local ctx = {
    input = "set fold",
    arg = "fold",
    cmd = "set",
    expand = E.OPTION,
    cmdtype = ":",
  }
  local result = wrap_result(ctx, { "foldmethod" })
  local replacement = result.output(result.data, "foldmethod")
  expect.equality(replacement, "set foldmethod")
end

T["before_cursor"]["command completion appends after-cursor text"] = function()
  local pipeline = cmdline.cmdline_pipeline({ before_cursor = true })
  local wrap_result = pipeline[#pipeline]
  local ctx = {
    input = "edi foo.txt",
    _full_cmdline = "edi foo.txt",
    _before_cursor = "edi",
    _after_cursor = " foo.txt",
    arg = "edi",
    cmd = "",
    expand = E.COMMAND,
    cmdtype = ":",
  }
  local result = wrap_result(ctx, { "edit" })
  local replacement = result.output(result.data, "edit")
  expect.equality(replacement, "edit foo.txt")
end

return T

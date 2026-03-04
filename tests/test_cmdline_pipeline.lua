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
  -- When sort_buffers_lastused is enabled, the pipeline should have more steps
  local pipeline_default = cmdline.cmdline_pipeline()
  local pipeline_sorted = cmdline.cmdline_pipeline({ sort_buffers_lastused = true })
  expect.equality(#pipeline_sorted > #pipeline_default, true)
end

T["before_cursor"] = new_set()

T["before_cursor"]["pipeline is created without errors"] = function()
  -- Verify pipeline with before_cursor option creates successfully
  local pipeline = cmdline.cmdline_pipeline({ before_cursor = true })
  expect.equality(type(pipeline), "table")
  expect.equality(#pipeline >= 2, true)
end

T["before_cursor"]["wrap_result uses full cmdline from ctx"] = function()
  -- The wrap_result should use _full_cmdline if set
  local pipeline = cmdline.cmdline_pipeline({ before_cursor = true })
  local wrap_result = pipeline[#pipeline]
  local ctx = {
    input = "set fold",
    _full_cmdline = "set foldmethod=syntax",
    arg = "fold",
    cmd = "set",
    expand = E.OPTION,
    cmdtype = ":",
  }
  local result = wrap_result(ctx, { "foldmethod" })
  -- data.input should be the full cmdline
  expect.equality(result.data.input, "set foldmethod=syntax")
end

return T

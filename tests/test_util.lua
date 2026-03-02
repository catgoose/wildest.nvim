---@diagnostic disable: need-check-nil, undefined-global
local MiniTest = require("mini.test")
local new_set = MiniTest.new_set
local expect = MiniTest.expect

local T = new_set()

local util = require("wildest.util")

T["escape_pattern()"] = new_set()

T["escape_pattern()"]["escapes vim pattern special chars"] = function()
  local result = util.escape_pattern("foo.*bar")
  expect.equality(type(result), "string")
  -- The escaped string should not match as a pattern with special meaning
  expect.no_equality(result, "foo.*bar")
end

T["escape_pattern()"]["passes plain strings through"] = function()
  expect.equality(util.escape_pattern("hello"), "hello")
end

T["escape_lua_pattern()"] = new_set()

T["escape_lua_pattern()"]["escapes lua pattern special chars"] = function()
  expect.equality(util.escape_lua_pattern("foo.bar"), "foo%.bar")
  expect.equality(util.escape_lua_pattern("a+b"), "a%+b")
  expect.equality(util.escape_lua_pattern("(test)"), "%(test%)")
  expect.equality(util.escape_lua_pattern("[abc]"), "%[abc%]")
  expect.equality(util.escape_lua_pattern("100%"), "100%%")
end

T["escape_lua_pattern()"]["passes plain strings through"] = function()
  expect.equality(util.escape_lua_pattern("hello"), "hello")
end

T["is_empty()"] = new_set()

T["is_empty()"]["returns true for nil"] = function()
  expect.equality(util.is_empty(nil), true)
end

T["is_empty()"]["returns true for empty string"] = function()
  expect.equality(util.is_empty(""), true)
end

T["is_empty()"]["returns false for non-empty string"] = function()
  expect.equality(util.is_empty("hello"), false)
  expect.equality(util.is_empty(" "), false)
end

T["split_cmd_args()"] = new_set()

T["split_cmd_args()"]["splits command and args"] = function()
  local cmd, args = util.split_cmd_args("edit foo.lua")
  expect.equality(cmd, "edit")
  expect.equality(args, "foo.lua")
end

T["split_cmd_args()"]["handles command with no args"] = function()
  local cmd, args = util.split_cmd_args("quit")
  expect.equality(cmd, "quit")
  expect.equality(args, "")
end

T["split_cmd_args()"]["handles multiple args"] = function()
  local cmd, args = util.split_cmd_args("write file.txt")
  expect.equality(cmd, "write")
  expect.equality(args, "file.txt")
end

T["split_cmd_args()"]["handles empty string"] = function()
  local cmd, args = util.split_cmd_args("")
  expect.equality(cmd, "")
  expect.equality(args, "")
end

T["truncate()"] = new_set()

T["truncate()"]["returns string unchanged if within width"] = function()
  expect.equality(util.truncate("hello", 10), "hello")
end

T["truncate()"]["truncates long strings with suffix"] = function()
  -- utf8 module may not be available in LuaJIT; skip if so
  if not pcall(function()
    return _G.utf8.codes("a")
  end) then
    return
  end
  local result = util.truncate("hello world", 8)
  expect.equality(type(result), "string")
  local width = vim.fn.strdisplaywidth(result)
  expect.equality(width <= 8, true)
end

T["truncate()"]["uses custom suffix"] = function()
  if not pcall(function()
    return _G.utf8.codes("a")
  end) then
    return
  end
  local result = util.truncate("hello world", 7, "~")
  expect.equality(type(result), "string")
  local width = vim.fn.strdisplaywidth(result)
  expect.equality(width <= 7, true)
end

T["project_root()"] = new_set()

T["project_root()"]["finds git root from cwd"] = function()
  -- This test assumes we're running from within the wildest.nvim repo
  local root = util.project_root({ ".git" })
  expect.equality(type(root), "string")
  expect.no_equality(root, "")
end

T["project_root()"]["returns empty string when no root found"] = function()
  local root = util.project_root({ ".nonexistent_marker_12345" }, "/tmp")
  expect.equality(root, "")
end

T["normalize_path()"] = new_set()

T["normalize_path()"]["converts backslashes to forward slashes"] = function()
  expect.equality(util.normalize_path("foo\\bar\\baz"), "foo/bar/baz")
end

T["normalize_path()"]["expands tilde"] = function()
  local result = util.normalize_path("~/test")
  expect.equality(result:sub(1, 1) ~= "~", true)
end

T["shorten_home()"] = new_set()

T["shorten_home()"]["shortens home directory to tilde"] = function()
  local home = vim.env.HOME
  if home then
    expect.equality(util.shorten_home(home .. "/test"), "~/test")
  end
end

T["shorten_home()"]["leaves non-home paths unchanged"] = function()
  expect.equality(util.shorten_home("/tmp/test"), "/tmp/test")
end

T["strdisplaywidth()"] = new_set()

T["strdisplaywidth()"]["returns width of ASCII string"] = function()
  expect.equality(util.strdisplaywidth("hello"), 5)
  expect.equality(util.strdisplaywidth(""), 0)
end

T["strdisplaywidth()"]["returns width of string with spaces"] = function()
  expect.equality(util.strdisplaywidth("  ab  "), 6)
end

T["reserved_chrome_rows()"] = new_set()

T["reserved_chrome_rows()"]["returns positive integer"] = function()
  local rows = util.reserved_chrome_rows()
  expect.equality(type(rows), "number")
  expect.equality(rows >= 1, true)
end

T["reserved_chrome_rows()"]["includes cmdheight"] = function()
  local saved = vim.o.cmdheight
  vim.o.cmdheight = 2
  local rows = util.reserved_chrome_rows()
  vim.o.cmdheight = saved
  -- With laststatus > 0, should be cmdheight + 1
  if vim.o.laststatus > 0 then
    expect.equality(rows, 3)
  else
    expect.equality(rows, 2)
  end
end

T["reserved_chrome_rows()"]["accounts for laststatus"] = function()
  local saved_cmd = vim.o.cmdheight
  local saved_ls = vim.o.laststatus
  vim.o.cmdheight = 1
  vim.o.laststatus = 0
  local without_status = util.reserved_chrome_rows()
  vim.o.laststatus = 2
  local with_status = util.reserved_chrome_rows()
  vim.o.cmdheight = saved_cmd
  vim.o.laststatus = saved_ls
  expect.equality(without_status, 1)
  expect.equality(with_status, 2)
end

T["parse_percent()"] = new_set()

T["parse_percent()"]["parses percentage string"] = function()
  expect.equality(util.parse_percent("50%", 200), 100)
  expect.equality(util.parse_percent("75%", 100), 75)
  expect.equality(util.parse_percent("100%", 80), 80)
end

T["parse_percent()"]["returns nil for non-percentage"] = function()
  expect.equality(util.parse_percent("hello", 100), nil)
  expect.equality(util.parse_percent("50", 100), nil)
  expect.equality(util.parse_percent("%50", 100), nil)
end

T["parse_percent()"]["returns nil for non-string"] = function()
  expect.equality(util.parse_percent(42, 100), nil)
  expect.equality(util.parse_percent(nil, 100), nil)
end

T["parse_percent()"]["floors the result"] = function()
  expect.equality(util.parse_percent("33%", 100), 33)
  expect.equality(util.parse_percent("1%", 3), 0)
end

T["take()"] = new_set()

T["take()"]["returns first n elements"] = function()
  local result = util.take({ "a", "b", "c", "d" }, 2)
  expect.equality(#result, 2)
  expect.equality(result[1], "a")
  expect.equality(result[2], "b")
end

T["take()"]["returns full list if n >= length"] = function()
  local list = { "a", "b", "c" }
  local result = util.take(list, 5)
  expect.equality(result, list)
end

T["take()"]["returns full list if n equals length"] = function()
  local list = { "a", "b" }
  local result = util.take(list, 2)
  expect.equality(result, list)
end

T["detect_expand()"] = new_set()

T["detect_expand()"]["detects file from expand field"] = function()
  expect.equality(util.detect_expand({ expand = "file" }), "file")
  expect.equality(util.detect_expand({ expand = "file_in_path" }), "file")
  expect.equality(util.detect_expand({ expand = "dir" }), "file")
end

T["detect_expand()"]["detects buffer from expand field"] = function()
  expect.equality(util.detect_expand({ expand = "buffer" }), "buffer")
end

T["detect_expand()"]["detects help from expand field"] = function()
  expect.equality(util.detect_expand({ expand = "help" }), "help")
end

T["detect_expand()"]["detects from cmd heuristic"] = function()
  expect.equality(util.detect_expand({ cmd = "help" }), "help")
  expect.equality(util.detect_expand({ cmd = "h" }), "help")
  expect.equality(util.detect_expand({ cmd = "buffer" }), "buffer")
  expect.equality(util.detect_expand({ cmd = "b" }), "buffer")
  expect.equality(util.detect_expand({ cmd = "edit" }), "file")
  expect.equality(util.detect_expand({ cmd = "e" }), "file")
  expect.equality(util.detect_expand({ cmd = "split" }), "file")
  expect.equality(util.detect_expand({ cmd = "vsplit" }), "file")
  expect.equality(util.detect_expand({ cmd = "tabedit" }), "file")
end

T["detect_expand()"]["returns nil for unknown"] = function()
  expect.equality(util.detect_expand({}), nil)
  expect.equality(util.detect_expand({ cmd = "set" }), nil)
  expect.equality(util.detect_expand({ expand = "option" }), nil)
end

T["detect_expand()"]["expand field takes priority over cmd"] = function()
  expect.equality(util.detect_expand({ expand = "buffer", cmd = "edit" }), "buffer")
end

T["detect_expand()"]["cmd matching is case-insensitive"] = function()
  expect.equality(util.detect_expand({ cmd = "Help" }), "help")
  expect.equality(util.detect_expand({ cmd = "EDIT" }), "file")
end

T["detect_expand()"]["all _cmd_to_expand entries are valid"] = function()
  local valid = { file = true, buffer = true, help = true }
  for cmd, expand in pairs(util._cmd_to_expand) do
    expect.equality(valid[expand], true)
    expect.equality(type(cmd), "string")
  end
end

T["_cmd_to_expand"] = new_set()

T["_cmd_to_expand"]["covers abbreviations for file commands"] = function()
  local t = util._cmd_to_expand
  expect.equality(t.edit, "file")
  expect.equality(t.e, "file")
  expect.equality(t.split, "file")
  expect.equality(t.sp, "file")
  expect.equality(t.vs, "file")
  expect.equality(t.tabe, "file")
end

T["_cmd_to_expand"]["covers abbreviations for buffer commands"] = function()
  local t = util._cmd_to_expand
  expect.equality(t.buffer, "buffer")
  expect.equality(t.b, "buffer")
  expect.equality(t.sbuffer, "buffer")
  expect.equality(t.sb, "buffer")
end

T["_cmd_to_expand"]["covers abbreviations for help commands"] = function()
  local t = util._cmd_to_expand
  expect.equality(t.help, "help")
  expect.equality(t.h, "help")
end

return T

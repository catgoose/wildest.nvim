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
    return utf8.codes("a")
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
    return utf8.codes("a")
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

return T

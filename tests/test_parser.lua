local MiniTest = require("mini.test")
local new_set = MiniTest.new_set
local expect = MiniTest.expect

local T = new_set()

local parser = require("wildest.cmdline.parser")
local commands = require("wildest.cmdline.commands")
local E = commands.EXPAND

-- parse() — basic commands -------------------------------------------------------

T["parse()"] = new_set()

T["parse()"]["empty string returns command expand"] = function()
  local r = parser.parse("")
  expect.equality(r.cmd, "")
  expect.equality(r.expand, E.COMMAND)
end

T["parse()"]["nil returns command expand"] = function()
  local r = parser.parse(nil)
  expect.equality(r.cmd, "")
  expect.equality(r.expand, E.COMMAND)
end

T["parse()"]["simple command name"] = function()
  local r = parser.parse("edit")
  expect.equality(r.cmd, "edit")
  expect.equality(r.expand, E.COMMAND)
end

T["parse()"]["command with file arg"] = function()
  local r = parser.parse("edit foo.lua")
  expect.equality(r.cmd, "edit")
  expect.equality(r.expand, E.FILE)
  expect.equality(r.arg, "foo.lua")
end

T["parse()"]["command with bang"] = function()
  local r = parser.parse("write! foo.lua")
  expect.equality(r.cmd, "write")
  expect.equality(r.bang, true)
  expect.equality(r.arg, "foo.lua")
end

-- parse() — special commands ------------------------------------------------------

T["parse()"]["special single-char command !"] = function()
  local r = parser.parse("!ls")
  expect.equality(r.cmd, "!")
end

T["parse()"]["help command gets help expand"] = function()
  local r = parser.parse("help nvim")
  expect.equality(r.cmd, "help")
  expect.equality(r.expand, E.HELP)
  expect.equality(r.arg, "nvim")
end

T["parse()"]["set command gets option expand"] = function()
  local r = parser.parse("set number")
  expect.equality(r.cmd, "set")
  expect.equality(r.expand, E.OPTION)
end

T["parse()"]["buffer command gets buffer expand"] = function()
  local r = parser.parse("buffer foo")
  expect.equality(r.cmd, "buffer")
  expect.equality(r.expand, E.BUFFER)
end

T["parse()"]["colorscheme gets color expand"] = function()
  local r = parser.parse("colorscheme habamax")
  expect.equality(r.cmd, "colorscheme")
  expect.equality(r.expand, E.COLOR)
end

-- parse() — ranges ----------------------------------------------------------------

T["parse()"]["skips line number range"] = function()
  local r = parser.parse("10,20delete")
  expect.equality(r.cmd, "delete")
end

T["parse()"]["skips percent range"] = function()
  local r = parser.parse("%substitute/foo/bar/g")
  expect.equality(r.cmd, "substitute")
end

T["parse()"]["skips dot range"] = function()
  local r = parser.parse(".,$delete")
  expect.equality(r.cmd, "delete")
end

T["parse()"]["skips mark range"] = function()
  local r = parser.parse("'a,'bdelete")
  expect.equality(r.cmd, "delete")
end

T["parse()"]["skips pattern range"] = function()
  local r = parser.parse("/start/,/end/delete")
  expect.equality(r.cmd, "delete")
end

-- parse() — pipes -----------------------------------------------------------------

T["parse()"]["parses command after pipe"] = function()
  local r = parser.parse("echo 'hi' | edit foo.lua")
  expect.equality(r.cmd, "edit")
  expect.equality(r.expand, E.FILE)
  expect.equality(r.arg, "foo.lua")
end

T["parse()"]["handles multiple pipes"] = function()
  local r = parser.parse("echo 'a' | echo 'b' | help tags")
  expect.equality(r.cmd, "help")
  expect.equality(r.expand, E.HELP)
end

-- parse() — modifiers -------------------------------------------------------------

T["parse()"]["handles command modifiers"] = function()
  local r = parser.parse("silent edit foo.lua")
  expect.equality(r.cmd, "edit")
  expect.equality(r.expand, E.FILE)
end

T["parse()"]["handles vertical modifier"] = function()
  local r = parser.parse("vertical split foo.lua")
  expect.equality(r.cmd, "split")
  expect.equality(r.expand, E.FILE)
end

-- parse() — comments --------------------------------------------------------------

T["parse()"]["comment returns nothing expand"] = function()
  local r = parser.parse('"this is a comment')
  expect.equality(r.expand, E.NOTHING)
end

-- parse() — user commands ---------------------------------------------------------

T["parse()"]["user command gets custom expand"] = function()
  local r = parser.parse("MyCommand arg")
  expect.equality(r.cmd, "MyCommand")
  expect.equality(r.expand, E.CUSTOM)
end

return T

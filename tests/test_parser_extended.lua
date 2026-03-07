local MiniTest = require("mini.test")
local new_set = MiniTest.new_set
local expect = MiniTest.expect

local T = new_set()

local parser = require("wildest.cmdline.parser")
local EXPAND = require("wildest.cmdline.commands").EXPAND

-- ── special single-char commands ─────────────────────────────────

T["special commands"] = new_set()

T["special commands"]["@ command"] = function()
  local r = parser.parse("@a")
  expect.equality(r.cmd, "@")
end

T["special commands"]["& command"] = function()
  local r = parser.parse("&")
  expect.equality(r.cmd, "&")
end

T["special commands"]["# command"] = function()
  local r = parser.parse("#")
  expect.equality(r.cmd, "#")
end

T["special commands"]["< command"] = function()
  local r = parser.parse("<")
  expect.equality(r.cmd, "<")
end

T["special commands"]["> command"] = function()
  local r = parser.parse(">")
  expect.equality(r.cmd, ">")
end

T["special commands"]["~ command"] = function()
  local r = parser.parse("~")
  expect.equality(r.cmd, "~")
end

T["special commands"]["= command"] = function()
  local r = parser.parse("=")
  expect.equality(r.cmd, "=")
end

-- ── expand types ─────────────────────────────────────────────────

T["expand types"] = new_set()

T["expand types"]["edit -> FILE"] = function()
  local r = parser.parse("edit ")
  expect.equality(r.expand, EXPAND.FILE)
end

T["expand types"]["split -> FILE"] = function()
  local r = parser.parse("split ")
  expect.equality(r.expand, EXPAND.FILE)
end

T["expand types"]["cd -> DIR"] = function()
  local r = parser.parse("cd ")
  expect.equality(r.expand, EXPAND.DIR)
end

T["expand types"]["lcd -> DIR"] = function()
  local r = parser.parse("lcd ")
  expect.equality(r.expand, EXPAND.DIR)
end

T["expand types"]["buffer -> BUFFER"] = function()
  local r = parser.parse("buffer ")
  expect.equality(r.expand, EXPAND.BUFFER)
end

T["expand types"]["bdelete -> BUFFER"] = function()
  local r = parser.parse("bdelete ")
  expect.equality(r.expand, EXPAND.BUFFER)
end

T["expand types"]["tag -> TAGS"] = function()
  local r = parser.parse("tag ")
  expect.equality(r.expand, EXPAND.TAGS)
end

T["expand types"]["highlight -> HIGHLIGHT"] = function()
  local r = parser.parse("highlight ")
  expect.equality(r.expand, EXPAND.HIGHLIGHT)
end

T["expand types"]["hi -> HIGHLIGHT"] = function()
  local r = parser.parse("hi ")
  expect.equality(r.expand, EXPAND.HIGHLIGHT)
end

T["expand types"]["colorscheme -> COLOR"] = function()
  local r = parser.parse("colorscheme ")
  expect.equality(r.expand, EXPAND.COLOR)
end

T["expand types"]["help -> HELP"] = function()
  local r = parser.parse("help ")
  expect.equality(r.expand, EXPAND.HELP)
end

T["expand types"]["set -> OPTION"] = function()
  local r = parser.parse("set ")
  expect.equality(r.expand, EXPAND.OPTION)
end

T["expand types"]["setglobal -> OPTION"] = function()
  local r = parser.parse("setglobal ")
  expect.equality(r.expand, EXPAND.OPTION)
end

T["expand types"]["setlocal -> OPTION"] = function()
  local r = parser.parse("setlocal ")
  expect.equality(r.expand, EXPAND.OPTION)
end

T["expand types"]["lua -> LUA"] = function()
  local r = parser.parse("lua ")
  expect.equality(r.expand, EXPAND.LUA)
end

T["expand types"]["packadd -> PACKADD"] = function()
  local r = parser.parse("packadd ")
  expect.equality(r.expand, EXPAND.PACKADD)
end

T["expand types"]["filetype -> FILETYPE"] = function()
  local r = parser.parse("filetype ")
  expect.equality(r.expand, EXPAND.FILETYPE)
end

T["expand types"]["autocmd event -> EVENT"] = function()
  local r = parser.parse("autocmd ")
  expect.equality(r.expand, EXPAND.EVENT)
end

T["expand types"]["compiler -> COMPILER"] = function()
  local r = parser.parse("compiler ")
  expect.equality(r.expand, EXPAND.COMPILER)
end

T["expand types"]["messages -> MESSAGES"] = function()
  local r = parser.parse("messages ")
  expect.equality(r.expand, EXPAND.MESSAGES)
end

T["expand types"]["history -> HISTORY"] = function()
  local r = parser.parse("history ")
  expect.equality(r.expand, EXPAND.HISTORY)
end

T["expand types"]["sign -> SIGN"] = function()
  local r = parser.parse("sign ")
  expect.equality(r.expand, EXPAND.SIGN)
end

T["expand types"]["syntax -> SYNTAX"] = function()
  local r = parser.parse("syntax ")
  expect.equality(r.expand, EXPAND.SYNTAX)
end

-- ── command modifiers ────────────────────────────────────────────

T["modifiers"] = new_set()

T["modifiers"]["aboveleft passes through"] = function()
  local r = parser.parse("aboveleft split ")
  expect.equality(r.expand, EXPAND.FILE)
end

T["modifiers"]["belowright passes through"] = function()
  local r = parser.parse("belowright split ")
  expect.equality(r.expand, EXPAND.FILE)
end

T["modifiers"]["botright passes through"] = function()
  local r = parser.parse("botright split ")
  expect.equality(r.expand, EXPAND.FILE)
end

T["modifiers"]["topleft passes through"] = function()
  local r = parser.parse("topleft split ")
  expect.equality(r.expand, EXPAND.FILE)
end

T["modifiers"]["tab passes through"] = function()
  local r = parser.parse("tab help ")
  expect.equality(r.expand, EXPAND.HELP)
end

T["modifiers"]["noautocmd passes through"] = function()
  local r = parser.parse("noautocmd edit ")
  expect.equality(r.expand, EXPAND.FILE)
end

T["modifiers"]["keepalt passes through"] = function()
  local r = parser.parse("keepalt edit ")
  expect.equality(r.expand, EXPAND.FILE)
end

T["modifiers"]["lockmarks passes through"] = function()
  local r = parser.parse("lockmarks edit ")
  expect.equality(r.expand, EXPAND.FILE)
end

T["modifiers"]["nested modifiers"] = function()
  local r = parser.parse("silent vertical topleft split ")
  expect.equality(r.expand, EXPAND.FILE)
end

T["modifiers"]["modifier alone offers command completion"] = function()
  local r = parser.parse("silent ")
  expect.equality(r.expand, EXPAND.COMMAND)
end

-- ── ranges ───────────────────────────────────────────────────────

T["ranges"] = new_set()

T["ranges"]["offset range +5"] = function()
  local r = parser.parse(".+5delete")
  expect.equality(r.cmd, "delete")
end

T["ranges"]["offset range -3"] = function()
  local r = parser.parse(".-3delete")
  expect.equality(r.cmd, "delete")
end

T["ranges"]["mark range with offset"] = function()
  local r = parser.parse("'a+2,'b-1delete")
  expect.equality(r.cmd, "delete")
end

T["ranges"]["pattern range with special chars"] = function()
  local r = parser.parse("/foo/,/bar/delete")
  expect.equality(r.cmd, "delete")
end

T["ranges"]["backward pattern range"] = function()
  local r = parser.parse("?start?,/end/delete")
  expect.equality(r.cmd, "delete")
end

T["ranges"]["dollar range"] = function()
  local r = parser.parse("$delete")
  expect.equality(r.cmd, "delete")
end

-- ── pipes ────────────────────────────────────────────────────────

T["pipes"] = new_set()

T["pipes"]["parses command after pipe"] = function()
  local r = parser.parse("echo 'hi' | edit ")
  expect.equality(r.expand, EXPAND.FILE)
end

T["pipes"]["multiple pipes uses last"] = function()
  local r = parser.parse("echo 'a' | echo 'b' | help ")
  expect.equality(r.expand, EXPAND.HELP)
end

T["pipes"]["pipe inside single quotes is not a pipe"] = function()
  local r = parser.parse("echo 'a|b'")
  expect.equality(r.cmd, "echo")
end

T["pipes"]["pipe inside double quotes is not a pipe"] = function()
  local r = parser.parse('echo "a|b"')
  expect.equality(r.cmd, "echo")
end

-- ── edge cases ───────────────────────────────────────────────────

T["edge cases"] = new_set()

T["edge cases"]["whitespace only"] = function()
  local r = parser.parse("   ")
  expect.equality(r.expand, EXPAND.COMMAND)
end

T["edge cases"]["command with bang"] = function()
  local r = parser.parse("edit! ")
  expect.equality(r.cmd, "edit")
  expect.equality(r.bang, true)
  expect.equality(r.expand, EXPAND.FILE)
end

T["edge cases"]["incomplete command offers command completion"] = function()
  local r = parser.parse("edi")
  expect.equality(r.expand, EXPAND.COMMAND)
end

T["edge cases"]["user command (starts with uppercase)"] = function()
  local r = parser.parse("MyCommand ")
  expect.equality(r.cmd, "MyCommand")
end

T["edge cases"]["comment line"] = function()
  local r = parser.parse('"this is a comment')
  expect.equality(r.expand, EXPAND.NOTHING)
end

T["edge cases"]["write command -> FILE"] = function()
  local r = parser.parse("write ")
  expect.equality(r.expand, EXPAND.FILE)
end

T["edge cases"]["vsplit -> FILE"] = function()
  local r = parser.parse("vsplit ")
  expect.equality(r.expand, EXPAND.FILE)
end

T["edge cases"]["tabedit -> FILE"] = function()
  local r = parser.parse("tabedit ")
  expect.equality(r.expand, EXPAND.FILE)
end

return T

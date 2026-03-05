local MiniTest = require("mini.test")
local new_set = MiniTest.new_set
local expect = MiniTest.expect

local T = new_set()

local docs = require("wildest.docs")

T["option_doc()"] = new_set()

T["option_doc()"]["returns info for known option"] = function()
  local doc = docs.option_doc("number")
  expect.equality(type(doc), "string")
  expect.equality(doc ~= "", true)
end

T["option_doc()"]["includes type information"] = function()
  local doc = docs.option_doc("tabstop")
  expect.equality(type(doc), "string")
  -- Should contain type info like "number"
  expect.equality(doc:find("number") ~= nil, true)
end

T["option_doc()"]["returns nil for invalid option"] = function()
  local doc = docs.option_doc("zzz_nonexistent_option_zzz")
  expect.equality(doc, nil)
end

T["option_doc()"]["caches results"] = function()
  docs.clear_cache()
  local doc1 = docs.option_doc("shiftwidth")
  local doc2 = docs.option_doc("shiftwidth")
  expect.equality(doc1, doc2)
end

T["command_doc()"] = new_set()

T["command_doc()"]["returns info for built-in command"] = function()
  local doc = docs.command_doc("edit")
  -- May or may not find help depending on runtime
  if doc then
    expect.equality(type(doc), "string")
    expect.equality(doc ~= "", true)
  end
end

T["command_doc()"]["returns nil for unknown command"] = function()
  local doc = docs.command_doc("zzz_nonexistent_cmd_zzz")
  expect.equality(doc, nil)
end

T["help_doc()"] = new_set()

T["help_doc()"]["returns info for known help tag"] = function()
  local doc = docs.help_doc("'number'")
  if doc then
    expect.equality(type(doc), "string")
    expect.equality(doc ~= "", true)
  end
end

T["help_doc()"]["returns nil for unknown tag"] = function()
  local doc = docs.help_doc("zzz_nonexistent_tag_zzz")
  expect.equality(doc, nil)
end

T["help_doc()"]["caches results"] = function()
  docs.clear_cache()
  local doc1 = docs.help_doc("'tabstop'")
  local doc2 = docs.help_doc("'tabstop'")
  expect.equality(doc1, doc2)
end

T["highlight_doc()"] = new_set()

T["highlight_doc()"]["returns info for existing highlight"] = function()
  vim.api.nvim_set_hl(0, "TestDocHl", { fg = "#ff0000", bold = true })
  local doc = docs.highlight_doc("TestDocHl")
  expect.equality(type(doc), "string")
  expect.equality(doc:find("bold") ~= nil, true)
end

T["highlight_doc()"]["returns link info"] = function()
  vim.api.nvim_set_hl(0, "TestDocLink", { link = "Normal" })
  local doc = docs.highlight_doc("TestDocLink")
  expect.equality(type(doc), "string")
  expect.equality(doc:find("Normal") ~= nil, true)
end

T["highlight_doc()"]["returns nil for empty highlight"] = function()
  docs.clear_cache()
  local doc = docs.highlight_doc("ZZZNonexistentHighlight")
  expect.equality(doc, nil)
end

T["event_doc()"] = new_set()

T["event_doc()"]["returns info for known event"] = function()
  local doc = docs.event_doc("BufEnter")
  if doc then
    expect.equality(type(doc), "string")
  end
end

T["lookup()"] = new_set()

T["lookup()"]["routes option expand to option_doc"] = function()
  docs.clear_cache()
  local doc = docs.lookup("number", "option", "set")
  expect.equality(type(doc), "string")
end

T["lookup()"]["routes help expand to help_doc"] = function()
  docs.clear_cache()
  local doc = docs.lookup("'number'", "help", "help")
  -- May or may not exist
  if doc then
    expect.equality(type(doc), "string")
  end
end

T["lookup()"]["routes highlight expand to highlight_doc"] = function()
  vim.api.nvim_set_hl(0, "TestLookupHl", { fg = "#00ff00" })
  docs.clear_cache()
  local doc = docs.lookup("TestLookupHl", "highlight", "highlight")
  expect.equality(type(doc), "string")
end

T["lookup()"]["returns nil for empty candidate"] = function()
  expect.equality(docs.lookup("", "option", "set"), nil)
  expect.equality(docs.lookup(nil, "option", "set"), nil)
end

T["lookup()"]["returns nil for color expand"] = function()
  expect.equality(docs.lookup("habamax", "color", "colorscheme"), nil)
end

T["clear_cache()"] = new_set()

T["clear_cache()"]["resets cache state"] = function()
  docs.option_doc("number")
  docs.clear_cache()
  -- After clearing, the next call should work fine (re-populate)
  local doc = docs.option_doc("number")
  expect.equality(type(doc), "string")
end

-- ── Chrome component tests ──────────────────────────────────────────

T["docs component"] = new_set()

T["docs component"]["new returns function"] = function()
  local component = require("wildest.renderer.components.docs")
  local fn = component.new()
  expect.equality(type(fn), "function")
end

T["docs component"]["returns nil when no selection"] = function()
  local component = require("wildest.renderer.components.docs")
  local fn = component.new()
  local ctx = {
    selected = -1,
    result = { value = { "test" }, data = { expand = "option" } },
    width = 60,
  }
  expect.equality(fn(ctx), nil)
end

T["docs component"]["returns nil when no result"] = function()
  local component = require("wildest.renderer.components.docs")
  local fn = component.new()
  local ctx = { selected = 0, result = nil, width = 60 }
  expect.equality(fn(ctx), nil)
end

T["docs component"]["returns chunks for option with selection"] = function()
  local component = require("wildest.renderer.components.docs")
  local fn = component.new()
  local ctx = {
    selected = 0,
    result = { value = { "number" }, data = { expand = "option", cmd = "set" } },
    width = 80,
  }
  local result = fn(ctx)
  if result then
    expect.equality(type(result), "table")
    expect.equality(type(result[1][1]), "string")
    expect.equality(type(result[1][2]), "string")
  end
end

T["docs component"]["returns chunks for highlight with selection"] = function()
  vim.api.nvim_set_hl(0, "TestDocsComp", { fg = "#0000ff" })
  local component = require("wildest.renderer.components.docs")
  local fn = component.new()
  local ctx = {
    selected = 0,
    result = { value = { "TestDocsComp" }, data = { expand = "highlight" } },
    width = 80,
  }
  local result = fn(ctx)
  expect.equality(type(result), "table")
  expect.equality(result[1][1]:find("#0000ff") ~= nil, true)
end

T["docs component"]["custom hl group applied"] = function()
  vim.api.nvim_set_hl(0, "TestDocsComp2", { link = "Normal" })
  local component = require("wildest.renderer.components.docs")
  local fn = component.new({ hl = "MyDocsHl" })
  local ctx = {
    selected = 0,
    result = { value = { "TestDocsComp2" }, data = { expand = "highlight" } },
    width = 80,
  }
  local result = fn(ctx)
  expect.equality(result[1][2], "MyDocsHl")
end

return T

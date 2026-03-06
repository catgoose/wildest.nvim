local MiniTest = require("mini.test")
local new_set = MiniTest.new_set
local expect = MiniTest.expect

local T = new_set()

--- Helper: set up config and create a key_hints component
local function make_component(cfg_opts, component_opts)
  local config = require("wildest.config")
  config.setup(cfg_opts)
  local key_hints = require("wildest.renderer.components.key_hints")
  return key_hints.new(component_opts)
end

local function make_ctx(overrides)
  return vim.tbl_extend("force", {
    width = 80,
    selected = 0,
    total = 5,
    page_start = 0,
    page_end = 4,
    result = { value = { "a", "b", "c", "d", "e" } },
  }, overrides or {})
end

T["returns hints for default keys"] = function()
  local comp = make_component({
    next_key = "<Tab>",
    previous_key = "<S-Tab>",
    confirm_key = "<C-y>",
  })
  local result = comp(make_ctx())
  expect.equality(type(result), "table")
  expect.equality(#result, 1)
  local text = result[1][1]
  expect.equality(text:find("Tab:next") ~= nil, true)
  expect.equality(text:find("S%-Tab:prev") ~= nil, true)
  expect.equality(text:find("C%-y:confirm") ~= nil, true)
end

T["includes mark/unmark when configured"] = function()
  local comp = make_component({
    next_key = "<Tab>",
    previous_key = "<S-Tab>",
    mark_key = "<C-Space>",
    unmark_key = "<C-u>",
  })
  local result = comp(make_ctx())
  local text = result[1][1]
  expect.equality(text:find("C%-Space:mark") ~= nil, true)
  expect.equality(text:find("C%-u:unmark") ~= nil, true)
end

T["omits mark/unmark when not configured"] = function()
  local comp = make_component({
    next_key = "<Tab>",
    previous_key = "<S-Tab>",
    mark_key = nil,
    unmark_key = nil,
  })
  local result = comp(make_ctx())
  local text = result[1][1]
  expect.equality(text:find("mark") == nil, true)
end

T["includes actions"] = function()
  local comp = make_component({
    next_key = "<Tab>",
    previous_key = "<S-Tab>",
    actions = {
      ["<C-q>"] = "send_to_quickfix",
      ["<C-s>"] = "open_split",
    },
  })
  local result = comp(make_ctx())
  local text = result[1][1]
  expect.equality(text:find("C%-q:quickfix") ~= nil, true)
  expect.equality(text:find("C%-s:open split") ~= nil, true)
end

T["strips angle brackets from keys"] = function()
  local comp = make_component({
    next_key = "<C-j>",
    previous_key = "<C-k>",
  })
  local result = comp(make_ctx())
  local text = result[1][1]
  expect.equality(text:find("C%-j:next") ~= nil, true)
  expect.equality(text:find("<C%-j>") == nil, true)
end

T["uses first key from array"] = function()
  local comp = make_component({
    next_key = { "<C-j>", "<C-n>" },
    previous_key = { "<C-k>", "<C-p>" },
    accept_key = "<C-a>",
  })
  local result = comp(make_ctx())
  local text = result[1][1]
  expect.equality(text:find("C%-j:next") ~= nil, true)
  -- Second key should not appear
  expect.equality(text:find("C%-n") == nil, true)
end

T["custom separator"] = function()
  local comp = make_component({
    next_key = "<Tab>",
    previous_key = "<S-Tab>",
  }, { separator = " | " })
  local result = comp(make_ctx())
  local text = result[1][1]
  expect.equality(text:find(" | ") ~= nil, true)
end

T["custom labels"] = function()
  local comp = make_component({
    next_key = "<Tab>",
    mark_key = "<C-Space>",
  }, { keys = { next_key = "fwd", mark_key = "sel" } })
  local result = comp(make_ctx())
  local text = result[1][1]
  expect.equality(text:find("Tab:fwd") ~= nil, true)
  expect.equality(text:find("C%-Space:sel") ~= nil, true)
end

T["truncates to width"] = function()
  local comp = make_component({
    next_key = "<Tab>",
    previous_key = "<S-Tab>",
    accept_key = "<Down>",
    confirm_key = "<C-y>",
    mark_key = "<C-Space>",
    unmark_key = "<C-u>",
    actions = {
      ["<C-q>"] = "send_to_quickfix",
      ["<C-s>"] = "open_split",
      ["<C-v>"] = "open_vsplit",
      ["<C-t>"] = "open_tab",
    },
  })
  local result = comp(make_ctx({ width = 30 }))
  local text = result[1][1]
  expect.equality(vim.api.nvim_strwidth(text) <= 30, true)
  expect.equality(text:sub(-3) == "...", true)
end

T["uses WildestKeyHints highlight"] = function()
  local comp = make_component({ next_key = "<Tab>" })
  local result = comp(make_ctx())
  expect.equality(result[1][2], "WildestKeyHints")
end

T["custom highlight"] = function()
  local comp = make_component({ next_key = "<Tab>" }, { hl = "Comment" })
  local result = comp(make_ctx())
  expect.equality(result[1][2], "Comment")
end

return T

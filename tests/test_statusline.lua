local MiniTest = require("mini.test")
local new_set = MiniTest.new_set
local expect = MiniTest.expect

local T = new_set()

local function make_component(cfg_opts, component_opts)
  local config = require("wildest.config")
  config.setup(cfg_opts or {})
  local statusline = require("wildest.renderer.components.statusline")
  return statusline.new(component_opts)
end

local function make_ctx(overrides)
  return vim.tbl_extend("force", {
    width = 120,
    selected = 3,
    total = 42,
    page_start = 0,
    page_end = 15,
    result = { value = {}, data = {} },
    marked = {},
    session_id = 1,
  }, overrides or {})
end

local function chunks_to_text(chunks)
  local parts = {}
  for _, c in ipairs(chunks) do
    parts[#parts + 1] = c[1]
  end
  return table.concat(parts)
end

T["shows match count"] = function()
  local comp = make_component({}, { sections = { "matches" } })
  local result = comp(make_ctx({ total = 42 }))
  expect.equality(type(result), "table")
  local text = chunks_to_text(result)
  expect.equality(text:find("42") ~= nil, true)
end

T["shows no matches"] = function()
  local comp = make_component({}, { sections = { "matches" } })
  local result = comp(make_ctx({ total = 0 }))
  local text = chunks_to_text(result)
  expect.equality(text:find("no matches") ~= nil, true)
end

T["shows position"] = function()
  local comp = make_component({}, { sections = { "position" } })
  local result = comp(make_ctx({ selected = 5, total = 42 }))
  local text = chunks_to_text(result)
  -- 1-indexed: selected 5 → display "6"
  expect.equality(text:find("6") ~= nil, true)
  expect.equality(text:find("42") ~= nil, true)
end

T["hides position when nothing selected"] = function()
  local comp = make_component({}, { sections = { "position" } })
  local result = comp(make_ctx({ selected = -1 }))
  expect.equality(result, nil)
end

T["shows page info"] = function()
  local comp = make_component({}, { sections = { "page" } })
  local result = comp(make_ctx({ total = 100, page_start = 16, page_end = 31 }))
  local text = chunks_to_text(result)
  expect.equality(text:find("pg") ~= nil, true)
  expect.equality(text:find("2") ~= nil, true)
end

T["hides page when single page"] = function()
  local comp = make_component({}, { sections = { "page" } })
  local result = comp(make_ctx({ total = 5, page_start = 0, page_end = 4 }))
  expect.equality(result, nil)
end

T["shows scroll percentage"] = function()
  local comp = make_component({}, { sections = { "scroll" } })
  local result = comp(make_ctx({ total = 100, page_start = 50, page_end = 65 }))
  local text = chunks_to_text(result)
  expect.equality(text:find("%%") ~= nil, true) -- %% is Lua pattern escape for literal %
end

T["hides scroll when all fit"] = function()
  local comp = make_component({}, { sections = { "scroll" } })
  local result = comp(make_ctx({ total = 10, page_start = 0, page_end = 9 }))
  expect.equality(result, nil)
end

T["shows marked count"] = function()
  local comp = make_component({}, { sections = { "marked" } })
  local result = comp(make_ctx({ marked = { [0] = true, [2] = true, [5] = true } }))
  local text = chunks_to_text(result)
  expect.equality(text:find("3") ~= nil, true)
  expect.equality(text:find("marked") ~= nil, true)
end

T["hides marked when none"] = function()
  local comp = make_component({}, { sections = { "marked" } })
  local result = comp(make_ctx({ marked = {} }))
  expect.equality(result, nil)
end

T["shows route from expand"] = function()
  local comp = make_component({}, { sections = { "route" } })
  local result = comp(make_ctx({ result = { value = {}, data = { expand = "help" } } }))
  local text = chunks_to_text(result)
  expect.equality(text:find("help") ~= nil, true)
end

T["shows route from data.route"] = function()
  local comp = make_component({}, { sections = { "route" } })
  local result = comp(make_ctx({ result = { value = {}, data = { route = "custom" } } }))
  local text = chunks_to_text(result)
  expect.equality(text:find("custom") ~= nil, true)
end

T["shows input length"] = function()
  local comp = make_component({}, { sections = { "input" } })
  local result = comp(make_ctx({ result = { value = {}, data = { input = "hello" } } }))
  local text = chunks_to_text(result)
  expect.equality(text:find("5") ~= nil, true)
  expect.equality(text:find("chars") ~= nil, true)
end

T["hides input when empty"] = function()
  local comp = make_component({}, { sections = { "input" } })
  local result = comp(make_ctx({ result = { value = {}, data = { input = "" } } }))
  expect.equality(result, nil)
end

T["shows density bar"] = function()
  local comp = make_component({}, { sections = { "density" } })
  local result = comp(make_ctx({ total = 100, page_start = 0, page_end = 15 }))
  local text = chunks_to_text(result)
  expect.equality(text:find("█") ~= nil, true)
  expect.equality(text:find("░") ~= nil, true)
end

T["hides density when all fit"] = function()
  local comp = make_component({}, { sections = { "density" } })
  local result = comp(make_ctx({ total = 5, page_start = 0, page_end = 4 }))
  expect.equality(result, nil)
end

T["shows time"] = function()
  local comp = make_component({}, { sections = { "time" } })
  local result = comp(make_ctx())
  local text = chunks_to_text(result)
  -- Should have HH:MM format
  expect.equality(text:find("%d%d:%d%d") ~= nil, true)
end

T["multiple sections combined"] = function()
  local comp = make_component({}, { sections = { "matches", "page", "position" } })
  local result = comp(make_ctx({ total = 100, page_start = 0, page_end = 15, selected = 3 }))
  local text = chunks_to_text(result)
  expect.equality(text:find("100") ~= nil, true)
  expect.equality(text:find("pg") ~= nil, true)
  expect.equality(text:find("4/100") ~= nil, true)
end

T["wraps to multiple rows when too wide"] = function()
  local comp = make_component({
    mark_key = "<Tab>",
    actions = { ["<C-q>"] = "send_to_quickfix" },
  }, {
    sections = { "route", "matches", "page", "position", "marked", "scroll", "keys" },
  })
  local result = comp(make_ctx({
    width = 25,
    total = 9999,
    page_start = 0,
    page_end = 15,
    marked = { [0] = true, [1] = true },
  }))
  local text = chunks_to_text(result)
  -- Should contain newlines for wrapping
  expect.equality(text:find("\n") ~= nil, true)
  -- Each row should fit within width
  for line in text:gmatch("[^\n]+") do
    expect.equality(vim.api.nvim_strwidth(line) <= 25, true)
  end
end

T["uses correct highlight groups"] = function()
  local comp = make_component({}, { sections = { "matches" } })
  local result = comp(make_ctx({ total = 10 }))
  local has_accent = false
  for _, c in ipairs(result) do
    if c[2] == "WildestStatuslineAccent" then
      has_accent = true
    end
  end
  expect.equality(has_accent, true)
end

T["marked uses hot highlight"] = function()
  local comp = make_component({}, { sections = { "marked" } })
  local result = comp(make_ctx({ marked = { [0] = true } }))
  local has_hot = false
  for _, c in ipairs(result) do
    if c[2] == "WildestStatuslineHot" then
      has_hot = true
    end
  end
  expect.equality(has_hot, true)
end

T["keys section shows configured keys"] = function()
  local comp = make_component({
    mark_key = "<Tab>",
    confirm_key = "<C-y>",
  }, { sections = { "keys" } })
  local result = comp(make_ctx())
  local text = chunks_to_text(result)
  expect.equality(text:find("Tab:mark") ~= nil, true)
  expect.equality(text:find("C%-y:ok") ~= nil, true)
end

-- Grouped alignment tests

T["grouped: left/right alignment"] = function()
  local comp = make_component({}, {
    left = { "matches" },
    right = { "time" },
  })
  local result = comp(make_ctx({ total = 42, width = 60 }))
  expect.equality(type(result), "table")
  local text = chunks_to_text(result)
  -- Left has matches, right has time
  expect.equality(text:find("42") ~= nil, true)
  expect.equality(text:find("%d%d:%d%d") ~= nil, true)
  -- Should have spacing between them (not just separator)
  expect.equality(#text > 10, true)
end

T["grouped: left/center/right alignment"] = function()
  local comp = make_component({}, {
    left = { "route" },
    center = { "position" },
    right = { "time" },
  })
  local result = comp(make_ctx({
    total = 42,
    selected = 3,
    width = 60,
    result = { value = {}, data = { expand = "help" } },
  }))
  local text = chunks_to_text(result)
  expect.equality(text:find("help") ~= nil, true)
  expect.equality(text:find("4/42") ~= nil, true)
  expect.equality(text:find("%d%d:%d%d") ~= nil, true)
end

T["grouped: center is roughly centered"] = function()
  local comp = make_component({}, {
    left = { "matches" },
    center = { "position" },
    right = { "matches" },
  })
  local result = comp(make_ctx({ total = 10, selected = 3, width = 60 }))
  local text = chunks_to_text(result)
  -- Find where the position bracket starts
  local pos_start = text:find("%[")
  -- It should be roughly in the middle (within a few chars)
  local mid = math.floor(#text / 2)
  expect.equality(math.abs(pos_start - mid) < 10, true)
end

T["grouped: empty groups return nil"] = function()
  local comp = make_component({}, {
    left = { "position" },
    right = { "marked" },
  })
  -- position hidden (selected=-1), marked hidden (empty)
  local result = comp(make_ctx({ selected = -1, marked = {} }))
  expect.equality(result, nil)
end

T["grouped: only left group"] = function()
  local comp = make_component({}, {
    left = { "matches" },
  })
  local result = comp(make_ctx({ total = 42 }))
  expect.equality(type(result), "table")
  local text = chunks_to_text(result)
  expect.equality(text:find("42") ~= nil, true)
end

T["grouped: only right group"] = function()
  local comp = make_component({}, {
    right = { "time" },
  })
  local result = comp(make_ctx())
  expect.equality(type(result), "table")
  local text = chunks_to_text(result)
  expect.equality(text:find("%d%d:%d%d") ~= nil, true)
end

T["frecency_score: hidden when nothing selected"] = function()
  local comp = make_component({}, { sections = { "frecency_score" } })
  local result = comp(make_ctx({ selected = -1 }))
  expect.equality(result, nil)
end

T["frecency_score: hidden when no candidate"] = function()
  local comp = make_component({}, { sections = { "frecency_score" } })
  local result = comp(make_ctx({ selected = 5, result = { value = {}, data = {} } }))
  expect.equality(result, nil)
end

T["grouped: backward compat with sections"] = function()
  local comp = make_component({}, { sections = { "matches", "position" } })
  local result = comp(make_ctx({ total = 42, selected = 3 }))
  local text = chunks_to_text(result)
  expect.equality(text:find("42") ~= nil, true)
  expect.equality(text:find("4/42") ~= nil, true)
end

T["default: uses grouped alignment"] = function()
  local comp = make_component({}, {})
  local result = comp(make_ctx({
    total = 100,
    selected = 3,
    page_start = 0,
    page_end = 15,
    width = 80,
    result = { value = {}, data = { expand = "help" } },
  }))
  expect.equality(type(result), "table")
  local text = chunks_to_text(result)
  -- Default left has route + matches
  expect.equality(text:find("help") ~= nil, true)
  expect.equality(text:find("100") ~= nil, true)
  -- Default center has position + page
  expect.equality(text:find("4/100") ~= nil, true)
  expect.equality(text:find("pg") ~= nil, true)
  -- Default right has time
  expect.equality(text:find("%d%d:%d%d") ~= nil, true)
end

return T

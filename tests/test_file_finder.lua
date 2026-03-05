local MiniTest = require("mini.test")
local new_set = MiniTest.new_set
local expect = MiniTest.expect

local T = new_set()

-- ── file_finder_pipeline ─────────────────────────────────────────────

local file_finder = require("wildest.file_finder")

T["file_finder_pipeline()"] = new_set()

T["file_finder_pipeline()"]["returns a pipeline table"] = function()
  local pipeline = file_finder.file_finder_pipeline()
  expect.equality(type(pipeline), "table")
  expect.equality(#pipeline >= 3, true) -- finder + fuzzy filter + result wrapper
end

T["file_finder_pipeline()"]["accepts opts"] = function()
  local pipeline = file_finder.file_finder_pipeline({
    max_results = 100,
    cwd = "/tmp",
  })
  expect.equality(type(pipeline), "table")
end

T["file_finder_pipeline()"]["accepts custom file_command"] = function()
  local pipeline = file_finder.file_finder_pipeline({
    file_command = { "echo", "test.lua" },
  })
  expect.equality(type(pipeline), "table")
end

T["file_finder_pipeline()"]["finder rejects non-colon cmdtype"] = function()
  local pipeline = file_finder.file_finder_pipeline()
  local finder = pipeline[1]
  local ctx = { cmdtype = "/" }
  local result = finder(ctx, "e test")
  expect.equality(result, false)
end

T["file_finder_pipeline()"]["finder rejects empty input"] = function()
  local pipeline = file_finder.file_finder_pipeline()
  local finder = pipeline[1]
  local ctx = { cmdtype = ":" }
  expect.equality(finder(ctx, ""), false)
  expect.equality(finder(ctx, nil), false)
end

T["file_finder_pipeline()"]["result wrapper sets expand and cmd"] = function()
  local pipeline = file_finder.file_finder_pipeline()
  -- The result wrapper is the last step
  local result_step = pipeline[#pipeline]
  local ctx = {
    input = "e test.lua",
    arg = "test.lua",
    cmd = "edit",
    expand = "file",
  }
  local result = result_step(ctx, { "test.lua", "tests/test.lua" })
  expect.equality(type(result), "table")
  expect.equality(result.data.expand, "file")
  expect.equality(result.data.cmd, "edit")
  expect.equality(result.data.arg, "test.lua")
  expect.equality(#result.value, 2)
end

T["file_finder_pipeline()"]["result wrapper returns false for empty files"] = function()
  local pipeline = file_finder.file_finder_pipeline()
  local result_step = pipeline[#pipeline]
  local ctx = { input = "e x", arg = "x", cmd = "edit", expand = "file" }
  expect.equality(result_step(ctx, {}), false)
end

T["file_finder_pipeline()"]["result wrapper output replaces arg portion"] = function()
  local pipeline = file_finder.file_finder_pipeline()
  local result_step = pipeline[#pipeline]
  local ctx = { input = "e te", arg = "te", cmd = "edit", expand = "file" }
  local result = result_step(ctx, { "test.lua" })
  local output = result.output(result.data, "test.lua")
  expect.equality(output, "e test.lua")
end

T["file_finder_pipeline()"]["result wrapper sets query for path files"] = function()
  local pipeline = file_finder.file_finder_pipeline()
  local result_step = pipeline[#pipeline]
  local ctx = {
    input = "e lua/wildest/init",
    arg = "lua/wildest/init",
    cmd = "edit",
    expand = "file",
  }
  local result = result_step(ctx, { "lua/wildest/init.lua" })
  expect.equality(result.data.query, "init")
end

T["file_finder_pipeline()"]["cancel is safe when no job"] = function()
  -- Should not error
  file_finder.cancel()
end

-- ── cmdline_pipeline file_finder integration ─────────────────────────

T["cmdline_pipeline file_finder"] = new_set()

T["cmdline_pipeline file_finder"]["returns pipeline when file_finder=true"] = function()
  local cmdline = require("wildest.cmdline")
  local pipeline = cmdline.cmdline_pipeline({ file_finder = true })
  expect.equality(type(pipeline), "table")
  -- Should be a branch (single step wrapping file_finder + sync)
  expect.equality(#pipeline, 1)
  expect.equality(type(pipeline[1]), "function")
end

T["cmdline_pipeline file_finder"]["returns pipeline when file_finder=table"] = function()
  local cmdline = require("wildest.cmdline")
  local pipeline = cmdline.cmdline_pipeline({
    file_finder = { max_results = 500 },
    fuzzy = true,
  })
  expect.equality(type(pipeline), "table")
  expect.equality(#pipeline, 1)
end

-- ── engine option ────────────────────────────────────────────────────

T["engine option"] = new_set()

T["engine option"]["cmdline engine=fast enables file_finder branch"] = function()
  local cmdline = require("wildest.cmdline")
  local pipeline = cmdline.cmdline_pipeline({ engine = "fast" })
  expect.equality(type(pipeline), "table")
  expect.equality(#pipeline, 1)
  expect.equality(type(pipeline[1]), "function")
end

T["engine option"]["cmdline engine=vim returns normal pipeline"] = function()
  local cmdline = require("wildest.cmdline")
  local pipeline = cmdline.cmdline_pipeline({ engine = "vim" })
  expect.equality(type(pipeline), "table")
  expect.equality(#pipeline > 1, true) -- multiple steps, not a single branch
end

T["engine option"]["cmdline engine=nil returns normal pipeline"] = function()
  local cmdline = require("wildest.cmdline")
  local pipeline = cmdline.cmdline_pipeline({})
  expect.equality(type(pipeline), "table")
  expect.equality(#pipeline > 1, true)
end

T["engine option"]["cmdline engine table with files=true enables file_finder"] = function()
  local cmdline = require("wildest.cmdline")
  local pipeline = cmdline.cmdline_pipeline({ engine = { files = true } })
  expect.equality(#pipeline, 1)
  expect.equality(type(pipeline[1]), "function")
end

T["engine option"]["cmdline engine table with files=table passes opts"] = function()
  local cmdline = require("wildest.cmdline")
  local pipeline = cmdline.cmdline_pipeline({ engine = { files = { max_results = 100 } } })
  expect.equality(#pipeline, 1)
end

T["engine option"]["cmdline engine table without files returns normal"] = function()
  local cmdline = require("wildest.cmdline")
  local pipeline = cmdline.cmdline_pipeline({ engine = { shell = true } })
  expect.equality(#pipeline > 1, true)
end

T["engine option"]["cmdline legacy file_finder still works"] = function()
  local cmdline = require("wildest.cmdline")
  local pipeline = cmdline.cmdline_pipeline({ file_finder = true })
  expect.equality(#pipeline, 1)
end

T["engine option"]["cmdline file_finder overrides engine"] = function()
  local cmdline = require("wildest.cmdline")
  -- file_finder=false should disable even if engine=fast
  local pipeline = cmdline.cmdline_pipeline({ file_finder = false, engine = "fast" })
  expect.equality(#pipeline > 1, true)
end

T["engine option"]["help engine=fast enables cache"] = function()
  local help_mod = require("wildest.pipeline.help")
  -- Just verify it builds without error
  local pipeline = help_mod.help_pipeline({ engine = "fast" })
  expect.equality(type(pipeline), "table")
  expect.equality(#pipeline >= 1, true)
end

T["engine option"]["help engine table with help=true enables cache"] = function()
  local help_mod = require("wildest.pipeline.help")
  local pipeline = help_mod.help_pipeline({ engine = { help = true } })
  expect.equality(type(pipeline), "table")
end

T["engine option"]["shell engine=fast enables exec_cache"] = function()
  local shell_mod = require("wildest.shell")
  local pipeline = shell_mod.shell_pipeline({ engine = "fast" })
  expect.equality(type(pipeline), "table")
  expect.equality(#pipeline >= 1, true)
end

T["engine option"]["shell engine table with shell=true enables exec_cache"] = function()
  local shell_mod = require("wildest.shell")
  local pipeline = shell_mod.shell_pipeline({ engine = { shell = true } })
  expect.equality(type(pipeline), "table")
end

-- ── exec_cache ───────────────────────────────────────────────────────

T["exec_cache"] = new_set()

local exec_cache = require("wildest.shell.exec_cache")

T["exec_cache"]["get returns a table"] = function()
  exec_cache.clear()
  local result = exec_cache.get()
  expect.equality(type(result), "table")
end

T["exec_cache"]["get returns sorted executables"] = function()
  exec_cache.clear()
  local result = exec_cache.get()
  -- Should have common executables
  expect.equality(#result > 0, true)
  -- Should be sorted
  for i = 2, #result do
    expect.equality(result[i - 1] <= result[i], true)
  end
end

T["exec_cache"]["filter returns matching executables"] = function()
  exec_cache.clear()
  local result = exec_cache.filter("ls")
  expect.equality(type(result), "table")
  -- ls should be available on any system
  local found = false
  for _, name in ipairs(result) do
    if name == "ls" then
      found = true
    end
  end
  expect.equality(found, true)
end

T["exec_cache"]["filter returns empty for nonsense prefix"] = function()
  exec_cache.clear()
  local result = exec_cache.filter("zzz_nonexistent_cmd_zzz")
  expect.equality(type(result), "table")
  expect.equality(#result, 0)
end

T["exec_cache"]["clear resets cache"] = function()
  exec_cache.get() -- populate
  exec_cache.clear()
  -- After clear, next get should re-scan
  local result = exec_cache.get()
  expect.equality(type(result), "table")
  expect.equality(#result > 0, true)
end

T["exec_cache"]["caches results across calls"] = function()
  exec_cache.clear()
  local r1 = exec_cache.get()
  local r2 = exec_cache.get()
  -- Same reference (cached)
  expect.equality(r1, r2)
end

-- ── help_cache ───────────────────────────────────────────────────────

T["help_cache"] = new_set()

local help_cache = require("wildest.pipeline.help_cache")

T["help_cache"]["get returns a table"] = function()
  help_cache.clear()
  local result = help_cache.get()
  expect.equality(type(result), "table")
end

T["help_cache"]["filter returns matching tags"] = function()
  help_cache.clear()
  local result = help_cache.filter("help")
  expect.equality(type(result), "table")
  -- "help" should match in any environment
  expect.equality(#result > 0, true)
end

T["help_cache"]["filter returns empty for nonsense"] = function()
  help_cache.clear()
  local result = help_cache.filter("zzz_nonexistent_tag_zzz")
  expect.equality(type(result), "table")
  expect.equality(#result, 0)
end

T["help_cache"]["preload populates cache"] = function()
  help_cache.clear()
  help_cache.preload()
  local result = help_cache.get()
  expect.equality(#result > 0, true)
end

T["help_cache"]["caches results across calls"] = function()
  help_cache.clear()
  local r1 = help_cache.get()
  local r2 = help_cache.get()
  expect.equality(r1, r2)
end

return T

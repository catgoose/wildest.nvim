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

-- ── engine resolver ──────────────────────────────────────────────────

T["engine resolver"] = new_set()

local engine_mod = require("wildest.engine")

T["engine resolver"]["resolve true returns auto"] = function()
  local kind, val = engine_mod.resolve(true)
  expect.equality(kind, "auto")
  expect.equality(type(val), "table")
end

T["engine resolver"]["resolve false returns disabled"] = function()
  local kind = engine_mod.resolve(false)
  expect.equality(kind, "disabled")
end

T["engine resolver"]["resolve nil returns disabled"] = function()
  local kind = engine_mod.resolve(nil)
  expect.equality(kind, "disabled")
end

T["engine resolver"]["resolve string array returns command"] = function()
  local kind, val = engine_mod.resolve({ "fd", "-tf", "--hidden" })
  expect.equality(kind, "command")
  expect.equality(val[1], "fd")
  expect.equality(val[3], "--hidden")
end

T["engine resolver"]["resolve table with named keys returns opts"] = function()
  local kind, val = engine_mod.resolve({ command = { "fd" }, max_results = 100 })
  expect.equality(kind, "opts")
  expect.equality(val.max_results, 100)
end

T["engine resolver"]["resolve function returns function"] = function()
  local fn = function() end
  local kind, val = engine_mod.resolve(fn)
  expect.equality(kind, "function")
  expect.equality(val, fn)
end

T["engine resolver"]["to_file_finder_opts true returns empty table"] = function()
  local opts = engine_mod.to_file_finder_opts(true)
  expect.equality(type(opts), "table")
  expect.equality(next(opts), nil)
end

T["engine resolver"]["to_file_finder_opts command array maps to file_command"] = function()
  local opts = engine_mod.to_file_finder_opts({ "fd", "-tf", "--hidden" })
  expect.equality(type(opts), "table")
  expect.equality(opts.file_command[1], "fd")
  expect.equality(opts.file_command[3], "--hidden")
end

T["engine resolver"]["to_file_finder_opts function maps to file_command"] = function()
  local fn = function() end
  local opts = engine_mod.to_file_finder_opts(fn)
  expect.equality(opts.file_command, fn)
end

T["engine resolver"]["to_file_finder_opts opts table passes through"] = function()
  local opts = engine_mod.to_file_finder_opts({ max_results = 500, cwd = "/tmp" })
  expect.equality(opts.max_results, 500)
  expect.equality(opts.cwd, "/tmp")
end

T["engine resolver"]["to_exec_cache_opts command array maps to command"] = function()
  local opts = engine_mod.to_exec_cache_opts({ "bash", "-c", "compgen -c" })
  expect.equality(opts.command[1], "bash")
end

T["engine resolver"]["to_help_cache_opts function maps to command"] = function()
  local fn = function() end
  local opts = engine_mod.to_help_cache_opts(fn)
  expect.equality(opts.command, fn)
end

-- ── engine custom commands ──────────────────────────────────────────

T["engine custom commands"] = new_set()

T["engine custom commands"]["cmdline engine files with command array creates branch"] = function()
  local cmdline = require("wildest.cmdline")
  local pipeline = cmdline.cmdline_pipeline({
    engine = { files = { "fd", "-tf", "--hidden" } },
  })
  expect.equality(#pipeline, 1) -- branch
  expect.equality(type(pipeline[1]), "function")
end

T["engine custom commands"]["cmdline engine files with function creates branch"] = function()
  local cmdline = require("wildest.cmdline")
  local pipeline = cmdline.cmdline_pipeline({
    engine = {
      files = function()
        return { "echo", "test.lua" }
      end,
    },
  })
  expect.equality(#pipeline, 1)
end

T["engine custom commands"]["exec_cache configure accepts custom command"] = function()
  local ec = require("wildest.shell.exec_cache")
  ec.clear()
  ec.configure({ command = { "echo", "mycmd" } })
  local result = ec.get()
  expect.equality(type(result), "table")
  -- Should contain "mycmd" from echo output
  local found = false
  for _, name in ipairs(result) do
    if name == "mycmd" then
      found = true
    end
  end
  expect.equality(found, true)
  -- Clean up
  ec.configure({ command = nil })
  ec.clear()
end

T["engine custom commands"]["exec_cache configure accepts function"] = function()
  local ec = require("wildest.shell.exec_cache")
  ec.clear()
  ec.configure({
    command = function()
      return { "alpha", "beta", "gamma" }
    end,
  })
  local result = ec.get()
  expect.equality(#result, 3)
  expect.equality(result[1], "alpha")
  expect.equality(result[2], "beta")
  expect.equality(result[3], "gamma")
  -- Clean up
  ec.configure({ command = nil })
  ec.clear()
end

T["engine custom commands"]["help_cache configure accepts custom command"] = function()
  local hc = require("wildest.pipeline.help_cache")
  hc.clear()
  hc.configure({ command = { "echo", "custom-tag" } })
  local result = hc.get()
  expect.equality(type(result), "table")
  local found = false
  for _, tag in ipairs(result) do
    if tag == "custom-tag" then
      found = true
    end
  end
  expect.equality(found, true)
  -- Clean up
  hc.configure({ command = nil })
  hc.clear()
end

T["engine custom commands"]["help_cache configure accepts function"] = function()
  local hc = require("wildest.pipeline.help_cache")
  hc.clear()
  hc.configure({
    command = function()
      return { "tag-one", "tag-two" }
    end,
  })
  local result = hc.get()
  expect.equality(#result, 2)
  expect.equality(result[1], "tag-one")
  -- Clean up
  hc.configure({ command = nil })
  hc.clear()
end

T["engine custom commands"]["shell engine with custom command builds pipeline"] = function()
  local shell_mod = require("wildest.shell")
  local pipeline = shell_mod.shell_pipeline({
    engine = { shell = { "bash", "-c", "compgen -c" } },
  })
  expect.equality(type(pipeline), "table")
  expect.equality(#pipeline >= 1, true)
  -- Clean up exec_cache
  require("wildest.shell.exec_cache").configure({ command = nil })
  require("wildest.shell.exec_cache").clear()
end

T["engine custom commands"]["help engine with custom command builds pipeline"] = function()
  local help_mod = require("wildest.pipeline.help")
  local pipeline = help_mod.help_pipeline({
    engine = { help = { "echo", "my-help-tag" } },
  })
  expect.equality(type(pipeline), "table")
  -- Clean up help_cache
  require("wildest.pipeline.help_cache").configure({ command = nil })
  require("wildest.pipeline.help_cache").clear()
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

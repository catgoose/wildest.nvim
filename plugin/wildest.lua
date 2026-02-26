if vim.g.loaded_wildest then
  return
end
vim.g.loaded_wildest = true

-- Theme compilation commands
vim.api.nvim_create_user_command("WildestCompile", function(args)
  local name = args.args
  if name == "" then
    require("wildest.themes").compile_all()
  else
    require("wildest.themes").compile(name)
  end
end, {
  nargs = "?",
  complete = function()
    return require("wildest.themes").theme_names
  end,
  desc = "Compile wildest theme(s) to bytecode. No args = compile all.",
})

vim.api.nvim_create_user_command("WildestClearCache", function()
  require("wildest.themes").clear_cache()
end, { desc = "Clear compiled wildest theme cache" })

-- Log viewer command
vim.api.nvim_create_user_command("WildestLog", function(args)
  local log = require("wildest.log")
  local subcmd = args.args

  if subcmd == "clear" then
    log.clear()
    vim.notify("[wildest] Log cleared", vim.log.levels.INFO)
    return
  end

  if subcmd == "path" then
    vim.notify(log.path(), vim.log.levels.INFO)
    return
  end

  -- Default: open log file in a split
  local path = log.path()
  log.flush()
  vim.cmd("split " .. vim.fn.fnameescape(path))
end, {
  nargs = "?",
  complete = function()
    return { "clear", "path" }
  end,
  desc = "View or manage wildest log. Subcommands: clear, path",
})

-- Profiler command
vim.api.nvim_create_user_command("WildestProfile", function(args)
  local profiler = require("wildest.profiler")
  local subcmd = args.args

  if subcmd == "start" then
    profiler.enable()
    vim.notify("[wildest] Profiling enabled", vim.log.levels.INFO)
  elseif subcmd == "stop" then
    profiler.disable()
    vim.notify("[wildest] Profiling disabled", vim.log.levels.INFO)
  elseif subcmd == "clear" then
    profiler.clear()
    vim.notify("[wildest] Profile data cleared", vim.log.levels.INFO)
  else
    -- Default: show profile data
    print(profiler.format())
  end
end, {
  nargs = "?",
  complete = function()
    return { "start", "stop", "clear" }
  end,
  desc = "Pipeline profiler. Subcommands: start, stop, clear",
})

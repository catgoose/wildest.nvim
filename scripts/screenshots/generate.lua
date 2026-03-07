-- Generate wildest.nvim screenshots using Charmbracelet VHS
--
-- Usage:
--   nvim --headless -l scripts/screenshots/generate.lua                  # Generate all screenshots
--   nvim --headless -l scripts/screenshots/generate.lua theme_saloon     # Generate a single screenshot
--   nvim --headless -l scripts/screenshots/generate.lua --list           # List available configs
--   nvim --headless -l scripts/screenshots/generate.lua --themes         # Generate theme screenshots only
--   nvim --headless -l scripts/screenshots/generate.lua --renderers      # Generate renderer screenshots only
--   nvim --headless -l scripts/screenshots/generate.lua --features       # Generate feature screenshots only
--   nvim --headless -l scripts/screenshots/generate.lua --pipelines      # Generate pipeline screenshots only
--   nvim --headless -l scripts/screenshots/generate.lua --layouts        # Generate layout screenshots only
--   nvim --headless -l scripts/screenshots/generate.lua --options        # Generate renderer option screenshots only
--   nvim --headless -l scripts/screenshots/generate.lua --gifs           # Also generate animated GIFs
--   nvim --headless -l scripts/screenshots/generate.lua --showdown       # Generate the animated showdown GIF only
--   nvim --headless -l scripts/screenshots/generate.lua --gunsmoke       # Generate the animated gunsmoke GIF only
--   nvim --headless -l scripts/screenshots/generate.lua -j4              # Run 4 screenshots in parallel
--   nvim --headless -l scripts/screenshots/generate.lua --install-deps   # Install VHS, ttyd, and Nerd Font (for CI)
--
-- Requirements:
--   - VHS: https://github.com/charmbracelet/vhs
--   - Neovim (nightly)
--   - fuzzy.so must be built: make -C csrc
--
-- Optional:
--   - nvim-web-devicons (auto-cloned to deps/ if missing)

local uv = vim.uv

-- ── Paths ────────────────────────────────────────────────────────

local script_dir = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h")
local root_dir = vim.fn.fnamemodify(script_dir .. "/../..", ":p"):gsub("/$", "")
local output_dir = script_dir .. "/output"
local init_lua = script_dir .. "/init.lua"
local gif_init_lua = script_dir .. "/gif_init.lua"

-- ── Load configs ─────────────────────────────────────────────────

local configs_mod = dofile(script_dir .. "/configs.lua")

-- ── Settings ─────────────────────────────────────────────────────

local settings = {
  width = 1200,
  height = 600,
  font_size = 14,
  font_family = "JetBrainsMono Nerd Font",
  padding = 20,
  theme = "Catppuccin Mocha",
}

-- ── Helpers ──────────────────────────────────────────────────────

local function printf(fmt, ...)
  io.write(string.format(fmt, ...) .. "\n")
  io.flush()
end

local function get_cmd(config_name)
  local cfg = configs_mod.configs[config_name]
  if cfg and cfg.cmd then
    return cfg.cmd
  end
  return configs_mod.default_cmd
end

local function file_exists(path)
  return uv.fs_stat(path) ~= nil
end

local function file_size_human(path)
  local stat = uv.fs_stat(path)
  if not stat then
    return "?"
  end
  local bytes = stat.size
  if bytes >= 1048576 then
    return string.format("%.1fM", bytes / 1048576)
  elseif bytes >= 1024 then
    return string.format("%.0fK", bytes / 1024)
  else
    return string.format("%dB", bytes)
  end
end

-- ── Tmpfile helper ───────────────────────────────────────────────

local function write_tmpfile(content)
  local path = os.tmpname() .. ".tape"
  local f = io.open(path, "w")
  f:write(content)
  f:close()
  return path
end

-- ── VHS helpers ──────────────────────────────────────────────────

--- Shared VHS preamble (shell, font, dimensions, theme).
---@param typing_speed string|nil  e.g. "50ms" (default "50ms")
---@return string
local function vhs_preamble(typing_speed)
  typing_speed = typing_speed or "50ms"
  return string.format(
    [[Require nvim

Set Shell "bash"
Set FontSize %d
Set FontFamily "%s"
Set Width %d
Set Height %d
Set Padding %d
Set Theme "%s"
Set TypingSpeed %s]],
    settings.font_size,
    settings.font_family,
    settings.width,
    settings.height,
    settings.padding,
    settings.theme,
    typing_speed
  )
end

-- ── VHS tape generation ──────────────────────────────────────────

local function generate_tape(config_name, generate_gifs)
  local cmd = get_cmd(config_name)
  local mode = cmd:sub(1, 1)
  local typed = cmd:sub(2)
  local nvim_cmd = string.format("WILDEST_CONFIG=%s nvim -u %s -i NONE", config_name, init_lua)

  -- cursor_pos: move cursor left after typing to position it mid-cmdline
  local cfg = configs_mod.configs[config_name]
  local cursor_left = ""
  if cfg and cfg.cursor_pos then
    local total = #typed
    local left_count = total - cfg.cursor_pos + 1
    if left_count > 0 then
      cursor_left = "\nSleep 200ms\n" .. ("Left\n"):rep(left_count):gsub("\n$", "")
    end
  end

  local parts = {}

  if generate_gifs then
    table.insert(parts, string.format('Output "%s/%s.gif"', output_dir, config_name))
    table.insert(parts, "")
  end

  table.insert(
    parts,
    string.format(
      [[%s

Type "%s"
Enter
Sleep 2s

Type "%s"
Sleep 500ms
Type@80ms "%s"%s
Sleep 2s

Screenshot "%s/%s.png"

Escape
Sleep 300ms
Type ":q!"
Enter
Sleep 500ms]],
      vhs_preamble(),
      nvim_cmd,
      mode,
      typed,
      cursor_left,
      output_dir,
      config_name
    )
  )

  return write_tmpfile(table.concat(parts, "\n"))
end

-- ── VHS execution ────────────────────────────────────────────────

--- Run VHS synchronously on a single tape file.
---@return boolean success
local function run_vhs(tape_file)
  local result = vim.fn.system({ "vhs", tape_file })
  return vim.v.shell_error == 0
end

--- Run multiple VHS jobs in parallel using libuv.
---@param jobs table[] list of { config = string, tape = string }
---@param max_concurrent number
---@return table<number, boolean> results indexed by job position
local function run_parallel(jobs, max_concurrent)
  local idx, active = 0, 0
  local results = {}
  local done_count = 0
  local total = #jobs

  local function next_job()
    while active < max_concurrent and idx < total do
      idx = idx + 1
      active = active + 1
      local i = idx
      printf("  Generating: %s", jobs[i].config)
      local handle, pid
      handle, pid = uv.spawn("vhs", {
        args = { jobs[i].tape },
        stdio = { nil, nil, nil },
      }, function(code, signal)
        handle:close()
        results[i] = code == 0
        active = active - 1
        done_count = done_count + 1

        -- Report result
        local config_name = jobs[i].config
        if code == 0 and file_exists(output_dir .. "/" .. config_name .. ".png") then
          printf(
            "    OK: %s.png (%s)",
            config_name,
            file_size_human(output_dir .. "/" .. config_name .. ".png")
          )
        else
          printf("    FAILED: %s", config_name)
        end

        -- Clean up tape
        os.remove(jobs[i].tape)

        next_job()
      end)

      if not handle then
        printf("    FAILED to spawn VHS for %s: %s", jobs[i].config, tostring(pid))
        results[i] = false
        active = active - 1
        done_count = done_count + 1
        os.remove(jobs[i].tape)
      end
    end
  end

  next_job()
  -- Run the event loop until all jobs complete
  while done_count < total do
    uv.run("once")
  end

  return results
end

-- ── Random GIF scene generation ──────────────────────────────────
--
-- Each completion type has a pool of commands to exercise.  Scenes are
-- composed at tape-generation time by randomly picking a type, then a
-- command from that type's pool, with randomised typing speed and
-- linger duration.  This means every GIF generation covers a different
-- combination while still guaranteeing good coverage of all types.

-- Pools of commands grouped by the completion type they exercise.
-- mode = ":" or "/" (which key opens cmdline), typed = text after mode.
local scene_pools = {
  file = {
    -- Directories with many files (13+ matches)
    { mode = ":", typed = "e lua/wildest/renderer/components/" },
    { mode = ":", typed = "e tests/" },
    -- Directories with moderate matches
    { mode = ":", typed = "e lua/wildest/" },
    { mode = ":", typed = "e lua/wildest/renderer/" },
    { mode = ":", typed = "e lua/wildest/pipeline/" },
    { mode = ":", typed = "e scripts/" },
    -- Prefix completions within directories
    { mode = ":", typed = "e tests/test_c" },
    { mode = ":", typed = "e tests/test_h" },
    { mode = ":", typed = "e lua/wildest/renderer/components/s" },
    { mode = ":", typed = "e lua/wildest/renderer/p" },
  },
  option = {
    { mode = ":", typed = "set fold" },
    { mode = ":", typed = "set mouse" },
    { mode = ":", typed = "set tab" },
    { mode = ":", typed = "set sign" },
    { mode = ":", typed = "set number" },
    { mode = ":", typed = "set wrap" },
    { mode = ":", typed = "set scroll" },
    { mode = ":", typed = "set status" },
  },
  help = {
    { mode = ":", typed = "help help-" },
    { mode = ":", typed = "help nvim_b" },
    { mode = ":", typed = "help api-" },
    { mode = ":", typed = "help win" },
    { mode = ":", typed = "help buf" },
    { mode = ":", typed = "help option" },
    { mode = ":", typed = "help map" },
    { mode = ":", typed = "help cmd" },
  },
  lua = {
    { mode = ":", typed = "lua vim.api.nvim" },
    { mode = ":", typed = "lua vim.fn.get" },
    { mode = ":", typed = "lua vim.keymap" },
    { mode = ":", typed = "lua vim.lsp" },
    { mode = ":", typed = "lua vim.api.nvim_buf" },
    { mode = ":", typed = "lua vim.treesitter" },
    { mode = ":", typed = "lua vim.diagnostic" },
    { mode = ":", typed = "lua vim.fs" },
  },
  search = {
    { mode = "/", typed = "function" },
    { mode = "/", typed = "return" },
    { mode = "/", typed = "local" },
    { mode = "/", typed = "require" },
    { mode = "/", typed = "end" },
    { mode = "/", typed = "self" },
    { mode = "/", typed = "table" },
    { mode = "/", typed = "string" },
    { mode = "?", typed = "function" },
    { mode = "?", typed = "return" },
    { mode = "?", typed = "local" },
    { mode = "?", typed = "require" },
  },
}

-- Weighted distribution: file & option are the most common user actions,
-- search and help are frequent, lua is less common but important to test.
local scene_weights = {
  { "file", 25 },
  { "option", 25 },
  { "help", 20 },
  { "lua", 15 },
  { "search", 15 },
}

local scene_weight_total = 0
for _, w in ipairs(scene_weights) do
  scene_weight_total = scene_weight_total + w[2]
end

--- Pick a random completion type respecting weights.
---@return string type key into scene_pools
local function pick_scene_type()
  local roll = math.random(scene_weight_total)
  local acc = 0
  for _, w in ipairs(scene_weights) do
    acc = acc + w[2]
    if roll <= acc then
      return w[1]
    end
  end
  return scene_weights[1][1]
end

--- Build the VHS tape body for n randomly composed scenes.
---@param n number  how many scenes to emit
---@return string   VHS tape fragment (no preamble / postamble)
local function build_scene_tape(n)
  math.randomseed(os.time() + (vim.fn.getpid and vim.fn.getpid() or 0))

  local parts = {}
  for i = 1, n do
    local kind = pick_scene_type()
    local pool = scene_pools[kind]
    local s = pool[math.random(#pool)]
    local speed = math.random(30, 120)

    if i > 1 then
      table.insert(parts, "Ctrl+N")
      table.insert(parts, "Sleep 300ms")
      table.insert(parts, "")
    end
    table.insert(parts, string.format('Type "%s"', s.mode))
    table.insert(parts, "Sleep 300ms")
    table.insert(parts, string.format('Type@%dms "%s"', speed, s.typed))
    table.insert(parts, "Sleep 800ms")

    -- Tab through a few completions to showcase previews updating
    local tab_count = math.random(2, 5)
    for _ = 1, tab_count do
      table.insert(parts, "Tab")
      table.insert(parts, string.format("Sleep %dms", math.random(600, 1200)))
    end

    table.insert(parts, "Escape")
    table.insert(parts, "Sleep 300ms")
    table.insert(parts, "")
  end
  return table.concat(parts, "\n")
end

-- ── Showdown GIF scene generation ────────────────────────────────

local showdown_action_keys = {
  accept = { key = "Enter" },
  open_tab = { key = "Ctrl+T" },
  open_split = { key = "Ctrl+S" },
  open_vsplit = { key = "Ctrl+V" },
  send_to_quickfix = { key = "Ctrl+Q" },
  send_to_loclist = { key = "Ctrl+L" },
  toggle_preview = { key = "Ctrl+P" },
  redirect_output = { key = "Ctrl+R" },
  search_accept = { key = "Enter" },
}

--- Build the VHS tape body for showdown scenes (preview + actions).
---
--- Each scene: dump command instantly → browse several candidates (preview
--- updates on each) → settle on one → execute action → brief result → cleanup.
--- The focus is on preview variety across selections and configs, not the action.
---@param n number  how many scenes to emit
---@param seed number  deterministic seed (shared with configs.lua)
---@return string   VHS tape fragment (no preamble / postamble)
local function build_showdown_tape(n, seed)
  local plan = configs_mod.showdown_scene_plan(n, seed)

  local parts = {}
  for i, entry in ipairs(plan) do
    if i > 1 then
      -- Reset windows/tabs/quickfix/loclist from the previous action
      table.insert(parts, "Hide")
      table.insert(parts, 'Type ":"')
      table.insert(parts, "Sleep 100ms")
      table.insert(parts, 'Type "only | tabonly | cclose | lclose"')
      table.insert(parts, "Enter")
      table.insert(parts, "Sleep 300ms")
      table.insert(parts, "Show")
      -- Cycle to next scene config
      table.insert(parts, "Ctrl+N")
      table.insert(parts, "Sleep 300ms")
      table.insert(parts, "")
    end

    local s = entry.vhs_cmd
    local act = showdown_action_keys[entry.action]

    -- Dump command instantly and let popup + preview appear
    table.insert(parts, string.format('Type "%s"', s.mode))
    table.insert(parts, "Sleep 200ms")
    table.insert(parts, string.format('Type@1ms "%s"', s.typed))
    table.insert(parts, "Sleep 1500ms")

    -- Browse through candidates so the viewer sees preview updating
    for _ = 1, entry.browse_count do
      table.insert(parts, "Tab")
      table.insert(parts, "Sleep 1200ms")
    end

    -- Settle on the final selection
    table.insert(parts, "Sleep 800ms")

    -- Execute the action
    if entry.action == "toggle_preview" then
      table.insert(parts, "Ctrl+P")
      table.insert(parts, "Sleep 2000ms")
      table.insert(parts, "Ctrl+P")
      table.insert(parts, "Sleep 1000ms")
      table.insert(parts, "Escape")
      table.insert(parts, "Sleep 300ms")
    elseif entry.action == "search_accept" then
      table.insert(parts, "Enter")
      table.insert(parts, "Sleep 2000ms")
    else
      table.insert(parts, act.key)
      table.insert(parts, "Sleep 2000ms")
    end

    table.insert(parts, "")
  end
  return table.concat(parts, "\n")
end

-- ── Animated GIF generation ──────────────────────────────────────

local function generate_gif(name)
  printf("Generating animated %s GIF...", name)

  local scene_tape
  local seed = os.time() + (vim.fn.getpid and vim.fn.getpid() or 0)
  local env_prefix = ""

  if name == "showdown" then
    scene_tape = build_showdown_tape(25, seed)
    env_prefix = string.format("WILDEST_GIF_SEED=%d ", seed)
  else
    scene_tape = build_scene_tape(25)
  end

  local nvim_cmd =
    string.format("%sWILDEST_GIF_NAME=%s nvim -u %s -i NONE", env_prefix, name, gif_init_lua)
  local tape = string.format(
    [[Output "%s/%s.gif"

%s

Hide
Type "%s"
Enter
Sleep 2s
Show

%s

Hide
Type ":q!"
Enter
Sleep 500ms]],
    output_dir,
    name,
    vhs_preamble("60ms"),
    nvim_cmd,
    scene_tape
  )

  local tape_file = write_tmpfile(tape)

  local ok = run_vhs(tape_file)
  os.remove(tape_file)

  if ok and file_exists(output_dir .. "/" .. name .. ".gif") then
    printf("  OK: %s.gif (%s)", name, file_size_human(output_dir .. "/" .. name .. ".gif"))
  else
    printf("  FAILED: %s.gif", name)
    return false
  end
  return true
end

-- ── CI dependency installer ──────────────────────────────────────

local function install_deps()
  printf("Installing CI dependencies...")

  if os.execute("command -v vhs >/dev/null 2>&1") ~= 0 then
    printf("  Installing VHS and ttyd...")
    os.execute("sudo mkdir -p /etc/apt/keyrings")
    os.execute(
      "curl -fsSL https://repo.charm.sh/apt/gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/charm.gpg"
    )
    os.execute(
      'echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" | sudo tee /etc/apt/sources.list.d/charm.list'
    )
    os.execute("sudo apt-get update")
    os.execute("sudo apt-get install -y vhs ttyd")
  end

  if os.execute('fc-list | grep -qi "JetBrainsMono Nerd Font"') ~= 0 then
    printf("  Installing JetBrainsMono Nerd Font...")
    os.execute("mkdir -p ~/.local/share/fonts")
    os.execute(
      "curl -fsSL https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz | tar -xJf - -C ~/.local/share/fonts"
    )
    os.execute("fc-cache -fv")
  end

  printf("  Dependencies installed.")
end

-- ── Dependency checks ────────────────────────────────────────────

local function check_deps()
  if vim.fn.executable("vhs") ~= 1 then
    printf("Error: VHS is not installed.")
    printf("")
    printf("Install VHS:")
    printf("  go install github.com/charmbracelet/vhs@latest")
    printf("  brew install vhs")
    printf("  nix-env -iA nixpkgs.vhs")
    printf("")
    printf("See: https://github.com/charmbracelet/vhs")
    os.exit(1)
  end

  if vim.fn.executable("nvim") ~= 1 then
    printf("Error: Neovim is not installed.")
    os.exit(1)
  end

  local fuzzy_so = root_dir .. "/lua/wildest/fuzzy.so"
  if not file_exists(fuzzy_so) then
    printf("Warning: fuzzy.so not found. Building...")
    os.execute("make -C " .. root_dir .. "/csrc")
  end
end

local function ensure_devicons()
  local devicons_path = root_dir .. "/deps/nvim-web-devicons"
  if not file_exists(devicons_path) then
    printf("Cloning nvim-web-devicons...")
    os.execute(
      "git clone --depth 1 https://github.com/nvim-tree/nvim-web-devicons " .. devicons_path
    )
  end
end

-- ── List configs ─────────────────────────────────────────────────

local function list_configs()
  printf("Available configs:")
  printf("")

  for _, cat in ipairs(configs_mod.categories) do
    printf("%s:", cat.display)
    for _, name in ipairs(cat.names) do
      printf("  %s", (cat.prefix or "") .. name)
    end
    printf("")
  end
end

-- ── Build ordered config name lists ──────────────────────────────

local function all_config_names()
  local names = {}
  for _, cat in ipairs(configs_mod.categories) do
    for _, n in ipairs(cat.names) do
      table.insert(names, (cat.prefix or "") .. n)
    end
  end
  return names
end

-- ── Main ─────────────────────────────────────────────────────────

local function main()
  local configs_to_run = {}
  local parallel_jobs = 1
  local generate_gifs = false
  local generate_showdown_flag = false
  local generate_gunsmoke_flag = false

  -- Parse arguments
  local args = vim.v.argv
  -- Find our script in argv, arguments follow it
  local script_args = {}
  local found_script = false
  for _, a in ipairs(args) do
    if found_script then
      table.insert(script_args, a)
    elseif a:match("generate%.lua$") then
      found_script = true
    end
  end

  -- Build flag→category lookup from configs_mod.categories
  local category_flags = {}
  for _, cat in ipairs(configs_mod.categories) do
    category_flags["--" .. cat.flag] = cat
  end

  local i = 1
  while i <= #script_args do
    local a = script_args[i]
    if a == "--help" or a == "-h" then
      -- Print usage from top comment
      local f = io.open(debug.getinfo(1, "S").source:sub(2), "r")
      if f then
        for line in f:lines() do
          if line:match("^%-%-") then
            break
          end
          if line:match("^%-%-") == nil and line:sub(1, 2) == "--" then
            io.write(line:sub(4) .. "\n")
          end
        end
        f:close()
      end
      os.exit(0)
    elseif a == "--list" then
      list_configs()
      os.exit(0)
    elseif category_flags[a] then
      local cat = category_flags[a]
      for _, n in ipairs(cat.names) do
        table.insert(configs_to_run, (cat.prefix or "") .. n)
      end
    elseif a == "--gifs" then
      generate_gifs = true
    elseif a == "--showdown" then
      generate_showdown_flag = true
    elseif a == "--gunsmoke" then
      generate_gunsmoke_flag = true
    elseif a == "--install-deps" then
      install_deps()
    elseif a:match("^%-j%d+$") then
      parallel_jobs = tonumber(a:sub(3))
    else
      -- Single config name
      table.insert(configs_to_run, a)
    end
    i = i + 1
  end

  -- Default: all configs
  if #configs_to_run == 0 and not generate_showdown_flag and not generate_gunsmoke_flag then
    configs_to_run = all_config_names()
  end

  check_deps()
  ensure_devicons()
  vim.fn.mkdir(output_dir, "p")

  -- GIF-only mode
  if #configs_to_run == 0 and (generate_showdown_flag or generate_gunsmoke_flag) then
    if generate_showdown_flag then
      generate_gif("showdown")
    end
    if generate_gunsmoke_flag then
      generate_gif("gunsmoke")
    end
    printf("")
    printf("Output: %s/", output_dir)
    os.exit(0)
  end

  printf("Generating %d screenshot(s) (jobs: %d)...", #configs_to_run, parallel_jobs)
  printf("Output: %s/", output_dir)
  printf("")

  local succeeded, failed = 0, 0

  if parallel_jobs > 1 then
    -- Build all tape files, then run in parallel
    local jobs = {}
    for i, config_name in ipairs(configs_to_run) do
      printf("  [%d] %s", i, config_name)
      local tape_file = generate_tape(config_name, generate_gifs)
      table.insert(jobs, { config = config_name, tape = tape_file })
    end

    local results = run_parallel(jobs, parallel_jobs)

    for j = 1, #jobs do
      if results[j] then
        succeeded = succeeded + 1
      else
        failed = failed + 1
      end
    end
  else
    -- Sequential execution
    for i, config_name in ipairs(configs_to_run) do
      printf("  [%d] Generating: %s", i, config_name)
      local tape_file = generate_tape(config_name, generate_gifs)
      local ok = run_vhs(tape_file)
      os.remove(tape_file)

      local png_path = output_dir .. "/" .. config_name .. ".png"
      if ok and file_exists(png_path) then
        printf("    OK: %s.png (%s)", config_name, file_size_human(png_path))
        succeeded = succeeded + 1
      else
        printf("    FAILED: %s.png not created", config_name)
        failed = failed + 1
      end
    end
  end

  printf("")
  printf("Done: %d succeeded, %d failed", succeeded, failed)
  printf("Screenshots: %s/", output_dir)

  -- Print index for easy reference
  printf("")
  printf("Index:")
  for i, config_name in ipairs(configs_to_run) do
    printf("  [%d] %s", i, config_name)
  end

  -- Generate GIFs if requested alongside screenshots
  if generate_showdown_flag then
    generate_gif("showdown")
  end
  if generate_gunsmoke_flag then
    generate_gif("gunsmoke")
  end

  os.exit(failed > 0 and 1 or 0)
end

main()

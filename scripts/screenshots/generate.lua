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
local sample_lua = script_dir .. "/sample.lua"

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

-- ── VHS tape generation ──────────────────────────────────────────

local function generate_tape(config_name, generate_gifs)
  local cmd = get_cmd(config_name)
  local mode = cmd:sub(1, 1)
  local typed = cmd:sub(2)
  local nvim_cmd = string.format("WILDEST_CONFIG=%s nvim -u %s -i NONE %s", config_name, init_lua, sample_lua)

  local parts = {}

  if generate_gifs then
    table.insert(parts, string.format('Output "%s/%s.gif"', output_dir, config_name))
    table.insert(parts, "")
  end

  table.insert(parts, string.format([[Require nvim

Set Shell "bash"
Set FontSize %d
Set FontFamily "%s"
Set Width %d
Set Height %d
Set Padding %d
Set Theme "%s"
Set TypingSpeed 50ms

Type "%s"
Enter
Sleep 2s

Type "%s"
Sleep 500ms
Type@80ms "%s"
Sleep 2s

Screenshot "%s/%s.png"

Escape
Sleep 300ms
Type ":q!"
Enter
Sleep 500ms]], settings.font_size, settings.font_family, settings.width, settings.height,
    settings.padding, settings.theme, nvim_cmd, mode, typed, output_dir, config_name))

  local path = os.tmpname() .. ".tape"
  local f = io.open(path, "w")
  f:write(table.concat(parts, "\n"))
  f:close()
  return path
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
          printf("    OK: %s.png (%s)", config_name, file_size_human(output_dir .. "/" .. config_name .. ".png"))
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
    -- Fuzzy searches that show off fzy matching across filenames
    { mode = ":", typed = "e init" },
    { mode = ":", typed = "e rend" },
    { mode = ":", typed = "e high" },
    { mode = ":", typed = "e pipe" },
    { mode = ":", typed = "e test" },
    { mode = ":", typed = "e conf" },
    { mode = ":", typed = "e util" },
    { mode = ":", typed = "e gen" },
    -- Directory prefix completions
    { mode = ":", typed = "e lua/wildest/" },
    { mode = ":", typed = "e lua/wildest/renderer/" },
    { mode = ":", typed = "e scripts/" },
    { mode = ":", typed = "e tests/" },
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
  },
}

-- Weighted distribution: file & option are the most common user actions,
-- search and help are frequent, lua is less common but important to test.
local scene_weights = {
  { "file",   25 },
  { "option", 25 },
  { "help",   20 },
  { "lua",    15 },
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
    local wait_ms = math.random(1500, 3000)

    if i > 1 then
      table.insert(parts, "Ctrl+n")
      table.insert(parts, "Sleep 300ms")
      table.insert(parts, "")
    end
    table.insert(parts, string.format('Type "%s"', s.mode))
    table.insert(parts, "Sleep 300ms")
    table.insert(parts, string.format('Type@%dms "%s"', speed, s.typed))
    table.insert(parts, string.format("Sleep %dms", wait_ms))
    table.insert(parts, "Escape")
    table.insert(parts, "Sleep 300ms")
    table.insert(parts, "")
  end
  return table.concat(parts, "\n")
end

-- ── Showdown GIF ─────────────────────────────────────────────────

local function generate_showdown()
  printf("Generating animated showdown GIF...")

  local showdown_init = script_dir .. "/showdown_init.lua"
  local scene_tape = build_scene_tape(25)
  local tape = string.format([[Output "%s/showdown.gif"

Require nvim

Set Shell "bash"
Set FontSize %d
Set FontFamily "%s"
Set Width %d
Set Height %d
Set Padding %d
Set Theme "%s"
Set TypingSpeed 60ms

Hide
Type "nvim -u %s -i NONE %s"
Enter
Sleep 2s
Show

%s

Hide
Type ":q!"
Enter
Sleep 500ms]], output_dir, settings.font_size, settings.font_family, settings.width, settings.height,
    settings.padding, settings.theme, showdown_init, sample_lua, scene_tape)

  local tape_file = os.tmpname() .. ".tape"
  local f = io.open(tape_file, "w")
  f:write(tape)
  f:close()

  local ok = run_vhs(tape_file)
  os.remove(tape_file)

  if ok and file_exists(output_dir .. "/showdown.gif") then
    printf("  OK: showdown.gif (%s)", file_size_human(output_dir .. "/showdown.gif"))
  else
    printf("  FAILED: showdown.gif")
    return false
  end
  return true
end

-- ── Gunsmoke GIF ─────────────────────────────────────────────────

local function generate_gunsmoke()
  printf("Generating animated gunsmoke GIF...")

  local gunsmoke_init = script_dir .. "/gunsmoke_init.lua"
  local scene_tape = build_scene_tape(25)
  local tape = string.format([[Output "%s/gunsmoke.gif"

Require nvim

Set Shell "bash"
Set FontSize %d
Set FontFamily "%s"
Set Width %d
Set Height %d
Set Padding %d
Set Theme "%s"
Set TypingSpeed 60ms

Hide
Type "nvim -u %s -i NONE %s"
Enter
Sleep 2s
Show

%s

Hide
Type ":q!"
Enter
Sleep 500ms]], output_dir, settings.font_size, settings.font_family, settings.width, settings.height,
    settings.padding, settings.theme, gunsmoke_init, sample_lua, scene_tape)

  local tape_file = os.tmpname() .. ".tape"
  local f = io.open(tape_file, "w")
  f:write(tape)
  f:close()

  local ok = run_vhs(tape_file)
  os.remove(tape_file)

  if ok and file_exists(output_dir .. "/gunsmoke.gif") then
    printf("  OK: gunsmoke.gif (%s)", file_size_human(output_dir .. "/gunsmoke.gif"))
  else
    printf("  FAILED: gunsmoke.gif")
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
    os.execute("curl -fsSL https://repo.charm.sh/apt/gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/charm.gpg")
    os.execute('echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" | sudo tee /etc/apt/sources.list.d/charm.list')
    os.execute("sudo apt-get update")
    os.execute("sudo apt-get install -y vhs ttyd")
  end

  if os.execute('fc-list | grep -qi "JetBrainsMono Nerd Font"') ~= 0 then
    printf("  Installing JetBrainsMono Nerd Font...")
    os.execute("mkdir -p ~/.local/share/fonts")
    os.execute("curl -fsSL https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz | tar -xJf - -C ~/.local/share/fonts")
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
    os.execute("git clone --depth 1 https://github.com/nvim-tree/nvim-web-devicons " .. devicons_path)
  end
end

-- ── List configs ─────────────────────────────────────────────────

local function list_configs()
  printf("Available configs:")
  printf("")

  local categories = {
    { name = "Renderers", list = configs_mod.renderer_names },
    { name = "Themes", list = configs_mod.theme_names, prefix = "theme_" },
    { name = "Features", list = configs_mod.feature_names },
    { name = "Pipelines", list = configs_mod.pipeline_names },
    { name = "Highlights", list = configs_mod.highlight_names },
    { name = "Borders", list = configs_mod.border_names },
    { name = "Wildmenu Variants", list = configs_mod.wildmenu_variant_names },
    { name = "Palette Variants", list = configs_mod.palette_variant_names },
    { name = "Dimensions", list = configs_mod.dimension_names },
    { name = "Gradients", list = configs_mod.gradient_names },
    { name = "Combinations", list = configs_mod.combination_names },
    { name = "Layouts", list = configs_mod.layout_names },
    { name = "Options", list = configs_mod.option_names },
  }

  for _, cat in ipairs(categories) do
    printf("%s:", cat.name)
    for _, name in ipairs(cat.list) do
      printf("  %s", (cat.prefix or "") .. name)
    end
    printf("")
  end
end

-- ── Build ordered config name lists ──────────────────────────────

local function all_config_names()
  local names = {}
  local function add(list, prefix)
    for _, n in ipairs(list) do
      table.insert(names, (prefix or "") .. n)
    end
  end
  add(configs_mod.renderer_names)
  add(configs_mod.theme_names, "theme_")
  add(configs_mod.feature_names)
  add(configs_mod.pipeline_names)
  add(configs_mod.highlight_names)
  add(configs_mod.border_names)
  add(configs_mod.wildmenu_variant_names)
  add(configs_mod.palette_variant_names)
  add(configs_mod.dimension_names)
  add(configs_mod.gradient_names)
  add(configs_mod.combination_names)
  add(configs_mod.layout_names)
  add(configs_mod.option_names)
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
    elseif a == "--themes" then
      for _, n in ipairs(configs_mod.theme_names) do
        table.insert(configs_to_run, "theme_" .. n)
      end
    elseif a == "--renderers" then
      for _, n in ipairs(configs_mod.renderer_names) do
        table.insert(configs_to_run, n)
      end
    elseif a == "--features" then
      for _, n in ipairs(configs_mod.feature_names) do
        table.insert(configs_to_run, n)
      end
    elseif a == "--pipelines" then
      for _, n in ipairs(configs_mod.pipeline_names) do
        table.insert(configs_to_run, n)
      end
    elseif a == "--highlights" then
      for _, n in ipairs(configs_mod.highlight_names) do
        table.insert(configs_to_run, n)
      end
    elseif a == "--borders" then
      for _, n in ipairs(configs_mod.border_names) do
        table.insert(configs_to_run, n)
      end
    elseif a == "--wildmenu-variants" then
      for _, n in ipairs(configs_mod.wildmenu_variant_names) do
        table.insert(configs_to_run, n)
      end
    elseif a == "--palette-variants" then
      for _, n in ipairs(configs_mod.palette_variant_names) do
        table.insert(configs_to_run, n)
      end
    elseif a == "--dimensions" then
      for _, n in ipairs(configs_mod.dimension_names) do
        table.insert(configs_to_run, n)
      end
    elseif a == "--gradients" then
      for _, n in ipairs(configs_mod.gradient_names) do
        table.insert(configs_to_run, n)
      end
    elseif a == "--combinations" then
      for _, n in ipairs(configs_mod.combination_names) do
        table.insert(configs_to_run, n)
      end
    elseif a == "--layouts" then
      for _, n in ipairs(configs_mod.layout_names) do
        table.insert(configs_to_run, n)
      end
    elseif a == "--options" then
      for _, n in ipairs(configs_mod.option_names) do
        table.insert(configs_to_run, n)
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
      generate_showdown()
    end
    if generate_gunsmoke_flag then
      generate_gunsmoke()
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
    for _, config_name in ipairs(configs_to_run) do
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
    for _, config_name in ipairs(configs_to_run) do
      printf("  Generating: %s", config_name)
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

  -- Generate GIFs if requested alongside screenshots
  if generate_showdown_flag then
    generate_showdown()
  end
  if generate_gunsmoke_flag then
    generate_gunsmoke()
  end

  os.exit(failed > 0 and 1 or 0)
end

main()

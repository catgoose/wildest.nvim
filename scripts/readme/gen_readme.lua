#!/usr/bin/env lua
-- Generate README.md from template + runtime data.
-- Usage:
--   lua scripts/readme/gen_readme.lua            -- write README.md
--   lua scripts/readme/gen_readme.lua --check    -- exit 1 if README is stale
--   lua scripts/readme/gen_readme.lua --output X -- write to X instead

local IMG_BASE = "https://raw.githubusercontent.com/catgoose/wildest.nvim/screenshots/"

-- ── CLI args ───────────────────────────────────────────────────────

local check_mode = false
local output_path = "README.md"

local i = 1
while i <= #arg do
  if arg[i] == "--check" then
    check_mode = true
  elseif arg[i] == "--output" then
    i = i + 1
    output_path = arg[i]
  end
  i = i + 1
end

-- ── Stub vim global ────────────────────────────────────────────────

if not vim then
  -- Minimal stub so dofile on configs.lua doesn't crash.
  -- We only read static data tables, never call runtime functions.
  local noop = function() end
  local opt_mt = {
    __index = function()
      return { prepend = noop, append = noop }
    end,
  }
  vim = {
    opt = setmetatable({}, opt_mt),
    fn = setmetatable({}, {
      __index = function()
        return function() return "" end
      end,
    }),
    o = setmetatable({}, {
      __index = function() return 0 end,
      __newindex = noop,
    }),
    api = setmetatable({}, {
      __index = function()
        return noop
      end,
    }),
    cmd = noop,
    notify = noop,
    log = { levels = { ERROR = 1, WARN = 2, INFO = 3 } },
    tbl_extend = function(behavior, ...)
      local result = {}
      for _, t in ipairs({ ... }) do
        for k, v in pairs(t) do
          if behavior == "keep" and result[k] ~= nil then
            -- keep existing
          else
            result[k] = v
          end
        end
      end
      return result
    end,
    tbl_keys = function(t)
      local keys = {}
      for k in pairs(t) do
        keys[#keys + 1] = k
      end
      return keys
    end,
  }
end

-- ── Load configs.lua ───────────────────────────────────────────────

local configs_mod = dofile("scripts/screenshots/configs.lua")

-- ── Parse highlight defaults from renderer/init.lua ────────────────

local function parse_highlight_defaults()
  local f = io.open("lua/wildest/renderer/init.lua", "r")
  if not f then
    error("Cannot open lua/wildest/renderer/init.lua")
  end
  local src = f:read("*a")
  f:close()

  -- Extract the defaults table block
  local block = src:match("local defaults = (%b{})")
  if not block then
    error("Cannot find 'local defaults = {...}' in renderer/init.lua")
  end

  -- Parse key = "value" pairs (order-preserving via ordered list)
  local ordered = {}
  for group, link in block:gmatch('(%w+)%s*=%s*"([^"]+)"') do
    ordered[#ordered + 1] = { group = group, link = link }
  end
  return ordered
end

-- ── Highlight group descriptions ───────────────────────────────────

local hl_descriptions = {
  WildestDefault = "Popup background and text",
  WildestSelected = "Selected candidate",
  WildestAccent = "Matched characters",
  WildestSelectedAccent = "Matched characters (selected)",
  WildestBorder = "Border decoration",
  WildestPrompt = "Palette prompt area",
  WildestPromptCursor = "Palette prompt cursor",
  WildestScrollbar = "Scrollbar track",
  WildestScrollbarThumb = "Scrollbar thumb",
  WildestSpinner = "Loading spinner",
  WildestError = "Error messages",
}

-- ── Theme metadata ─────────────────────────────────────────────────

local theme_meta = {
  auto            = { renderer = "bordered", desc = "Derives colors from your colorscheme - a chameleon" },
  default         = { renderer = "plain",    desc = "Standard Pmenu links, no frills" },
  saloon          = { renderer = "bordered", desc = "Amber and whiskey - belly up to the bar" },
  outlaw          = { renderer = "bordered", desc = "Dark with crimson - wanted dead or alive" },
  sunset          = { renderer = "bordered", desc = "Orange to purple - end of the trail" },
  prairie         = { renderer = "bordered", desc = "Soft greens and earth - wide open spaces" },
  dusty           = { renderer = "bordered", desc = "Sandstone and sage - desert wanderer" },
  midnight        = { renderer = "bordered", desc = "Deep blue and silver - stars over the range" },
  wanted          = { renderer = "palette",  desc = "Parchment and ink - nailed to the post office wall" },
  cactus          = { renderer = "bordered", desc = "Green on dark soil - prickly but pretty" },
  tumbleweed      = { renderer = "plain",    desc = "Light and minimal - blowin' through town" },
  kanagawa        = { renderer = "bordered", desc = "Deep ink, warm autumn - the far east frontier" },
  kanagawa_dragon = { renderer = "bordered", desc = "Dark earth tones - dragon in the canyon" },
  kanagawa_lotus  = { renderer = "bordered", desc = "Light parchment - lotus in the desert spring" },
  catppuccin_mocha  = { renderer = "bordered", desc = "Rich dark pastels - lavender in the moonlight" },
  catppuccin_frappe = { renderer = "bordered", desc = "Dusky blue-grey pastels - twilight in the valley" },
  catppuccin_latte  = { renderer = "bordered", desc = "Warm light pastels - cream and ink at dawn" },
  tokyonight_night  = { renderer = "bordered", desc = "Deep midnight blue - neon in the dark" },
  tokyonight_storm  = { renderer = "bordered", desc = "Stormy dark blue - lightning on the horizon" },
  tokyonight_moon   = { renderer = "bordered", desc = "Soft moonlit blue - silver glow on the plains" },
  rose_pine         = { renderer = "bordered", desc = "Muted dark tones - wild roses at dusk" },
  rose_pine_moon    = { renderer = "bordered", desc = "Deeper purple base - roses under moonlight" },
  rose_pine_dawn    = { renderer = "bordered", desc = "Warm parchment light - roses at first light" },
  gruvbox_dark      = { renderer = "bordered", desc = "Warm retro earth - campfire in the canyon" },
  gruvbox_light     = { renderer = "bordered", desc = "Sandy retro light - parchment in the sun" },
  nord              = { renderer = "bordered", desc = "Arctic cool - frost on the frontier" },
  onedark           = { renderer = "bordered", desc = "Atom-inspired grey - steel and blue" },
  nightfox          = { renderer = "bordered", desc = "Deep ocean blue - foxfire in the night" },
  everforest_dark   = { renderer = "bordered", desc = "Woodland greens on dark soil - deep in the forest" },
  everforest_light  = { renderer = "bordered", desc = "Soft cream with fresh greens - forest clearing" },
  dracula           = { renderer = "bordered", desc = "Classic dark purple - the count rides at midnight" },
  solarized_dark    = { renderer = "bordered", desc = "Precision teal and cyan - the original classic" },
}

-- Validate every theme_name has metadata
for _, name in ipairs(configs_mod.theme_names) do
  if not theme_meta[name] then
    error("Missing theme_meta entry for theme: " .. name)
  end
end

-- ── Display labels for gallery items ───────────────────────────────

local display_labels = {
  -- Renderers
  popupmenu = "Popupmenu",
  popupmenu_border = "Bordered",
  popupmenu_palette = "Palette",
  wildmenu = "Wildmenu",
  -- Pipelines
  lua_pipeline = "Lua Completion",
  help_pipeline = "Help Tags",
  history_pipeline = "History",
  -- Highlights
  hl_neon = "Neon",
  hl_ember = "Ember",
  hl_ocean = "Ocean",
  -- Layouts
  laststatus_0 = "laststatus=0",
  laststatus_2 = "laststatus=2",
  laststatus_3 = "laststatus=3",
  cmdheight_0 = "cmdheight=0",
  cmdheight_0_offset_1 = "cmdheight=0 offset=1",
  cmdheight_0_offset_2 = "cmdheight=0 offset=2",
  offset_1 = "offset=1",
  offset_2 = "offset=2",
  -- Options
  noselect_false = "noselect=false",
  reverse = "reverse=true",
  empty_message = "empty_message",
  buffer_flags = "buffer_flags",
}

-- ── HTML helpers ───────────────────────────────────────────────────

local function img_cell(name, label, width)
  width = width or 400
  label = label or name
  return string.format(
    '<td align="center"><strong>%s</strong><br><img src="%s%s.png" width="%d"></td>',
    label, IMG_BASE, name, width
  )
end

local function gallery_table(names, prefix, label_fn)
  local lines = { "<table>" }
  for i = 1, #names, 2 do
    local name1 = names[i]
    local name2 = names[i + 1]
    local img_name1 = prefix and (prefix .. name1) or name1
    local img_name2 = name2 and (prefix and (prefix .. name2) or name2) or nil
    local label1 = label_fn and label_fn(name1) or (display_labels[name1] or name1)
    local label2 = name2 and (label_fn and label_fn(name2) or (display_labels[name2] or name2)) or nil
    lines[#lines + 1] = "<tr>"
    lines[#lines + 1] = img_cell(img_name1, label1)
    if img_name2 then
      lines[#lines + 1] = img_cell(img_name2, label2)
    else
      lines[#lines + 1] = "<td></td>"
    end
    lines[#lines + 1] = "</tr>"
  end
  lines[#lines + 1] = "</table>"
  return table.concat(lines, "\n")
end

-- ── Section generators ─────────────────────────────────────────────

local function gen_screenshot_table()
  -- All configs from all categories in order: renderer, feature, pipeline,
  -- highlight, layout, option, then themes
  local all_names = {}
  local lists = {
    configs_mod.renderer_names,
    configs_mod.feature_names,
    configs_mod.pipeline_names,
    configs_mod.highlight_names,
    configs_mod.layout_names,
    configs_mod.option_names,
  }
  for _, list in ipairs(lists) do
    for _, name in ipairs(list) do
      all_names[#all_names + 1] = name
    end
  end
  for _, name in ipairs(configs_mod.theme_names) do
    all_names[#all_names + 1] = "theme_" .. name
  end

  local lines = { "<table>" }
  for i = 1, #all_names, 2 do
    local n1 = all_names[i]
    local n2 = all_names[i + 1]
    lines[#lines + 1] = "<tr>"
    lines[#lines + 1] = img_cell(n1, n1)
    if n2 then
      lines[#lines + 1] = img_cell(n2, n2)
    end
    lines[#lines + 1] = "</tr>"
  end
  lines[#lines + 1] = "</table>"
  return table.concat(lines, "\n")
end

local function gen_pipeline_gallery()
  -- Pipeline gallery includes the named pipelines plus "search" from features
  local names = {}
  for _, n in ipairs(configs_mod.pipeline_names) do
    names[#names + 1] = n
  end
  names[#names + 1] = "search"
  local label_fn = function(n)
    if n == "search" then return "Search" end
    return display_labels[n] or n
  end
  return gallery_table(names, nil, label_fn)
end

local function gen_renderer_gallery()
  return gallery_table(configs_mod.renderer_names, nil, nil)
end

local function gen_highlight_groups()
  local hl_defaults = parse_highlight_defaults()
  local lines = {}
  lines[#lines + 1] = "| Group | Default Link | Used For |"
  lines[#lines + 1] = "| --- | --- | --- |"
  for _, entry in ipairs(hl_defaults) do
    local desc = hl_descriptions[entry.group] or ""
    lines[#lines + 1] = string.format("| `%s` | `%s` | %s |", entry.group, entry.link, desc)
  end
  return table.concat(lines, "\n")
end

local function gen_highlight_gallery()
  return gallery_table(configs_mod.highlight_names, nil, nil)
end

local function gen_theme_table()
  local lines = {}
  -- Compute column widths for alignment
  local max_theme = 5  -- "Theme"
  local max_rend = 8   -- "Renderer"
  local max_desc = 11  -- "Description"
  for _, name in ipairs(configs_mod.theme_names) do
    local meta = theme_meta[name]
    local theme_col = string.format("`%s`", name)
    if #theme_col > max_theme then max_theme = #theme_col end
    if #meta.renderer > max_rend then max_rend = #meta.renderer end
    if #meta.desc > max_desc then max_desc = #meta.desc end
  end

  local function pad(s, w)
    return s .. string.rep(" ", w - #s)
  end

  lines[#lines + 1] = string.format("| %s | %s | %s |",
    pad("Theme", max_theme), pad("Renderer", max_rend), pad("Description", max_desc))
  lines[#lines + 1] = string.format("| %s | %s | %s |",
    string.rep("-", max_theme), string.rep("-", max_rend), string.rep("-", max_desc))
  for _, name in ipairs(configs_mod.theme_names) do
    local meta = theme_meta[name]
    local theme_col = string.format("`%s`", name)
    lines[#lines + 1] = string.format("| %s | %s | %s |",
      pad(theme_col, max_theme), pad(meta.renderer, max_rend), pad(meta.desc, max_desc))
  end
  return table.concat(lines, "\n")
end

local function gen_theme_gallery()
  return gallery_table(configs_mod.theme_names, "theme_", function(name) return name end)
end

local function gen_layout_gallery()
  return gallery_table(configs_mod.layout_names, nil, nil)
end

local function gen_option_gallery()
  return gallery_table(configs_mod.option_names, nil, nil)
end

-- ── Marker replacement ─────────────────────────────────────────────

local generators = {
  screenshot_table = gen_screenshot_table,
  pipeline_gallery = gen_pipeline_gallery,
  renderer_gallery = gen_renderer_gallery,
  highlight_groups = gen_highlight_groups,
  highlight_gallery = gen_highlight_gallery,
  theme_table = gen_theme_table,
  theme_gallery = gen_theme_gallery,
  layout_gallery = gen_layout_gallery,
  option_gallery = gen_option_gallery,
}

local function read_file(path)
  local f = io.open(path, "r")
  if not f then
    error("Cannot open: " .. path)
  end
  local content = f:read("*a")
  f:close()
  return content
end

local function replace_markers(template)
  -- Replace content between start/end marker pairs.
  -- Process line-by-line for robustness with empty sections.
  local lines = {}
  local in_marker = nil
  for line in template:gmatch("([^\n]*)\n?") do
    local start_name = line:match("^<!%-%- gen:([%w_]+):start %-%->$")
    local end_name = line:match("^<!%-%- gen:([%w_]+):end %-%->$")
    if start_name then
      in_marker = start_name
      lines[#lines + 1] = line
      local gen = generators[in_marker]
      if not gen then
        error("Unknown generator: " .. in_marker)
      end
      lines[#lines + 1] = gen()
    elseif end_name and in_marker == end_name then
      lines[#lines + 1] = line
      in_marker = nil
    elseif not in_marker then
      lines[#lines + 1] = line
    end
    -- else: skip old content between markers
  end
  -- gmatch produces an extra empty string at the end; remove trailing empty line
  -- only if the original didn't end with one
  if not template:match("\n$") and lines[#lines] == "" then
    table.remove(lines)
  end
  return table.concat(lines, "\n")
end

-- ── Main ───────────────────────────────────────────────────────────

local template = read_file("scripts/readme/README.template.md")
local result = replace_markers(template)

if check_mode then
  local current = read_file(output_path)
  if current == result then
    print("README.md is up-to-date.")
    os.exit(0)
  else
    io.stderr:write("README.md is out-of-date. Run 'make readme' to regenerate.\n")
    -- Write to temp for diff
    local tmp = os.tmpname()
    local f = io.open(tmp, "w")
    f:write(result)
    f:close()
    os.execute(string.format("diff -u %s %s || true", output_path, tmp))
    os.remove(tmp)
    os.exit(1)
  end
else
  local f = io.open(output_path, "w")
  if not f then
    error("Cannot write: " .. output_path)
  end
  f:write(result)
  f:close()
  print("Generated " .. output_path)
end

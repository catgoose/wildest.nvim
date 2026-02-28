#!/usr/bin/env lua
-- Generate README.md and SCREENSHOTS.md from templates + runtime data.
-- Usage:
--   lua scripts/readme/gen_readme.lua            -- write README.md + SCREENSHOTS.md
--   lua scripts/readme/gen_readme.lua --check    -- exit 1 if any output is stale
--   lua scripts/readme/gen_readme.lua --output X -- write README to X instead

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

local theme_meta = configs_mod.theme_meta

-- Validate every theme_name has metadata
for _, name in ipairs(configs_mod.theme_names) do
  if not theme_meta[name] then
    error("Missing theme_meta entry for theme: " .. name)
  end
end

-- ── Display labels (read from configs) ─────────────────────────────

local function get_label(name)
  local cfg = configs_mod.configs[name]
  return cfg and cfg.label or name
end

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
    local label1 = label_fn and label_fn(name1) or get_label(name1)
    local label2 = name2 and (label_fn and label_fn(name2) or get_label(name2)) or nil
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
  -- All configs from all categories in order
  local all_names = {}
  local lists = {
    configs_mod.renderer_names,
    configs_mod.feature_names,
    configs_mod.pipeline_names,
    configs_mod.highlight_names,
    configs_mod.border_names,
    configs_mod.wildmenu_variant_names,
    configs_mod.palette_variant_names,
    configs_mod.dimension_names,
    configs_mod.gradient_names,
    configs_mod.combination_names,
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
    return get_label(n)
  end
  return gallery_table(names, nil, label_fn)
end

local function gen_renderer_gallery()
  return gallery_table(configs_mod.renderer_names, nil, nil)
end

local function gen_feature_gallery()
  return gallery_table(configs_mod.feature_names, nil, nil)
end

local function gen_border_gallery()
  return gallery_table(configs_mod.border_names, nil, nil)
end

local function gen_wildmenu_variant_gallery()
  return gallery_table(configs_mod.wildmenu_variant_names, nil, nil)
end

local function gen_palette_variant_gallery()
  return gallery_table(configs_mod.palette_variant_names, nil, nil)
end

local function gen_dimension_gallery()
  return gallery_table(configs_mod.dimension_names, nil, nil)
end

local function gen_gradient_gallery()
  return gallery_table(configs_mod.gradient_names, nil, nil)
end

local function gen_combination_gallery()
  return gallery_table(configs_mod.combination_names, nil, nil)
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
  feature_gallery = gen_feature_gallery,
  border_gallery = gen_border_gallery,
  wildmenu_variant_gallery = gen_wildmenu_variant_gallery,
  palette_variant_gallery = gen_palette_variant_gallery,
  dimension_gallery = gen_dimension_gallery,
  gradient_gallery = gen_gradient_gallery,
  combination_gallery = gen_combination_gallery,
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

local function write_file(path, content)
  local f = io.open(path, "w")
  if not f then
    error("Cannot write: " .. path)
  end
  f:write(content)
  f:close()
end

-- ── Main ───────────────────────────────────────────────────────────

-- Files to generate: { template_path, output_path }
local targets = {
  { template = "scripts/readme/README.template.md", output = output_path },
  { template = "scripts/readme/SCREENSHOTS.template.md", output = "SCREENSHOTS.md" },
}

local all_ok = true

for _, target in ipairs(targets) do
  local template = read_file(target.template)
  local result = replace_markers(template)

  if check_mode then
    local ok, current = pcall(read_file, target.output)
    if ok and current == result then
      print(target.output .. " is up-to-date.")
    else
      all_ok = false
      io.stderr:write(target.output .. " is out-of-date. Run 'make readme' to regenerate.\n")
      if ok then
        local tmp = os.tmpname()
        local f = io.open(tmp, "w")
        f:write(result)
        f:close()
        os.execute(string.format("diff -u %s %s || true", target.output, tmp))
        os.remove(tmp)
      end
    end
  else
    write_file(target.output, result)
    print("Generated " .. target.output)
  end
end

if check_mode and not all_ok then
  os.exit(1)
end

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
  local cols = 3
  local lines = { "<table>" }
  for i = 1, #names, cols do
    lines[#lines + 1] = "<tr>"
    for j = 0, cols - 1 do
      local name = names[i + j]
      if name then
        local img_name = prefix and (prefix .. name) or name
        local label = label_fn and label_fn(name) or get_label(name)
        lines[#lines + 1] = img_cell(img_name, label)
      else
        lines[#lines + 1] = "<td></td>"
      end
    end
    lines[#lines + 1] = "</tr>"
  end
  lines[#lines + 1] = "</table>"
  return table.concat(lines, "\n")
end

-- ── Lua value serializer ─────────────────────────────────────────

local function serialize_lua(v, indent)
  indent = indent or 0
  local t = type(v)
  if t == "string" then
    return string.format("%q", v)
  elseif t == "number" or t == "boolean" then
    return tostring(v)
  elseif t ~= "table" then
    return tostring(v)
  end
  local pad = string.rep("  ", indent + 1)
  local pad_close = string.rep("  ", indent)
  -- Check if sequential list
  local count = 0
  for _ in pairs(v) do count = count + 1 end
  if count == #v and count > 0 then
    local parts = {}
    for _, item in ipairs(v) do
      parts[#parts + 1] = serialize_lua(item, 0)
    end
    local inline = "{ " .. table.concat(parts, ", ") .. " }"
    if #inline <= 60 then return inline end
    local lines = { "{" }
    for _, item in ipairs(v) do
      lines[#lines + 1] = pad .. serialize_lua(item, indent + 1) .. ","
    end
    lines[#lines + 1] = pad_close .. "}"
    return table.concat(lines, "\n")
  end
  -- Dict-style table
  local keys = {}
  for k in pairs(v) do keys[#keys + 1] = k end
  table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
  local parts = {}
  for _, k in ipairs(keys) do
    local ks = (type(k) == "string" and k:match("^[%a_][%w_]*$")) and k
      or ("[" .. serialize_lua(k, 0) .. "]")
    parts[#parts + 1] = ks .. " = " .. serialize_lua(v[k], 0)
  end
  local inline = "{ " .. table.concat(parts, ", ") .. " }"
  if #inline <= 60 then return inline end
  local lines = { "{" }
  for _, k in ipairs(keys) do
    local ks = (type(k) == "string" and k:match("^[%a_][%w_]*$")) and k
      or ("[" .. serialize_lua(k, 0) .. "]")
    lines[#lines + 1] = pad .. ks .. " = " .. serialize_lua(v[k], indent + 1) .. ","
  end
  lines[#lines + 1] = pad_close .. "}"
  return table.concat(lines, "\n")
end

-- ── Config serializer ────────────────────────────────────────────

local config_field_order = {
  "cmd", "renderer", "theme", "pipeline", "highlighter", "highlights",
  "left", "right", "separator", "ellipsis",
  "border", "title", "position",
  "max_height", "min_height", "fixed_height", "max_width",
  "noselect", "reverse", "pumblend", "offset",
  "empty_message", "laststatus", "cmdheight",
  "gradient_colors", "custom_highlights",
  "palette", "mux",
}

local config_skip_keys = { category = true, label = true }

local function config_to_lua(name)
  local raw = configs_mod.configs[name]
  if not raw then return "-- (unknown config)" end
  local seen = {}
  local parts = {}
  for _, key in ipairs(config_field_order) do
    if raw[key] ~= nil and not config_skip_keys[key] then
      seen[key] = true
      parts[#parts + 1] = key .. " = " .. serialize_lua(raw[key], 0) .. ","
    end
  end
  for k, v in pairs(raw) do
    if not seen[k] and not config_skip_keys[k] then
      parts[#parts + 1] = k .. " = " .. serialize_lua(v, 0) .. ","
    end
  end
  if #parts == 0 then
    return "-- (default settings)"
  end
  return table.concat(parts, "\n")
end

-- ── Expect description generator ─────────────────────────────────

local function gen_expect(name)
  local raw = configs_mod.configs[name]
  if not raw then return name end

  local merged = vim.tbl_extend("keep", raw, configs_mod.defaults)
  if merged.theme then
    merged.renderer = "theme:" .. merged.theme
    merged.highlights = false
  end

  local tokens = {}
  local function add(s) tokens[#tokens + 1] = s end

  -- Renderer
  local renderer = merged.renderer or "theme:auto"
  if renderer == "popupmenu" then
    add("plain popupmenu")
  elseif renderer == "border_theme" then
    add("bordered")
  elseif renderer == "palette" then
    add("palette")
  elseif renderer == "wildmenu" then
    add("wildmenu")
  elseif renderer == "mux" then
    add("renderer mux")
  elseif renderer:match("^theme:") then
    local theme_name = renderer:match("^theme:(.+)$")
    add(theme_name .. " theme")
    if theme_meta[theme_name] then
      add(theme_meta[theme_name].renderer)
    end
  end

  -- Border
  if merged.border then
    add(merged.border)
  end

  -- Notable options
  if merged.title then add("title") end
  if merged.position and merged.position ~= "bottom" then
    add("position=" .. merged.position)
  end
  if merged.reverse then add("reverse") end
  if merged.noselect == true then add("noselect") end
  if merged.noselect == false then add("noselect=false") end
  if merged.pumblend then add("pumblend=" .. merged.pumblend) end
  if merged.offset then add("offset=" .. merged.offset) end
  if merged.max_height then add("max_height=" .. merged.max_height) end
  if merged.min_height then add("min_height=" .. merged.min_height) end
  if merged.fixed_height == false then add("fixed_height=false") end
  if merged.empty_message then add("empty_message") end
  if merged.ellipsis then add("ellipsis") end

  -- Highlighter
  add(merged.highlighter or "fzy")

  -- Left components
  local left = merged.left
  local has_devicons, has_kind, has_buffer_flags = false, false, false
  if type(left) == "string" then
    if left == "devicons" then has_devicons = true end
  elseif type(left) == "table" then
    for _, item in ipairs(left) do
      if item == "devicons" then has_devicons = true end
      if item == "kind_icon" then has_kind = true end
      if item == "buffer_flags" then has_buffer_flags = true end
    end
  end
  if has_devicons then add("devicons") end
  if has_kind then add("kind icons") end
  if has_buffer_flags then add("buffer flags") end
  if not has_devicons and configs_mod.defaults.left == "devicons"
    and renderer ~= "wildmenu" and renderer ~= "mux" then
    add("no devicons")
  end

  -- Right components
  local has_scrollbar = false
  if type(merged.right) == "table" then
    for _, item in ipairs(merged.right) do
      if item == "scrollbar" then has_scrollbar = true end
    end
  end
  if has_scrollbar then add("scrollbar") end
  local default_has_scrollbar = false
  if type(configs_mod.defaults.right) == "table" then
    for _, item in ipairs(configs_mod.defaults.right) do
      if item == "scrollbar" then default_has_scrollbar = true end
    end
  end
  if not has_scrollbar and default_has_scrollbar
    and renderer ~= "wildmenu" and renderer ~= "mux" then
    add("no scrollbar")
  end

  -- Wildmenu-specific
  if renderer == "wildmenu" then
    local has_arrows = false
    if type(left) == "table" then
      for _, item in ipairs(left) do
        if item == "arrows" then has_arrows = true end
      end
    end
    if type(merged.right) == "table" then
      for _, item in ipairs(merged.right) do
        if item == "arrows_right" then has_arrows = true end
      end
    end
    if has_arrows then add("arrows") end
    if type(merged.right) == "table" then
      for _, item in ipairs(merged.right) do
        if item == "index" then add("index"); break end
      end
    end
    if merged.separator then
      add('separator="' .. merged.separator .. '"')
    end
  end

  -- Pipeline (non-default)
  if merged.pipeline then
    for _, p in ipairs(merged.pipeline) do
      if p == "lua" then add("lua pipeline") end
      if p == "help_fuzzy" then add("help pipeline") end
      if p == "history" then add("history pipeline") end
    end
  end

  -- Layout (non-default)
  if merged.laststatus ~= configs_mod.defaults.laststatus then
    add("laststatus=" .. merged.laststatus)
  end
  if merged.cmdheight ~= configs_mod.defaults.cmdheight then
    add("cmdheight=" .. merged.cmdheight)
  end

  -- Highlights
  if merged.custom_highlights then add("custom highlights") end
  if merged.gradient_colors then add("gradient colors") end

  -- Command
  local cmd = raw.cmd or configs_mod.default_cmd
  add(cmd:match("^(.-)%s*$"))

  return table.concat(tokens, ", ")
end

-- ── Detailed HTML helpers ────────────────────────────────────────

local function img_cell_detailed(config_name, label, width)
  width = width or 400
  label = label or config_name
  local expect = gen_expect(config_name)
  local config_lua = config_to_lua(config_name)
  return string.format(
    '<td align="center">\n'
    .. '<strong>%s</strong><br>\n'
    .. '<em>%s</em><br>\n'
    .. '<img src="%s%s.png" width="%d"><br>\n'
    .. '<details><summary>Config</summary>\n'
    .. '<pre><code class="language-lua">\n'
    .. '%s\n'
    .. '</code></pre>\n'
    .. '</details>\n'
    .. '</td>',
    label, expect, IMG_BASE, config_name, width, config_lua
  )
end

local function gallery_table_detailed(names, prefix, label_fn)
  local cols = 3
  local lines = { "<table>" }
  for i = 1, #names, cols do
    lines[#lines + 1] = "<tr>"
    for j = 0, cols - 1 do
      local name = names[i + j]
      if name then
        local img_name = prefix and (prefix .. name) or name
        local label = label_fn and label_fn(name) or get_label(name)
        lines[#lines + 1] = img_cell_detailed(img_name, label)
      else
        lines[#lines + 1] = "<td></td>"
      end
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

-- ── Test section generators (for SCREENSHOTS.md) ──────────────────

local function gen_renderer_gallery_test()
  return gallery_table_detailed(configs_mod.renderer_names, nil, nil)
end

local function gen_feature_gallery_test()
  return gallery_table_detailed(configs_mod.feature_names, nil, nil)
end

local function gen_pipeline_gallery_test()
  local names = {}
  for _, n in ipairs(configs_mod.pipeline_names) do
    names[#names + 1] = n
  end
  names[#names + 1] = "search"
  local label_fn = function(n)
    if n == "search" then return "Search" end
    return get_label(n)
  end
  return gallery_table_detailed(names, nil, label_fn)
end

local function gen_border_gallery_test()
  return gallery_table_detailed(configs_mod.border_names, nil, nil)
end

local function gen_wildmenu_variant_gallery_test()
  return gallery_table_detailed(configs_mod.wildmenu_variant_names, nil, nil)
end

local function gen_palette_variant_gallery_test()
  return gallery_table_detailed(configs_mod.palette_variant_names, nil, nil)
end

local function gen_dimension_gallery_test()
  return gallery_table_detailed(configs_mod.dimension_names, nil, nil)
end

local function gen_gradient_gallery_test()
  return gallery_table_detailed(configs_mod.gradient_names, nil, nil)
end

local function gen_combination_gallery_test()
  return gallery_table_detailed(configs_mod.combination_names, nil, nil)
end

local function gen_highlight_gallery_test()
  return gallery_table_detailed(configs_mod.highlight_names, nil, nil)
end

local function gen_theme_gallery_test()
  return gallery_table_detailed(configs_mod.theme_names, "theme_", function(name) return name end)
end

local function gen_layout_gallery_test()
  return gallery_table_detailed(configs_mod.layout_names, nil, nil)
end

local function gen_option_gallery_test()
  return gallery_table_detailed(configs_mod.option_names, nil, nil)
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
  -- Test variants (for SCREENSHOTS.md — includes descriptions + configs)
  renderer_gallery_test = gen_renderer_gallery_test,
  feature_gallery_test = gen_feature_gallery_test,
  pipeline_gallery_test = gen_pipeline_gallery_test,
  border_gallery_test = gen_border_gallery_test,
  wildmenu_variant_gallery_test = gen_wildmenu_variant_gallery_test,
  palette_variant_gallery_test = gen_palette_variant_gallery_test,
  dimension_gallery_test = gen_dimension_gallery_test,
  gradient_gallery_test = gen_gradient_gallery_test,
  combination_gallery_test = gen_combination_gallery_test,
  highlight_gallery_test = gen_highlight_gallery_test,
  theme_gallery_test = gen_theme_gallery_test,
  layout_gallery_test = gen_layout_gallery_test,
  option_gallery_test = gen_option_gallery_test,
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

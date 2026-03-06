---@mod wildest.renderer.components.statusline Popup Statusline Component
---@brief [[
---Bottom/top chrome component that shows a dynamic status bar with match count,
---page position, marked count, scroll progress, pipeline route, selection
---position, input length, frecency stats, and optional key hints.
---@brief ]]

local config = require("wildest.config")

local M = {}

--- Route display names by cmdtype
local route_icons = {
  [":"] = { icon = "", label = "cmd" },
  ["/"] = { icon = "", label = "search" },
  ["?"] = { icon = "", label = "search?" },
}

--- Pipeline route labels derived from result data
local function route_label(result)
  local data = result.data or {}
  if data.route then
    return data.route
  end
  local expand = data.expand or ""
  local map = {
    file = "files",
    dir = "dirs",
    file_in_path = "files",
    help = "help",
    option = "options",
    command = "commands",
    buffer = "buffers",
    color = "colors",
    highlight = "highlights",
    lua = "lua",
    shellcmd = "shell",
    history = "history",
    var = "vars",
    environment = "env",
    event = "events",
    expression = "expr",
    mapping = "maps",
    user = "user cmds",
  }
  return map[expand]
end

--- Build a progress bar string
---@param ratio number 0.0 to 1.0
---@param width integer character width
---@return string
local function progress_bar(ratio, width)
  local filled = math.floor(ratio * width + 0.5)
  local empty = width - filled
  return string.rep("█", filled) .. string.rep("░", empty)
end

--- Create a popup statusline chrome component.
---
--- Example:
---   bottom = { w.popupmenu_statusline() }
---
--- Supports aligned groups:
---   bottom = { w.popupmenu_statusline({
---     left = { "route", "matches" },
---     center = { "position", "page" },
---     right = { "scroll", "marked", "density", "time" },
---   }) }
---
---@param opts? table
---   - hl?: string Base highlight (default "WildestStatusline" → Comment)
---   - accent_hl?: string Accent highlight for icons/numbers (default "WildestStatuslineAccent" → Special)
---   - hot_hl?: string Highlight for hot/active indicators (default "WildestStatuslineHot" → DiagnosticOk)
---   - separator?: string Between sections (default "  ")
---   - sections?: string[] Which sections to show, in order (left-aligned, backward compat).
---   - left?: string[] Left-aligned sections.
---   - center?: string[] Center-aligned sections.
---   - right?: string[] Right-aligned sections.
---       Available: "route", "matches", "position", "page", "scroll", "marked",
---                  "input", "frecency", "frecency_score", "density", "time", "keys"
---       Defaults (grouped): left={"route","matches","marked"},
---         center={"position","page"}, right={"scroll","frecency_score","time"}
---   - keys?: table<string, string> Key hint label overrides (same as key_hints component)
---   - bar_width?: integer Width of progress/density bars (default 8)
---@return function chrome_component
function M.new(opts)
  opts = opts or {}
  local base_hl = opts.hl or "WildestStatusline"
  local accent_hl = opts.accent_hl or "WildestStatuslineAccent"
  local hot_hl = opts.hot_hl or "WildestStatuslineHot"
  local sep = opts.separator or "  "
  local key_labels = opts.keys or {}
  local bar_width = opts.bar_width or 8

  -- Determine layout mode: grouped (left/center/right) or flat (sections)
  local has_groups = opts.left or opts.center or opts.right
  local has_sections = opts.sections
  local groups, sections
  if has_groups then
    groups = {
      left = opts.left or {},
      center = opts.center or {},
      right = opts.right or {},
    }
  elseif has_sections then
    sections = opts.sections
  else
    -- Sensible defaults: grouped alignment
    groups = {
      left = { "route", "matches", "marked" },
      center = { "position", "page" },
      right = { "scroll", "frecency_score", "time" },
    }
  end

  pcall(vim.api.nvim_set_hl, 0, "WildestStatusline", { link = "Comment", default = true })
  pcall(vim.api.nvim_set_hl, 0, "WildestStatuslineAccent", { link = "Special", default = true })
  pcall(vim.api.nvim_set_hl, 0, "WildestStatuslineHot", { link = "DiagnosticOk", default = true })

  --- Build chunk array for a section
  ---@param name string section name
  ---@param ctx table chrome context
  ---@param result table pipeline result
  ---@return table[]|nil chunks { {text, hl}, ... }
  local function build_section(name, ctx, result)
    local total = ctx.total or 0

    if name == "matches" then
      if total == 0 then
        return { { " no matches", base_hl } }
      end
      return { { " ", accent_hl }, { tostring(total), accent_hl } }
    end

    if name == "position" then
      local selected = ctx.selected
      if not selected or selected < 0 or total == 0 then
        return nil
      end
      return {
        { "[", base_hl },
        { tostring(selected + 1), accent_hl },
        { "/", base_hl },
        { tostring(total), accent_hl },
        { "]", base_hl },
      }
    end

    if name == "page" then
      if total == 0 then
        return nil
      end
      local page_start = ctx.page_start or 0
      local page_end = ctx.page_end or 0
      local page_size = page_end - page_start + 1
      if page_size <= 0 then
        return nil
      end
      local total_pages = math.ceil(total / page_size)
      if total_pages <= 1 then
        return nil
      end
      local current_page = math.floor(page_start / page_size) + 1
      return {
        { "pg ", base_hl },
        { tostring(current_page), accent_hl },
        { "/", base_hl },
        { tostring(total_pages), accent_hl },
      }
    end

    if name == "scroll" then
      if total == 0 then
        return nil
      end
      local page_start = ctx.page_start or 0
      local page_end = ctx.page_end or 0
      local page_size = page_end - page_start + 1
      if page_size >= total then
        return nil
      end
      local pct = math.floor((page_start / (total - page_size)) * 100 + 0.5)
      return { { tostring(pct) .. "%", accent_hl } }
    end

    if name == "marked" then
      local marked = ctx.marked
      if not marked then
        return nil
      end
      local count = 0
      for _ in pairs(marked) do
        count = count + 1
      end
      if count == 0 then
        return nil
      end
      return {
        { " ", hot_hl },
        { tostring(count), hot_hl },
        { " marked", base_hl },
      }
    end

    if name == "route" then
      local label = route_label(result)
      if not label then
        local ok, cmdtype = pcall(vim.fn.getcmdtype)
        if ok then
          local info = route_icons[cmdtype]
          if info then
            return { { info.icon .. " " .. info.label, base_hl } }
          end
        end
        return nil
      end
      return { { " " .. label, accent_hl } }
    end

    if name == "input" then
      local data = result.data or {}
      local input = data.input or data.arg or ""
      local len = #input
      if len == 0 then
        return nil
      end
      return {
        { " ", base_hl },
        { tostring(len), accent_hl },
        { " chars", base_hl },
      }
    end

    if name == "frecency" then
      local ok, frecency = pcall(require, "wildest.frecency")
      if not ok then
        return nil
      end
      local data_ok, fdata = pcall(frecency.load)
      if not data_ok or not fdata then
        return nil
      end
      local candidates = result.value or {}
      if #candidates == 0 then
        return nil
      end
      local hot_count = 0
      for _, c in ipairs(candidates) do
        if type(c) == "string" and frecency.score(c, fdata) > 0 then
          hot_count = hot_count + 1
        end
      end
      if hot_count == 0 then
        return nil
      end
      return {
        { " ", hot_hl },
        { tostring(hot_count), hot_hl },
        { " frecent", base_hl },
      }
    end

    if name == "frecency_score" then
      local selected = ctx.selected
      if not selected or selected < 0 then
        return nil
      end
      local candidates = result.value or {}
      local candidate = candidates[selected + 1]
      if not candidate then
        return nil
      end
      local item = type(candidate) == "string" and candidate
        or (candidate.word or candidate[1] or tostring(candidate))
      local ok, frecency = pcall(require, "wildest.frecency")
      if not ok then
        return nil
      end
      local data_ok, fdata = pcall(frecency.load)
      if not data_ok or not fdata then
        return nil
      end
      local score = frecency.score(item, fdata)
      if score == 0 then
        return nil
      end
      return {
        { " ", hot_hl },
        { string.format("%.1f", score), hot_hl },
      }
    end

    if name == "density" then
      if total == 0 then
        return nil
      end
      local page_start = ctx.page_start or 0
      local page_end = ctx.page_end or 0
      local page_size = page_end - page_start + 1
      if page_size >= total then
        return nil
      end
      local ratio = page_size / total
      return { { progress_bar(ratio, bar_width), accent_hl } }
    end

    if name == "time" then
      return { { os.date("%H:%M"), base_hl } }
    end

    if name == "keys" then
      local cfg = config.get()
      local hints = {}
      local function add(key_name, default_label)
        local key = cfg[key_name]
        if not key then
          return
        end
        local k = type(key) == "table" and key[1] or key
        if not k then
          return
        end
        local display = k:gsub("^<(.+)>$", "%1")
        local label = key_labels[key_name] or default_label
        hints[#hints + 1] = { display .. ":" .. label, base_hl }
      end
      if cfg.mark_key then
        add("mark_key", "mark")
      end
      if cfg.confirm_key then
        add("confirm_key", "ok")
      end
      if cfg.actions then
        for key, action in pairs(cfg.actions) do
          if type(action) == "string" then
            local label = key_labels[action]
              or action:gsub("send_to_", ""):gsub("open_", ""):gsub("_", " ")
            local display = key:gsub("^<(.+)>$", "%1")
            hints[#hints + 1] = { display .. ":" .. label, base_hl }
          end
        end
      end
      if #hints == 0 then
        return nil
      end
      local chunks = {}
      for i, h in ipairs(hints) do
        if i > 1 then
          chunks[#chunks + 1] = { " ", base_hl }
        end
        chunks[#chunks + 1] = h
      end
      return chunks
    end

    return nil
  end

  -- Measure display width of a chunk array
  local function chunks_width(chunks)
    local w = 0
    for _, c in ipairs(chunks) do
      w = w + vim.api.nvim_strwidth(c[1])
    end
    return w
  end

  -- Build chunks for a list of section names, joined by separator
  local function build_group(section_names, ctx, result)
    local group_chunks = {}
    local total_w = 0
    for _, name in ipairs(section_names) do
      local sc = build_section(name, ctx, result)
      if sc then
        if #group_chunks > 0 then
          group_chunks[#group_chunks + 1] = { sep, base_hl }
          total_w = total_w + vim.api.nvim_strwidth(sep)
        end
        for _, c in ipairs(sc) do
          group_chunks[#group_chunks + 1] = c
        end
        total_w = total_w + chunks_width(sc)
      end
    end
    return group_chunks, total_w
  end

  -- Truncate a chunk array to fit within max_w characters
  local function truncate_chunks(chunks, max_w)
    local out = {}
    local w = 0
    for _, c in ipairs(chunks) do
      local cw = vim.api.nvim_strwidth(c[1])
      if w + cw > max_w then
        local remain = max_w - w
        if remain > 0 then
          local trimmed = ""
          local tw = 0
          for _, ch in vim.iter(vim.fn.split(c[1], "\\zs")):enumerate() do
            local chw = vim.api.nvim_strwidth(ch)
            if tw + chw > remain then
              break
            end
            trimmed = trimmed .. ch
            tw = tw + chw
          end
          out[#out + 1] = { trimmed, c[2] }
        end
        break
      end
      out[#out + 1] = c
      w = w + cw
    end
    return out
  end

  return function(ctx)
    local result = ctx.result or { value = {}, data = {} }
    ctx.marked = ctx.marked or require("wildest.state").get().marked
    ctx.session_id = ctx.session_id or require("wildest.state").get().session_id

    local width = ctx.width
    local sep_w = vim.api.nvim_strwidth(sep)

    if groups then
      -- Grouped mode: left/center/right alignment
      local left_chunks, left_w = build_group(groups.left, ctx, result)
      local center_chunks, center_w = build_group(groups.center, ctx, result)
      local right_chunks, right_w = build_group(groups.right, ctx, result)

      if #left_chunks == 0 and #center_chunks == 0 and #right_chunks == 0 then
        return nil
      end

      -- Add 1-char padding on each side
      local pad = 1
      local usable = width - (pad * 2)

      -- Calculate gaps for alignment
      -- Layout: [pad][left][gap_or_center][right][pad]
      local content_w = left_w + center_w + right_w
      local remaining = usable - content_w

      local all_chunks = {}
      -- Left padding
      all_chunks[#all_chunks + 1] = { string.rep(" ", pad), base_hl }

      -- Left group
      for _, c in ipairs(left_chunks) do
        all_chunks[#all_chunks + 1] = c
      end

      if remaining >= 0 then
        if #center_chunks > 0 then
          -- Center: place center group in the middle of usable space
          local center_start = math.floor((usable - center_w) / 2)
          local gap_left = center_start - left_w
          if gap_left < 1 then
            gap_left = 1
          end
          all_chunks[#all_chunks + 1] = { string.rep(" ", gap_left), base_hl }
          for _, c in ipairs(center_chunks) do
            all_chunks[#all_chunks + 1] = c
          end
          local gap_right = usable - left_w - gap_left - center_w - right_w
          if gap_right < 1 then
            gap_right = 1
          end
          all_chunks[#all_chunks + 1] = { string.rep(" ", gap_right), base_hl }
        else
          -- No center: fill gap between left and right
          local gap = usable - left_w - right_w
          if gap < 1 then
            gap = 1
          end
          all_chunks[#all_chunks + 1] = { string.rep(" ", gap), base_hl }
        end
      else
        -- Content overflows — just use minimal spacing
        if #center_chunks > 0 then
          all_chunks[#all_chunks + 1] = { sep, base_hl }
          for _, c in ipairs(center_chunks) do
            all_chunks[#all_chunks + 1] = c
          end
        end
        all_chunks[#all_chunks + 1] = { " ", base_hl }
      end

      -- Right group
      for _, c in ipairs(right_chunks) do
        all_chunks[#all_chunks + 1] = c
      end

      -- Right padding
      all_chunks[#all_chunks + 1] = { string.rep(" ", pad), base_hl }

      return all_chunks
    end

    -- Flat sections mode (backward compatible): wrapping layout
    local section_chunks = {}
    for _, section_name in ipairs(sections) do
      local chunks = build_section(section_name, ctx, result)
      if chunks then
        section_chunks[#section_chunks + 1] = chunks
      end
    end

    if #section_chunks == 0 then
      return nil
    end

    local prefix = " "
    local prefix_w = vim.api.nvim_strwidth(prefix)

    -- Pack sections into rows that fit within width
    local rows = {}
    local current_row = {}
    local current_w = prefix_w

    for i, sc in ipairs(section_chunks) do
      local sc_w = chunks_width(sc)
      local need = sc_w + (i > 1 and #current_row > 0 and sep_w or 0)

      if #current_row > 0 and current_w + need > width then
        rows[#rows + 1] = current_row
        current_row = {}
        current_w = prefix_w
      end

      if #current_row > 0 then
        current_w = current_w + sep_w
      end
      current_row[#current_row + 1] = sc
      current_w = current_w + sc_w
    end
    if #current_row > 0 then
      rows[#rows + 1] = current_row
    end

    -- Build chunk arrays per row, joined by newlines for multi-line chrome
    local all_chunks = {}
    for row_idx, row in ipairs(rows) do
      if row_idx > 1 then
        all_chunks[#all_chunks + 1] = { "\n", base_hl }
      end
      local row_chunks = { { prefix, base_hl } }
      for si, sc in ipairs(row) do
        if si > 1 then
          row_chunks[#row_chunks + 1] = { sep, base_hl }
        end
        for _, c in ipairs(sc) do
          row_chunks[#row_chunks + 1] = c
        end
      end
      local row_w = chunks_width(row_chunks)
      if row_w > width then
        local truncated = truncate_chunks(row_chunks, width - 1)
        for _, c in ipairs(truncated) do
          all_chunks[#all_chunks + 1] = c
        end
      else
        for _, c in ipairs(row_chunks) do
          all_chunks[#all_chunks + 1] = c
        end
      end
    end

    return all_chunks
  end
end

return M

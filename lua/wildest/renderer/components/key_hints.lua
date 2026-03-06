---@mod wildest.renderer.components.key_hints Key Hints Component
---@brief [[
---Bottom/top chrome component that shows contextual keybinding hints.
---Reads from the user's wildest config so hints always match their bindings.
---@brief ]]

local config = require("wildest.config")

local M = {}

--- Normalize a key spec (string or string[]) to a single display string.
---@param key string|string[]|nil
---@return string|nil
local function first_key(key)
  if type(key) == "table" then
    return key[1]
  end
  return key
end

--- Format a single hint: "key:label"
---@param key string|string[]|nil
---@param label string
---@return string|nil
local function fmt(key, label)
  local k = first_key(key)
  if not k then
    return nil
  end
  -- Strip angle brackets for compact display: <C-q> → C-q
  local display = k:gsub("^<(.+)>$", "%1")
  return display .. ":" .. label
end

--- Create a key hints chrome component.
--- Shows available keybindings derived from the user's wildest config.
---
--- Example:
---   bottom = { w.popupmenu_key_hints() }
---
---@param opts? table
---   - hl?: string Highlight group for hints (default "WildestKeyHints" → Comment)
---   - separator?: string Separator between hints (default "  ")
---   - prefix?: string Text before hints (default " ")
---   - keys?: table<string, string> Override labels: { next_key = "next", mark_key = "mark", ... }
---@return function chrome_component
function M.new(opts)
  opts = opts or {}
  local hl = opts.hl or "WildestKeyHints"
  local sep = opts.separator or "  "
  local prefix = opts.prefix or " "
  local label_overrides = opts.keys or {}

  pcall(vim.api.nvim_set_hl, 0, "WildestKeyHints", { link = "Comment", default = true })

  return function(ctx)
    local cfg = config.get()
    local hints = {}

    -- Navigation
    local nav_labels = {
      { "next_key", "next" },
      { "previous_key", "prev" },
      { "accept_key", "accept" },
      { "confirm_key", "confirm" },
    }
    for _, pair in ipairs(nav_labels) do
      local key_name, default_label = pair[1], pair[2]
      local label = label_overrides[key_name] or default_label
      local h = fmt(cfg[key_name], label)
      if h then
        hints[#hints + 1] = h
      end
    end

    -- Multi-select (only if configured)
    if cfg.mark_key then
      local h = fmt(cfg.mark_key, label_overrides.mark_key or "mark")
      if h then
        hints[#hints + 1] = h
      end
    end
    if cfg.unmark_key then
      local h = fmt(cfg.unmark_key, label_overrides.unmark_key or "unmark")
      if h then
        hints[#hints + 1] = h
      end
    end

    -- Actions
    if cfg.actions then
      for key, action in pairs(cfg.actions) do
        local label
        if type(action) == "string" then
          -- Use override or derive short label from action name
          label = label_overrides[action] or action:gsub("_", " "):gsub("send to ", "")
        end
        if label then
          local h = fmt(key, label)
          if h then
            hints[#hints + 1] = h
          end
        end
      end
    end

    if #hints == 0 then
      return nil
    end

    local text = prefix .. table.concat(hints, sep)
    -- Truncate to width
    local text_w = vim.api.nvim_strwidth(text)
    if text_w > ctx.width then
      local truncated = ""
      local dw = 0
      for _, ch in vim.iter(vim.fn.split(text, "\\zs")):enumerate() do
        local chw = vim.api.nvim_strwidth(ch)
        if dw + chw > ctx.width - 3 then
          break
        end
        truncated = truncated .. ch
        dw = dw + chw
      end
      text = truncated .. "..."
    end

    return { { text, hl } }
  end
end

return M

---@mod wildest.docs Documentation Hints
---@brief [[
---Extracts brief documentation for command-line completions from Neovim's
---help system, option metadata, and command registry.
---@brief ]]

local M = {}

--- Simple LRU cache for doc lookups.
---@class wildest.DocsCache
---@field _data table<string, string|false>
---@field _keys string[]
---@field _max integer
local Cache = {}
Cache.__index = Cache

function Cache.new(max)
  return setmetatable({ _data = {}, _keys = {}, _max = max or 200 }, Cache)
end

function Cache:get(key)
  local v = self._data[key]
  if v ~= nil then
    return v
  end
  return nil
end

function Cache:set(key, value)
  if self._data[key] == nil then
    table.insert(self._keys, key)
    if #self._keys > self._max then
      local old = table.remove(self._keys, 1)
      self._data[old] = nil
    end
  end
  self._data[key] = value
end

local cache = Cache.new(300)

--- Extract a one-line description from a help file for a given tag.
--- Returns nil if not found.
---@param tag string help tag to look up
---@return string|nil
local function help_oneliner(tag)
  local tags = vim.fn.taglist("^" .. vim.fn.escape(tag, "\\[].*~") .. "$")
  if not tags or #tags == 0 then
    return nil
  end

  local entry = tags[1]
  local fname = entry.filename
  if not fname or fname == "" then
    return nil
  end

  local ok, lines = pcall(vim.fn.readfile, fname, "", 500)
  if not ok or not lines or #lines == 0 then
    return nil
  end

  -- Find the tag line — tags look like *tag* at the start or end of a line
  local tag_pattern = "%*" .. vim.pesc(tag) .. "%*"
  local start_line = nil
  for i, line in ipairs(lines) do
    if line:match(tag_pattern) then
      start_line = i
      break
    end
  end

  if not start_line then
    return nil
  end

  -- Look at lines after the tag for the first non-empty, non-header line
  for i = start_line, math.min(start_line + 8, #lines) do
    local line = lines[i]
    -- Skip the tag line itself, separator lines, and empty lines
    if i > start_line then
      -- Strip leading whitespace for cleaner output
      local stripped = line:match("^%s*(.-)%s*$")
      if stripped and stripped ~= "" and not stripped:match("^[=~-]+$") then
        -- Skip lines that are just other tags
        if not stripped:match("^%*[^ ]+%*%s*$") then
          -- Truncate at a reasonable length
          if #stripped > 80 then
            stripped = stripped:sub(1, 77) .. "..."
          end
          return stripped
        end
      end
    else
      -- The tag line itself might contain description after the tag
      local after_tag = line:match(tag_pattern .. "%s+(.+)$")
      if after_tag then
        local stripped = after_tag:match("^(.-)%s*$")
        if stripped and stripped ~= "" and not stripped:match("^[=~-]+$") then
          if #stripped > 80 then
            stripped = stripped:sub(1, 77) .. "..."
          end
          return stripped
        end
      end
    end
  end

  return nil
end

--- Get documentation for a Vim option.
---@param name string option name
---@return string|nil
function M.option_doc(name)
  local key = "opt:" .. name
  local cached = cache:get(key)
  if cached ~= nil then
    return cached or nil
  end

  -- Try nvim_get_option_info2 for structural info
  local ok, info = pcall(vim.api.nvim_get_option_info2, name, {})
  if ok and info and info.name then
    local parts = {}

    -- Type
    if info.type then
      parts[#parts + 1] = info.type
    end

    -- Scope
    if info.scope then
      parts[#parts + 1] = "scope:" .. info.scope
    end

    -- Default value
    if info.default ~= nil then
      local default_str = tostring(info.default)
      if type(info.default) == "string" then
        if #default_str > 30 then
          default_str = default_str:sub(1, 27) .. "..."
        end
        default_str = '"' .. default_str .. '"'
      end
      parts[#parts + 1] = "default:" .. default_str
    end

    local meta = table.concat(parts, " ")

    -- Try to get a prose description from help
    local help_text = help_oneliner("'" .. name .. "'")
    local doc
    if help_text then
      doc = help_text .. "  [" .. meta .. "]"
    else
      doc = meta
    end

    cache:set(key, doc)
    return doc
  end

  -- Fallback: try help lookup
  local help_text = help_oneliner("'" .. name .. "'")
  if help_text then
    cache:set(key, help_text)
    return help_text
  end

  cache:set(key, false)
  return nil
end

--- Get documentation for a command.
---@param name string command name
---@return string|nil
function M.command_doc(name)
  local key = "cmd:" .. name
  local cached = cache:get(key)
  if cached ~= nil then
    return cached or nil
  end

  -- Try help lookup for :command
  local help_text = help_oneliner(":" .. name)
  if help_text then
    cache:set(key, help_text)
    return help_text
  end

  -- Try user command registry
  local ok, cmds = pcall(vim.api.nvim_get_commands, {})
  if ok and cmds and cmds[name] then
    local cmd_info = cmds[name]
    local parts = {}
    if cmd_info.nargs and cmd_info.nargs ~= "0" then
      parts[#parts + 1] = "nargs:" .. cmd_info.nargs
    end
    if cmd_info.definition and cmd_info.definition ~= "" then
      local def = cmd_info.definition
      if #def > 60 then
        def = def:sub(1, 57) .. "..."
      end
      parts[#parts + 1] = def
    end
    if #parts > 0 then
      local doc = table.concat(parts, " ")
      cache:set(key, doc)
      return doc
    end
  end

  cache:set(key, false)
  return nil
end

--- Get documentation for a help tag.
---@param tag string help tag
---@return string|nil
function M.help_doc(tag)
  local key = "help:" .. tag
  local cached = cache:get(key)
  if cached ~= nil then
    return cached or nil
  end

  local doc = help_oneliner(tag)
  cache:set(key, doc or false)
  return doc
end

--- Get documentation for an event name.
---@param name string autocmd event
---@return string|nil
function M.event_doc(name)
  local key = "event:" .. name
  local cached = cache:get(key)
  if cached ~= nil then
    return cached or nil
  end

  local doc = help_oneliner(name)
  cache:set(key, doc or false)
  return doc
end

--- Get documentation for a highlight group.
---@param name string highlight group name
---@return string|nil
function M.highlight_doc(name)
  local key = "hl:" .. name
  local cached = cache:get(key)
  if cached ~= nil then
    return cached or nil
  end

  -- Show current highlight definition
  local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = name })
  if ok and hl then
    local parts = {}
    if hl.link then
      parts[#parts + 1] = "links to " .. hl.link
    else
      if hl.fg then
        parts[#parts + 1] = string.format("fg:#%06x", hl.fg)
      end
      if hl.bg then
        parts[#parts + 1] = string.format("bg:#%06x", hl.bg)
      end
      if hl.bold then
        parts[#parts + 1] = "bold"
      end
      if hl.italic then
        parts[#parts + 1] = "italic"
      end
      if hl.underline then
        parts[#parts + 1] = "underline"
      end
    end
    if #parts > 0 then
      local doc = table.concat(parts, " ")
      cache:set(key, doc)
      return doc
    end
  end

  cache:set(key, false)
  return nil
end

--- Generic lookup that routes to the right strategy based on expand type.
---@param candidate string the completion candidate
---@param expand string|nil the expand type from pipeline data
---@param cmd string|nil the command being completed
---@return string|nil
function M.lookup(candidate, expand, cmd)
  if not candidate or candidate == "" then
    return nil
  end

  if expand == "option" then
    return M.option_doc(candidate)
  elseif expand == "command" or expand == "user_commands" then
    return M.command_doc(candidate)
  elseif expand == "help" then
    return M.help_doc(candidate)
  elseif expand == "event" then
    return M.event_doc(candidate)
  elseif expand == "highlight" then
    return M.highlight_doc(candidate)
  elseif expand == "color" then
    -- Colorschemes don't have useful help, skip
    return nil
  end

  -- For unknown expand types, try generic help lookup
  if expand and expand ~= "" then
    return M.help_doc(candidate)
  end

  -- If we know the command, try looking up the candidate as a help tag
  if cmd and cmd ~= "" then
    return M.help_doc(candidate)
  end

  return nil
end

--- Clear the documentation cache.
function M.clear_cache()
  cache = Cache.new(300)
end

return M

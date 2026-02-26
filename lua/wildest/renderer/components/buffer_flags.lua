---@mod wildest.renderer.components.buffer_flags Buffer Status Flags Component
---@brief [[
---Buffer status flags component.
---@brief ]]

local M = {}

--- Create a buffer flags component for the popupmenu
--- Shows buffer status indicators (modified, readonly, etc.)
---
--- Flag characters:
---   '1' = buffer number
---   '%' = current buffer indicator
---   '#' = alternate buffer
---   '+' = modified flag
---   '-' = readonly/nomodifiable flag
---   'a' = active (loaded + visible) / hidden indicator
---   'u' = unlisted buffer
---   ' ' = spacing
---
---@param opts? table { flags?: string, icons?: table, hl?: string, selected_hl?: string }
---@return table component
function M.new(opts)
  opts = opts or {}
  local flags_str = opts.flags or "%+- "
  local icons = opts.icons or {}
  local default_hl = opts.hl
  local selected_hl = opts.selected_hl

  -- Default icons
  local default_icons = {
    ["%"] = "%",
    ["#"] = "#",
    ["+"] = "+",
    ["-"] = "-",
    ["="] = "=",
    ["a"] = "a",
    ["h"] = "h",
    ["u"] = "u",
  }
  icons = vim.tbl_extend("force", default_icons, icons)

  local component = {}

  -- Cache: cleared per session
  local cache = {}
  local last_session_id = -1

  --- Get the flag string for a single flag character
  ---@param flag string single flag char
  ---@param bufnr integer
  ---@return string
  local function get_flag(flag, bufnr)
    if flag == " " then
      return " "
    end

    if flag == "1" then
      return tostring(bufnr)
    end

    if flag == "%" then
      if bufnr == vim.fn.bufnr("%") then
        return icons["%"]
      end
      return " "
    end

    if flag == "#" then
      if bufnr == vim.fn.bufnr("#") then
        return icons["#"]
      end
      return " "
    end

    if flag == "+" then
      if vim.bo[bufnr].modified then
        return icons["+"]
      end
      return " "
    end

    if flag == "-" then
      if vim.bo[bufnr].readonly then
        return icons["-"]
      elseif not vim.bo[bufnr].modifiable then
        return icons["="]
      end
      return " "
    end

    if flag == "a" then
      if vim.api.nvim_buf_is_loaded(bufnr) then
        -- Check if buffer is visible in any window
        local wins = vim.fn.win_findbuf(bufnr)
        if wins and #wins > 0 then
          return icons["a"]
        else
          return icons["h"]
        end
      end
      return " "
    end

    if flag == "u" then
      if not vim.bo[bufnr].buflisted then
        return icons["u"]
      end
      return " "
    end

    return " "
  end

  function component:render(ctx)
    local hl = ctx.is_selected and (selected_hl or ctx.selected_hl)
      or (default_hl or ctx.default_hl)

    -- Clear cache on new session
    if ctx.result and ctx.result.data and ctx.result.data.session_id then
      if ctx.result.data.session_id ~= last_session_id then
        cache = {}
        last_session_id = ctx.result.data.session_id
      end
    end

    -- Get the candidate
    local candidate = ""
    if ctx.result and ctx.result.value and ctx.index ~= nil then
      candidate = ctx.result.value[ctx.index + 1] or ""
    end

    if candidate == "" then
      return { { "", hl } }
    end

    -- Check cache
    if cache[candidate] then
      return { { cache[candidate], hl } }
    end

    -- Try to find the buffer
    local expanded = vim.fn.fnamemodify(candidate, ":p")
    local bufnr = vim.fn.bufnr(expanded)

    if bufnr == -1 then
      -- Try without full path expansion
      bufnr = vim.fn.bufnr(candidate)
    end

    if bufnr == -1 then
      local result = string.rep(" ", #flags_str)
      cache[candidate] = result
      return { { result, hl } }
    end

    -- Build flags string
    local result = ""
    for i = 1, #flags_str do
      local flag = flags_str:sub(i, i)
      result = result .. get_flag(flag, bufnr)
    end

    cache[candidate] = result
    return { { result, hl } }
  end

  return component
end

return M

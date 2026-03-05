---@mod wildest.ghost_text Ghost Text
---@brief [[
---Inline completion preview shown as dimmed virtual text next to the cmdline.
---Uses a minimal floating window positioned at the end of the cmdline input.
---@brief ]]

local M = {}

---@class wildest.GhostTextConfig
---@field hl_group? string Highlight group for ghost text (default "Comment")

local ns_id = vim.api.nvim_create_namespace("wildest_ghost_text")
local ghost_buf = nil
local ghost_win = nil

--- Ensure the ghost text buffer exists.
---@return integer bufnr
local function ensure_buf()
  if ghost_buf and vim.api.nvim_buf_is_valid(ghost_buf) then
    return ghost_buf
  end
  ghost_buf = vim.api.nvim_create_buf(false, true)
  vim.bo[ghost_buf].bufhidden = "wipe"
  return ghost_buf
end

--- Hide the ghost text window.
function M.hide()
  if ghost_win and vim.api.nvim_win_is_valid(ghost_win) then
    vim.api.nvim_win_hide(ghost_win)
  end
  ghost_win = nil
end

--- Compute the ghost text suffix for the current state.
--- Returns nil if there's nothing to show.
---@param ctx table draw context
---@param result table pipeline result
---@return string|nil suffix The text to show as ghost text
local function compute_suffix(ctx, result)
  local candidates = result.value or {}
  if #candidates == 0 then
    return nil
  end

  -- Only show ghost text when no candidate is selected
  if ctx.selected >= 0 then
    return nil
  end

  local candidate = candidates[1]
  local input = ctx.input or ""

  -- Use result.output to get the full cmdline that would be inserted
  local full
  if result.output then
    full = result.output(result.data, candidate)
  else
    full = candidate
  end

  if type(full) ~= "string" or full == "" then
    return nil
  end

  -- Extract the suffix beyond what's already typed
  -- Case-insensitive prefix check: if the full output starts with the input
  if #full > #input and full:sub(1, #input):lower() == input:lower() then
    return full:sub(#input + 1)
  end

  return nil
end

--- Update the ghost text display.
---@param ctx table draw context
---@param result table pipeline result
---@param opts wildest.GhostTextConfig ghost text config
function M.update(ctx, result, opts)
  local suffix = compute_suffix(ctx, result)
  if not suffix then
    M.hide()
    return
  end

  local hl_group = (opts and opts.hl_group) or "Comment"

  local buf = ensure_buf()

  -- Position: cmdline is at the bottom of the editor
  -- Row: vim.o.lines - 1 is the last editor row (0-indexed), cmdline is below
  local cmdline_row = vim.o.lines - 1
  -- Column: prompt char (1) + cursor position
  local cmdpos = vim.fn.getcmdpos() -- 1-indexed byte position in cmdline
  local prompt_width = 1 -- ':', '/', '?'
  local col = prompt_width + cmdpos - 1

  local suffix_width = vim.api.nvim_strwidth(suffix)
  if suffix_width == 0 then
    M.hide()
    return
  end

  -- Set buffer content
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { suffix })
  vim.api.nvim_buf_clear_namespace(buf, ns_id, 0, -1)
  vim.api.nvim_buf_add_highlight(buf, ns_id, hl_group, 0, 0, -1)

  local win_config = {
    relative = "editor",
    row = cmdline_row,
    col = col,
    width = math.min(suffix_width, vim.o.columns - col),
    height = 1,
    style = "minimal",
    border = "none",
    focusable = false,
    noautocmd = true,
    zindex = 300,
  }

  if win_config.width <= 0 then
    M.hide()
    return
  end

  if ghost_win and vim.api.nvim_win_is_valid(ghost_win) then
    vim.api.nvim_win_set_config(ghost_win, win_config)
    vim.api.nvim_win_set_buf(ghost_win, buf)
  else
    ghost_win = vim.api.nvim_open_win(buf, false, win_config)
    vim.api.nvim_set_option_value("winblend", 0, { win = ghost_win })
  end
end

return M

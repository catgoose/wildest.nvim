---@mod wildest.search Search Pipeline
---@brief [[
---Search mode (/ and ?) completion pipeline.
---@brief ]]

local M = {}

--- Create a buffer search pipeline
--- Searches current buffer lines matching the search pattern
---@param opts? table { max_results?: integer }
---@return table pipeline array
function M.search_pipeline(opts)
  opts = opts or {}
  local max_results = opts.max_results or 50

  local function search(ctx, input)
    if not input or input == "" then
      return false
    end

    -- Only handle search modes
    if ctx.cmdtype ~= "/" and ctx.cmdtype ~= "?" then
      return false
    end

    -- Try to compile the pattern
    local ok, regex = pcall(vim.regex, input)
    if not ok or not regex then
      return false
    end

    -- Search current buffer lines
    local bufnr = vim.api.nvim_get_current_buf()
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

    local matches = {}
    local seen = {}

    for _, line in ipairs(lines) do
      local s = regex:match_str(line)
      if s then
        -- Extract the matched portion
        local trimmed = vim.trim(line)
        if trimmed ~= "" and not seen[trimmed] then
          seen[trimmed] = true
          table.insert(matches, trimmed)
          if #matches >= max_results then
            break
          end
        end
      end
    end

    if #matches == 0 then
      return false
    end

    ctx.arg = input

    return {
      value = matches,
      data = {
        input = input,
        arg = input,
      },
      output = function(_data, _candidate)
        -- For search, just keep the pattern in the cmdline
        return input
      end,
    }
  end

  return { search }
end

return M

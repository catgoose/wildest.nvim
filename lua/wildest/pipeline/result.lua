---@mod wildest.pipeline.result Result Wrapper
---@brief [[
---Result wrapper pipeline step.
---@brief ]]

local M = {}

--- Wrap pipeline output into a result table
--- The result table has { value = candidates, data = metadata }
---@param opts? table { data?: table, output?: fun(ctx,x,data):string }
---@return fun(ctx: table, x: any): table
function M.result(opts)
  opts = opts or {}

  return function(ctx, x)
    local candidates = x
    if type(x) ~= "table" then
      candidates = { x }
    end
    if #candidates == 0 then
      return false
    end

    local data = vim.tbl_extend("force", {}, opts.data or {})
    data.input = ctx.input or ""
    if ctx.arg then
      data.arg = ctx.arg
    end

    local result = {
      value = candidates,
      data = data,
    }

    if opts.output then
      result.output = opts.output
    elseif data.arg ~= nil then
      result.output = function(d, candidate)
        local prefix = d.input:sub(1, #d.input - #d.arg)
        return prefix .. candidate
      end
    end

    return result
  end
end

return M

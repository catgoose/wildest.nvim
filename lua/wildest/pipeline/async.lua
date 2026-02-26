---@mod wildest.pipeline.async Async Pipeline Wrapper
---@brief [[
---Async pipeline wrapper.
---@brief ]]

local pipeline_mod = require("wildest.pipeline")

local M = {}

--- Wrap an async function into a pipeline step
--- The function receives (ctx, input, resolve, reject) — call resolve(result) or reject(err).
--- This is the escape hatch for users who need async operations in their pipelines.
---
--- Example:
---   w.async(function(ctx, input, resolve, reject)
---     vim.system({'grep', '-r', input, '.'}, { text = true }, function(result)
---       vim.schedule(function()
---         resolve(vim.split(result.stdout, '\n', { trimempty = true }))
---       end)
---     end)
---   end)
---
---@param fn fun(ctx: table, input: any, resolve: fun(result: any), reject: fun(err: any))
---@return fun(ctx: table, input: any): function
function M.async(fn)
  return function(ctx, input)
    return function(async_ctx)
      fn(ctx, input, function(result)
        pipeline_mod.resolve(async_ctx, result)
      end, function(err)
        pipeline_mod.reject(async_ctx, err)
      end)
    end
  end
end

return M

---@mod wildest.pipeline.subpipeline Sub-Pipeline Factory
---@brief [[
---Dynamic sub-pipeline factory.
---@brief ]]

local pipeline_mod = require("wildest.pipeline")

local M = {}

--- Create a dynamic sub-pipeline
--- The factory function receives (ctx, x) and returns a pipeline array.
--- That pipeline is then executed with the same ctx and x.
---@param factory fun(ctx: table, x: any): table
---@return function pipeline function
function M.subpipeline(factory)
  return function(ctx, x)
    return function(sub_ctx)
      local sub = factory(ctx, x)
      if not sub or #sub == 0 then
        pipeline_mod.resolve(sub_ctx, x)
        return
      end

      pipeline_mod.run(sub, function(_ctx, result)
        pipeline_mod.resolve(sub_ctx, result)
      end, function(_ctx, err)
        pipeline_mod.reject(sub_ctx, err)
      end, ctx, x)
    end
  end
end

return M

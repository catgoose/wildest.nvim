---@mod wildest.pipeline.branch Branch Combinator
---@brief [[
---Branch combinator — tries sub-pipelines until one succeeds.
---@brief ]]

local log = require("wildest.log")
local pipeline_mod = require("wildest.pipeline")

local M = {}

--- Create a branch pipeline that tries each sub-pipeline until one succeeds
--- If a pipeline returns false/errors, the next one is tried.
--- If all fail, the branch itself fails.
---@param ... table|function sub-pipelines to try
---@return function pipeline function
function M.branch(...)
  local pipelines = { ... }

  return function(ctx, x)
    return function(branch_ctx)
      -- Save the branch's handler_id before running inner pipelines,
      -- since inner pipeline_mod.run calls will overwrite ctx.handler_id
      local branch_handler_id = branch_ctx.handler_id

      log.log("branch", "start", {
        input = ctx.input,
        cmdtype = ctx.cmdtype,
        branch_count = #pipelines,
        run_id = ctx.run_id,
      })

      local function try(i)
        if i > #pipelines then
          log.log("branch", "all_failed", { input = ctx.input, run_id = ctx.run_id })
          branch_ctx.handler_id = branch_handler_id
          pipeline_mod.reject(branch_ctx, "all branches failed")
          return
        end

        local p = pipelines[i]
        if type(p) == "function" then
          p = { p }
        end

        log.log("branch", "try", { index = i, input = ctx.input, run_id = ctx.run_id })

        -- Create a child context so inner runs don't clobber branch_ctx.handler_id
        local child_ctx = {
          run_id = ctx.run_id,
          session_id = ctx.session_id,
          input = ctx.input,
          cmdtype = ctx.cmdtype,
          mode = ctx.mode,
          arg = ctx.arg,
        }

        pipeline_mod.run(p, function(_ctx, result)
          local result_len = type(result) == "table" and (result.value and #result.value or #result)
            or 0
          log.log("branch", "resolved", {
            index = i,
            input = ctx.input,
            result_len = result_len,
            run_id = ctx.run_id,
          })
          -- Restore branch handler_id before resolving
          branch_ctx.handler_id = branch_handler_id
          pipeline_mod.resolve(branch_ctx, result)
        end, function(_ctx, err)
          log.log("branch", "rejected", {
            index = i,
            input = ctx.input,
            err = tostring(err),
            run_id = ctx.run_id,
          })
          -- This branch failed, try next
          try(i + 1)
        end, child_ctx, x)
      end

      try(1)
    end
  end
end

return M

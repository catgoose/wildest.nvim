---@mod wildest.search Search Pipeline
---@brief [[
---Search mode (/ and ?) completion pipeline.
---Supports vim.regex (default) or external tools like rg/grep via the engine option.
---@brief ]]

local M = {}

--- Create a buffer search pipeline
--- Searches current buffer lines matching the search pattern
---@param opts? table { max_results?: integer, fuzzy?: boolean, fuzzy_filter?: function, engine?: "fast"|"vim"|string|string[] }
---@return table pipeline array
function M.search_pipeline(opts)
  opts = opts or {}
  local max_results = opts.max_results or 50

  local buffer_search = require("wildest.buffer_search")

  -- Resolve engine: extract from engine.search table form if needed
  local engine_val = opts.engine
  if type(engine_val) == "table" and not engine_val[1] and engine_val.search then
    engine_val = engine_val.search
  end
  local search_cmd = buffer_search.resolve_engine(engine_val)

  local function search(ctx, input)
    if not input or input == "" then
      return false
    end

    -- Only handle search modes
    if ctx.cmdtype ~= "/" and ctx.cmdtype ~= "?" then
      return false
    end

    local function make_result(matches)
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

    -- Try async external engine if available and buffer is on disk
    local filepath = search_cmd and buffer_search.current_buffer_path()
    if filepath then
      local pipeline_mod = require("wildest.pipeline")
      local state = require("wildest.state")
      local run_id = ctx.run_id

      return function(async_ctx)
        buffer_search.run_external(search_cmd, input, filepath, max_results, function(matches, err)
          -- Stale check
          if run_id ~= state.get().run_id then
            return
          end
          if err then
            pipeline_mod.reject(async_ctx, err)
            return
          end
          if not matches or #matches == 0 then
            -- Fall back: try fuzzy if enabled and external found nothing
            if opts.fuzzy then
              local bufnr = vim.api.nvim_get_current_buf()
              local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
              matches = buffer_search.search_fuzzy(lines, input, max_results)
            end
            if not matches or #matches == 0 then
              pipeline_mod.reject(async_ctx, false)
              return
            end
          end
          ctx.arg = input
          pipeline_mod.resolve(async_ctx, {
            value = matches,
            data = { input = input, arg = input },
            output = function(_data, _candidate)
              return input
            end,
          })
        end)
      end
    end

    -- Sync fallback: vim.regex + optional fuzzy
    local bufnr = vim.api.nvim_get_current_buf()
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

    local matches = buffer_search.search_vim(lines, input, max_results)

    -- Fuzzy fallback when regex fails or finds nothing
    if #matches == 0 and opts.fuzzy then
      matches = buffer_search.search_fuzzy(lines, input, max_results)
    end

    return make_result(matches)
  end

  local pipeline = { search }

  if opts.fuzzy then
    local fuzzy_filter = opts.fuzzy_filter or require("wildest.filter").fuzzy_filter()
    table.insert(pipeline, fuzzy_filter)
  end

  return pipeline
end

return M

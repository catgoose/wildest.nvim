---@mod wildest.pipeline.vim_complete Vim Completion Wrapper
---@brief [[
---Vim getcompletion() wrapper.
---@brief ]]

local M = {}

--- Create a pipeline step that calls vim.fn.getcompletion()
--- This is the easiest way to tap into Vim's built-in completions.
---
--- Example:
---   w.vim_complete('command')        -- complete command names
---   w.vim_complete('file')           -- complete file paths
---   w.vim_complete('help')           -- complete help tags
---   w.vim_complete('option')         -- complete options
---   w.vim_complete('buffer')         -- complete buffer names
---   w.vim_complete('color')          -- complete colorschemes
---   w.vim_complete(function(ctx)     -- dynamic type based on context
---     return ctx.expand or 'file'
---   end)
---
---@param complete_type string|fun(ctx: table): string completion type for getcompletion
---@param opts? table { use_arg?: boolean }
---@return fun(ctx: table, input: string): string[]|false
function M.vim_complete(complete_type, opts)
  opts = opts or {}

  return function(ctx, input)
    local ctype = complete_type
    if type(ctype) == "function" then
      ctype = ctype(ctx)
    end

    local query = input
    if opts.use_arg and ctx.arg then
      query = ctx.arg
    end

    local ok, results = pcall(vim.fn.getcompletion, query or "", ctype)
    if not ok or not results or #results == 0 then
      return false
    end
    return results
  end
end

return M

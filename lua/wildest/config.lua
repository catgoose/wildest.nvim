---@mod wildest.config Configuration
---@brief [[
---Configuration management for wildest.nvim.
---
---Call `require('wildest').setup(opts)` to set configuration. The opts table is
---merged with defaults using `vim.tbl_deep_extend`.
---@brief ]]

---@class wildest.Config
---@field modes? string[] Cmdline modes to enable (default: { ':', '/', '?' })
---@field next_key? string|string[] Key(s) to select next candidate (default: '<Tab>')
---@field previous_key? string|string[] Key(s) to select previous candidate (default: '<S-Tab>')
---@field accept_key? string|string[] Key(s) to accept current selection (default: '<Down>')
---@field reject_key? string|string[] Key(s) to reject and restore original (default: '<Up>')
---@field scroll_up_key? string|string[] Key(s) to scroll up by page (default: '<C-b>')
---@field scroll_down_key? string|string[] Key(s) to scroll down by page (default: '<C-f>')
---@field scroll_size? integer Number of items to scroll per page (default: 10)
---@field close_key? string|string[] Key(s) to close popup but stay in cmdline (default: '<C-e>')
---@field confirm_key? string|string[] Key(s) to accept selection and execute (default: '<C-y>')
---@field dismiss_key? string|string[] Key(s) to dismiss popup and restore input (default: nil)
---@field jump_keys? table[] Custom jump bindings: { { key, count } ... } e.g. { { "<C-n>", 5 }, { "<C-p>", -10 } }
---@field interval? integer Debounce interval in ms (default: 100)
---@field num_workers? integer Number of async workers (default: 2)
---@field noselect? boolean No item selected initially (default: true)
---@field trigger? 'auto'|'tab' When to show completions (default: 'auto')
---@field longest_prefix? boolean Insert longest common prefix on first Tab (default: false)
---@field pipeline_timeout? integer Timeout in ms for pipeline steps, 0 = no timeout (default: 0)
---@field skip_commands? string[] Commands to skip completions for (default: {})
---@field min_input? integer Minimum input length before showing completions (default: 0)
---@field pipeline? wildest.PipelineStep|wildest.PipelineStep[] Pipeline steps or single pipeline step
---@field renderer? wildest.Renderer Renderer instance

local M = {}

local defaults = {
  modes = { ":", "/", "?" },
  next_key = "<Tab>",
  previous_key = "<S-Tab>",
  accept_key = "<Down>",
  reject_key = "<Up>",
  scroll_up_key = "<C-b>",
  scroll_down_key = "<C-f>",
  scroll_size = 10,
  close_key = "<C-e>",
  confirm_key = "<C-y>",
  dismiss_key = nil,
  jump_keys = {},
  interval = 100, -- debounce interval in ms
  num_workers = 2,

  -- Selection behavior:
  --   noselect = true:  no item selected initially (user must press next_key)
  --   noselect = false: first item visually selected but NOT inserted (like noinsert)
  noselect = true,

  -- Trigger behavior:
  --   trigger = 'auto':  completions shown as you type
  --   trigger = 'tab':   completions only shown after pressing next_key
  trigger = "auto",

  -- longest_prefix: when true, insert the longest common prefix on first Tab
  -- instead of cycling through candidates (like wildmode=list:longest)
  longest_prefix = false,

  -- Timeout in ms for expensive completions. If a pipeline step takes longer
  -- than this, it gets cancelled. 0 = no timeout.
  pipeline_timeout = 0,

  -- List of command names to skip completions for (e.g., expensive commands)
  skip_commands = {},

  -- Minimum input length before showing completions:
  --   0 = show immediately on CmdlineEnter
  --   1 = after first character
  --   2+ = after N characters
  min_input = 0,

  pipeline = nil, -- must be set by user
  renderer = nil, -- must be set by user
}

--- Current resolved config
M._config = vim.deepcopy(defaults)

---Validate and merge user config with defaults.
---@param opts? wildest.Config
---@return wildest.Config
function M.setup(opts)
  opts = opts or {}
  M._config = vim.tbl_deep_extend("force", vim.deepcopy(defaults), opts)

  -- Validate modes
  for _, mode in ipairs(M._config.modes) do
    if mode ~= ":" and mode ~= "/" and mode ~= "?" then
      vim.notify("[wildest] Invalid mode: " .. mode .. ". Must be :, / or ?", vim.log.levels.WARN)
    end
  end

  return M._config
end

---Get current config value, or the full config table if key is nil.
---@param key? string Config key to retrieve
---@return any
function M.get(key)
  if key == nil then
    return M._config
  end
  return M._config[key]
end

return M

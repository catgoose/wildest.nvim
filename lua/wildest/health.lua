---@mod wildest.health Health Check
---@brief [[
---Health check for :checkhealth wildest.
---@brief ]]

local M = {}

function M.check()
  vim.health.start("wildest.nvim")

  -- Neovim version
  if vim.fn.has("nvim-0.10") == 1 then
    vim.health.ok("Neovim >= 0.10")
  else
    vim.health.error("Neovim >= 0.10 required")
  end

  -- C FFI fuzzy module
  local filter_ok, filter = pcall(require, "wildest.filter")
  if filter_ok and filter then
    local has_match_ok = pcall(filter.has_match, "a", "abc")
    if has_match_ok then
      vim.health.ok("C FFI fuzzy module loaded (fuzzy.so)")
    else
      vim.health.warn("C FFI fuzzy module failed to initialize — run `make` in csrc/")
    end
  else
    vim.health.warn("C FFI fuzzy module not available — run `make` in csrc/")
  end

  -- Setup status
  local config = require("wildest.config")
  local cfg = config.get()
  if cfg and cfg.pipeline then
    vim.health.ok("wildest.setup() has been called")
  else
    vim.health.warn("wildest.setup() has not been called yet, or no pipeline configured")
  end

  -- Optional: nvim-web-devicons
  local has_devicons = pcall(require, "nvim-web-devicons")
  if has_devicons then
    vim.health.ok("nvim-web-devicons available")
  else
    vim.health.info("nvim-web-devicons not installed (optional, for file type icons)")
  end

  -- Log file
  local log = require("wildest.log")
  vim.health.info("Log file: " .. log.path())
end

return M

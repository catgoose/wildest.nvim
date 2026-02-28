local themes = require("wildest.themes")

--- Outlaw theme: dark and dangerous, crimson accents
--- For the cowboy who rides alone.
return themes.define({
  renderer = "border",
  highlights = {
    WildestDefault = { bg = "#1a1a2e", fg = "#c8c8d0" },
    WildestSelected = { bg = "#3d0c11", fg = "#ffffff", bold = true },
    WildestAccent = { bg = "#1a1a2e", fg = "#e74c3c", bold = true },
    WildestSelectedAccent = { bg = "#3d0c11", fg = "#ff6b6b", bold = true, underline = true },
    WildestBorder = { bg = "#0f0f1a", fg = "#e74c3c" },
    WildestPrompt = { bg = "#1a1a2e", fg = "#c8c8d0" },
    WildestPromptCursor = { bg = "#e74c3c", fg = "#ffffff" },
    WildestSpinner = { fg = "#e74c3c" },
  },
  renderer_opts = {
    border = "single",
  },
})

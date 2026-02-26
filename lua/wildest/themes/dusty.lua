local themes = require("wildest.themes")

--- Dusty theme: muted desert colors, sandstone and sage
--- The calm before the dust storm.
return themes.define({
  renderer = "border",
  highlights = {
    WildestDefault = { bg = "#2d2a24", fg = "#c4b99a" },
    WildestSelected = { bg = "#4a4438", fg = "#f0e8d0", bold = true },
    WildestAccent = { bg = "#2d2a24", fg = "#c9a96e", bold = true },
    WildestSelectedAccent = { bg = "#4a4438", fg = "#e8c888", bold = true, underline = true },
    WildestBorder = { bg = "#201e1a", fg = "#7a7060" },
    WildestPrompt = { bg = "#2d2a24", fg = "#c4b99a" },
    WildestPromptCursor = { bg = "#c9a96e", fg = "#2d2a24" },
    WildestSpinner = { fg = "#c9a96e" },
  },
  renderer_opts = {
    border = "single",
    left = { " " },
    right = { " " },
  },
})

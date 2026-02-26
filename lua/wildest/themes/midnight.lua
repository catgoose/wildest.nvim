local themes = require("wildest.themes")

--- Midnight theme: deep blues and silver starlight
--- Riding under the stars, nothing but open sky.
return themes.define({
  renderer = "border",
  highlights = {
    WildestDefault = { bg = "#0d1b2a", fg = "#a8c4e0" },
    WildestSelected = { bg = "#1b3a5c", fg = "#e0f0ff", bold = true },
    WildestAccent = { bg = "#0d1b2a", fg = "#5dade2", bold = true },
    WildestSelectedAccent = { bg = "#1b3a5c", fg = "#85c1e9", bold = true, underline = true },
    WildestBorder = { bg = "#08111c", fg = "#3a7ca5" },
    WildestPrompt = { bg = "#0d1b2a", fg = "#a8c4e0" },
    WildestPromptCursor = { bg = "#5dade2", fg = "#0d1b2a" },
    WildestSpinner = { fg = "#5dade2" },
  },
  renderer_opts = {
    border = "rounded",
    left = { " " },
    right = { " " },
  },
})

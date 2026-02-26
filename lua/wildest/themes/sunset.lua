local themes = require("wildest.themes")

--- Sunset theme: warm gradient from orange to purple
--- Like watching the sun set over the mesa.
return themes.define({
  renderer = "border",
  highlights = {
    WildestDefault = { bg = "#1e1226", fg = "#e0c4a8" },
    WildestSelected = { bg = "#4a2040", fg = "#ffeedd", bold = true },
    WildestAccent = { bg = "#1e1226", fg = "#ff7043", bold = true },
    WildestSelectedAccent = { bg = "#4a2040", fg = "#ffab91", bold = true, underline = true },
    WildestBorder = { bg = "#140c1a", fg = "#c77dba" },
    WildestPrompt = { bg = "#1e1226", fg = "#e0c4a8" },
    WildestPromptCursor = { bg = "#ff7043", fg = "#1e1226" },
    WildestSpinner = { fg = "#ff7043" },
  },
  renderer_opts = {
    border = "rounded",
    left = { " " },
    right = { " " },
  },
})

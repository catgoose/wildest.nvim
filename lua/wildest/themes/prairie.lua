local themes = require("wildest.themes")

--- Prairie theme: soft greens and earth tones
--- Wide open grasslands under a clear sky.
return themes.define({
  renderer = "border",
  highlights = {
    WildestDefault = { bg = "#1d2a1d", fg = "#b8c9a3" },
    WildestSelected = { bg = "#2d4a2d", fg = "#e0f0d0", bold = true },
    WildestAccent = { bg = "#1d2a1d", fg = "#7ec87e", bold = true },
    WildestSelectedAccent = { bg = "#2d4a2d", fg = "#a0e8a0", bold = true, underline = true },
    WildestBorder = { bg = "#131f13", fg = "#5a8a5a" },
    WildestPrompt = { bg = "#1d2a1d", fg = "#b8c9a3" },
    WildestPromptCursor = { bg = "#7ec87e", fg = "#1d2a1d" },
    WildestSpinner = { fg = "#7ec87e" },
  },
  renderer_opts = {
    border = "rounded",
  },
})

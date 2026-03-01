local themes = require("wildest.themes")

--- Saloon theme: warm amber and whiskey tones
--- Like stepping into a dimly-lit frontier saloon.
return themes.define({
  renderer = "border",
  highlights = {
    WildestDefault = { bg = "#2b1d0e", fg = "#d4a76a" },
    WildestSelected = { bg = "#5c3a1e", fg = "#ffe0a6", bold = true },
    WildestAccent = { bg = "#2b1d0e", fg = "#ff9f43", bold = true },
    WildestSelectedAccent = { bg = "#5c3a1e", fg = "#ffcc00", bold = true, underline = true },
    WildestBorder = { bg = "#1a1008", fg = "#8b6914" },
    WildestPrompt = { bg = "#2b1d0e", fg = "#d4a76a" },
    WildestPromptCursor = { bg = "#ff9f43", fg = "#1a1008" },
    WildestSpinner = { fg = "#ff9f43" },
  },
  renderer_opts = {
    border = "rounded",
  },
})

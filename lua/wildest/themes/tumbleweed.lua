local themes = require("wildest.themes")

--- Tumbleweed theme: minimal, light and airy
--- Rolling through with barely a trace.
return themes.define({
  renderer = "popupmenu",
  highlights = {
    WildestDefault = { bg = "#f5f0e8", fg = "#5a5040" },
    WildestSelected = { bg = "#e0d8c8", fg = "#2a2520", bold = true },
    WildestAccent = { bg = "#f5f0e8", fg = "#b07830", bold = true },
    WildestSelectedAccent = { bg = "#e0d8c8", fg = "#906020", bold = true, underline = true },
    WildestBorder = { bg = "#ebe5d8", fg = "#9a8a70" },
    WildestPrompt = { bg = "#f5f0e8", fg = "#5a5040" },
    WildestPromptCursor = { bg = "#b07830", fg = "#f5f0e8" },
    WildestSpinner = { fg = "#b07830" },
  },
  renderer_opts = {
    left = { " " },
    right = { " " },
  },
})

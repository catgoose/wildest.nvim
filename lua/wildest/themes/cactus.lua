local themes = require("wildest.themes")

--- Cactus theme: vibrant greens on dark soil
--- Prickly on the outside, refreshing on the inside.
return themes.define({
  renderer = "border",
  highlights = {
    WildestDefault = { bg = "#1a2416", fg = "#a8d08c" },
    WildestSelected = { bg = "#2e4420", fg = "#d0f0b0", bold = true },
    WildestAccent = { bg = "#1a2416", fg = "#50c878", bold = true },
    WildestSelectedAccent = { bg = "#2e4420", fg = "#70e898", bold = true, underline = true },
    WildestBorder = { bg = "#101a0c", fg = "#3a7a30" },
    WildestPrompt = { bg = "#1a2416", fg = "#a8d08c" },
    WildestPromptCursor = { bg = "#50c878", fg = "#101a0c" },
    WildestSpinner = { fg = "#50c878" },
  },
  renderer_opts = {
    border = "rounded",
    left = { " " },
    right = { " " },
  },
})

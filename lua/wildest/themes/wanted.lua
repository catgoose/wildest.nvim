local themes = require("wildest.themes")

--- Wanted theme: centered palette, parchment and ink
--- Like reading a wanted poster nailed to the post office wall.
return themes.define({
  renderer = "palette",
  highlights = {
    WildestDefault = { bg = "#2c2416", fg = "#d4c4a0" },
    WildestSelected = { bg = "#4e3b20", fg = "#fff0d0", bold = true },
    WildestAccent = { bg = "#2c2416", fg = "#e8a838", bold = true },
    WildestSelectedAccent = { bg = "#4e3b20", fg = "#ffc848", bold = true, underline = true },
    WildestBorder = { bg = "#1c1808", fg = "#a08040" },
    WildestPrompt = { bg = "#352c1a", fg = "#d4c4a0" },
    WildestPromptCursor = { bg = "#e8a838", fg = "#1c1808" },
    WildestSpinner = { fg = "#e8a838" },
  },
  renderer_opts = {
    border = "double",
    max_height = "60%",
    max_width = "60%",
    min_width = 40,
    margin = "auto",
    prompt_position = "top",
    left = { " " },
    right = { " " },
  },
})

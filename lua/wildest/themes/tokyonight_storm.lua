local themes = require("wildest.themes")

--- TokyoNight Storm theme: stormy dark blue
--- Slightly lighter base than night with the same neon accents.
--- Based on https://github.com/folke/tokyonight.nvim (storm variant)
return themes.define({
  renderer = "border",
  highlights = {
    -- bg bg, fg fg
    WildestDefault = { bg = "#1f2335", fg = "#c0caf5" },
    -- bg_highlight bg, fg fg
    WildestSelected = { bg = "#373e59", fg = "#c0caf5", bold = true },
    -- cyan accent on bg
    WildestAccent = { bg = "#1f2335", fg = "#2ac3de", bold = true },
    -- cyan accent on bg_highlight
    WildestSelectedAccent = { bg = "#373e59", fg = "#2ac3de", bold = true, underline = true },
    -- bg bg, muted cyan border
    WildestBorder = { bg = "#1f2335", fg = "#2da0bd" },
    -- bg bg, fg fg
    WildestPrompt = { bg = "#1f2335", fg = "#c0caf5" },
    -- cyan cursor
    WildestPromptCursor = { bg = "#2ac3de", fg = "#1f2335" },
    WildestSpinner = { fg = "#2ac3de" },
    WildestScrollbar = { bg = "#1f2335" },
    WildestScrollbarThumb = { bg = "#373e59" },
  },
  renderer_opts = {
    border = "rounded",
    left = { " " },
    right = { " " },
  },
})

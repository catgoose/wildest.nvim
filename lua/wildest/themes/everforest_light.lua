local themes = require("wildest.themes")

--- Everforest Light theme: forest green light
--- Soft cream base with fresh green accents.
--- Based on https://github.com/sainnhe/everforest (light variant)
return themes.define({
  renderer = "border",
  highlights = {
    -- bg3 bg, fg fg
    WildestDefault = { bg = "#efebd4", fg = "#5c6a72" },
    -- green bg, bg_dim fg (inverted selection)
    WildestSelected = { bg = "#93b259", fg = "#fdf6e3", bold = true },
    -- green accent on bg3
    WildestAccent = { bg = "#efebd4", fg = "#8da101", bold = true },
    -- green accent on green bg
    WildestSelectedAccent = { bg = "#93b259", fg = "#fdf6e3", bold = true, underline = true },
    -- bg3 bg, grey1 border
    WildestBorder = { bg = "#efebd4", fg = "#939f91" },
    -- bg3 bg, fg fg
    WildestPrompt = { bg = "#efebd4", fg = "#5c6a72" },
    -- green cursor
    WildestPromptCursor = { bg = "#8da101", fg = "#efebd4" },
    WildestSpinner = { fg = "#8da101" },
    WildestScrollbar = { bg = "#efebd4" },
    WildestScrollbarThumb = { bg = "#939f91" },
  },
  renderer_opts = {
    border = "rounded",
  },
})

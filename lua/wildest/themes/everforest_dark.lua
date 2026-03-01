local themes = require("wildest.themes")

--- Everforest Dark theme: forest green dark
--- Warm greens and earth tones on a deep woodland base.
--- Based on https://github.com/sainnhe/everforest
return themes.define({
  renderer = "border",
  highlights = {
    -- bg3 bg, fg fg
    WildestDefault = { bg = "#3d484d", fg = "#d3c6aa" },
    -- green bg, bg_dim fg (inverted selection)
    WildestSelected = { bg = "#a7c080", fg = "#2d353b", bold = true },
    -- green accent on bg3
    WildestAccent = { bg = "#3d484d", fg = "#a7c080", bold = true },
    -- green accent on green bg
    WildestSelectedAccent = { bg = "#a7c080", fg = "#2d353b", bold = true, underline = true },
    -- bg3 bg, grey1 border
    WildestBorder = { bg = "#3d484d", fg = "#859289" },
    -- bg3 bg, fg fg
    WildestPrompt = { bg = "#3d484d", fg = "#d3c6aa" },
    -- green cursor
    WildestPromptCursor = { bg = "#a7c080", fg = "#3d484d" },
    WildestSpinner = { fg = "#a7c080" },
    WildestScrollbar = { bg = "#3d484d" },
    WildestScrollbarThumb = { bg = "#859289" },
  },
  renderer_opts = {
    border = "rounded",
  },
})

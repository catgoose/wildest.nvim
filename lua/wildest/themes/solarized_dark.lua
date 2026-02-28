local themes = require("wildest.themes")

--- Solarized Dark theme: the classic
--- Precision-crafted palette with cyan accents on deep teal.
--- Based on https://ethanschoonover.com/solarized/
return themes.define({
  renderer = "border",
  highlights = {
    -- base02 bg, base0 fg
    WildestDefault = { bg = "#073642", fg = "#839496" },
    -- blue bg, base03 fg (inverted selection)
    WildestSelected = { bg = "#268bd2", fg = "#002b36", bold = true },
    -- cyan accent on base02
    WildestAccent = { bg = "#073642", fg = "#2aa198", bold = true },
    -- cyan accent on blue bg
    WildestSelectedAccent = { bg = "#268bd2", fg = "#002b36", bold = true, underline = true },
    -- base02 bg, base01 border
    WildestBorder = { bg = "#073642", fg = "#586e75" },
    -- base02 bg, base0 fg
    WildestPrompt = { bg = "#073642", fg = "#839496" },
    -- cyan cursor
    WildestPromptCursor = { bg = "#2aa198", fg = "#073642" },
    WildestSpinner = { fg = "#2aa198" },
    WildestScrollbar = { bg = "#073642" },
    WildestScrollbarThumb = { bg = "#586e75" },
  },
  renderer_opts = {
    border = "rounded",
  },
})

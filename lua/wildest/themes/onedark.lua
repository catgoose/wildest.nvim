local themes = require("wildest.themes")

--- OneDark theme: Atom-inspired dark
--- Cool grey base with vivid blue accents.
--- Based on https://github.com/navarasu/onedark.nvim
return themes.define({
  renderer = "border",
  highlights = {
    -- bg1 bg, fg fg
    WildestDefault = { bg = "#31353f", fg = "#abb2bf" },
    -- blue bg, bg0 fg (inverted selection)
    WildestSelected = { bg = "#73b8f1", fg = "#282c34", bold = true },
    -- blue accent on bg1
    WildestAccent = { bg = "#31353f", fg = "#61afef", bold = true },
    -- blue accent on blue bg
    WildestSelectedAccent = { bg = "#73b8f1", fg = "#282c34", bold = true, underline = true },
    -- bg1 bg, grey border
    WildestBorder = { bg = "#31353f", fg = "#5c6370" },
    -- bg1 bg, fg fg
    WildestPrompt = { bg = "#31353f", fg = "#abb2bf" },
    -- blue cursor
    WildestPromptCursor = { bg = "#61afef", fg = "#31353f" },
    WildestSpinner = { fg = "#61afef" },
    WildestScrollbar = { bg = "#31353f" },
    WildestScrollbarThumb = { bg = "#5c6370" },
  },
  renderer_opts = {
    border = "rounded",
  },
})

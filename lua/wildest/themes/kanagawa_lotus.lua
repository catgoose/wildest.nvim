local themes = require("wildest.themes")

--- Kanagawa Lotus theme: light variant
--- Soft parchment tones with ink accents, like a painted scroll.
--- Based on https://github.com/rebelot/kanagawa.nvim (lotus variant)
return themes.define({
  renderer = "border",
  highlights = {
    -- lotusWhite3 bg, lotusInk1 fg
    WildestDefault = { bg = "#f2ecbc", fg = "#545464" },
    -- lotusWhite1 bg, lotusInk2 fg
    WildestSelected = { bg = "#dcd5ac", fg = "#43436c", bold = true },
    -- lotusOrange2 accent on default bg
    WildestAccent = { bg = "#f2ecbc", fg = "#e98a00", bold = true },
    -- lotusOrange2 accent on selected bg
    WildestSelectedAccent = { bg = "#dcd5ac", fg = "#cc6d00", bold = true, underline = true },
    -- lotusWhite2 bg, lotusGray2 fg
    WildestBorder = { bg = "#e5ddb0", fg = "#716e61" },
    -- lotusWhite3 bg, lotusInk1 fg
    WildestPrompt = { bg = "#f2ecbc", fg = "#545464" },
    -- lotusBlue4 cursor
    WildestPromptCursor = { bg = "#4d699b", fg = "#f2ecbc" },
    WildestSpinner = { fg = "#4d699b" },
  },
  renderer_opts = {
    border = "rounded",
  },
})

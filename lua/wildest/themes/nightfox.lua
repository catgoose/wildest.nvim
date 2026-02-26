local themes = require("wildest.themes")

--- Nightfox theme: deep blue dark
--- Deep ocean blue with soft steel accents.
--- Based on https://github.com/EdenEast/nightfox.nvim
return themes.define({
  renderer = "border",
  highlights = {
    -- bg1 bg, fg1 fg
    WildestDefault = { bg = "#2b3b51", fg = "#cdcecf" },
    -- sel0 bg, fg1 fg
    WildestSelected = { bg = "#3c5372", fg = "#cdcecf", bold = true },
    -- blue accent on bg1
    WildestAccent = { bg = "#2b3b51", fg = "#84b0d8", bold = true },
    -- blue accent on sel0
    WildestSelectedAccent = { bg = "#3c5372", fg = "#84b0d8", bold = true, underline = true },
    -- bg0 bg, muted fg border
    WildestBorder = { bg = "#131a24", fg = "#71839b" },
    -- bg1 bg, fg1 fg
    WildestPrompt = { bg = "#2b3b51", fg = "#cdcecf" },
    -- blue cursor
    WildestPromptCursor = { bg = "#84b0d8", fg = "#131a24" },
    WildestSpinner = { fg = "#84b0d8" },
    WildestScrollbar = { bg = "#2b3b51" },
    WildestScrollbarThumb = { bg = "#3c5372" },
  },
  renderer_opts = {
    border = "rounded",
    left = { " " },
    right = { " " },
  },
})

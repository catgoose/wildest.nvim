local themes = require("wildest.themes")

--- TokyoNight Moon theme: soft moonlit blue
--- Muted base with brighter blue accents.
--- Based on https://github.com/folke/tokyonight.nvim (moon variant)
return themes.define({
  renderer = "border",
  highlights = {
    -- bg bg, fg fg
    WildestDefault = { bg = "#1e2030", fg = "#c8d3f5" },
    -- bg_highlight bg, fg fg
    WildestSelected = { bg = "#383d56", fg = "#c8d3f5", bold = true },
    -- blue accent on bg
    WildestAccent = { bg = "#1e2030", fg = "#65bcff", bold = true },
    -- blue accent on bg_highlight
    WildestSelectedAccent = { bg = "#383d56", fg = "#65bcff", bold = true, underline = true },
    -- bg bg, muted blue border
    WildestBorder = { bg = "#1e2030", fg = "#589ed6" },
    -- bg bg, fg fg
    WildestPrompt = { bg = "#1e2030", fg = "#c8d3f5" },
    -- blue cursor
    WildestPromptCursor = { bg = "#65bcff", fg = "#1e2030" },
    WildestSpinner = { fg = "#65bcff" },
    WildestScrollbar = { bg = "#1e2030" },
    WildestScrollbarThumb = { bg = "#383d56" },
  },
  renderer_opts = {
    border = "rounded",
  },
})

local themes = require("wildest.themes")

--- Nord theme: arctic dark
--- Cool polar palette with frost blue accents.
--- Based on https://github.com/shaunsingh/nord.nvim
return themes.define({
  renderer = "border",
  highlights = {
    -- nord2 bg, nord4 fg
    WildestDefault = { bg = "#434C5E", fg = "#D8DEE9" },
    -- nord10 bg, nord4 fg
    WildestSelected = { bg = "#5E81AC", fg = "#D8DEE9", bold = true },
    -- nord8 accent on nord2
    WildestAccent = { bg = "#434C5E", fg = "#88C0D0", bold = true },
    -- nord8 accent on nord10
    WildestSelectedAccent = { bg = "#5E81AC", fg = "#88C0D0", bold = true, underline = true },
    -- nord2 bg, nord4 border
    WildestBorder = { bg = "#434C5E", fg = "#D8DEE9" },
    -- nord2 bg, nord4 fg
    WildestPrompt = { bg = "#434C5E", fg = "#D8DEE9" },
    -- nord8 cursor
    WildestPromptCursor = { bg = "#88C0D0", fg = "#434C5E" },
    WildestSpinner = { fg = "#88C0D0" },
    WildestScrollbar = { bg = "#434C5E" },
    WildestScrollbarThumb = { bg = "#5E81AC" },
  },
  renderer_opts = {
    border = "rounded",
  },
})

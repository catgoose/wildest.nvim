local themes = require("wildest.themes")

--- Gruvbox Light theme: warm retro light
--- Sandy light base with deep blue accents.
--- Based on https://github.com/ellisonleao/gruvbox.nvim (light variant)
return themes.define({
  renderer = "border",
  highlights = {
    -- fg3 bg, fg0 fg
    WildestDefault = { bg = "#d5c4a1", fg = "#3c3836" },
    -- blue bg, fg3 fg (inverted selection)
    WildestSelected = { bg = "#076678", fg = "#d5c4a1", bold = true },
    -- blue accent on fg3 bg
    WildestAccent = { bg = "#d5c4a1", fg = "#076678", bold = true },
    -- blue accent on blue bg
    WildestSelectedAccent = { bg = "#076678", fg = "#d5c4a1", bold = true, underline = true },
    -- fg3 bg, fg4 border
    WildestBorder = { bg = "#d5c4a1", fg = "#bdae93" },
    -- fg3 bg, fg0 fg
    WildestPrompt = { bg = "#d5c4a1", fg = "#3c3836" },
    -- blue cursor
    WildestPromptCursor = { bg = "#076678", fg = "#d5c4a1" },
    WildestSpinner = { fg = "#076678" },
    WildestScrollbar = { bg = "#d5c4a1" },
    WildestScrollbarThumb = { bg = "#bdae93" },
  },
  renderer_opts = {
    border = "rounded",
    left = { " " },
    right = { " " },
  },
})

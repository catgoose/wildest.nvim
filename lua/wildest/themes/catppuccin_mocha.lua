local themes = require("wildest.themes")

--- Catppuccin Mocha theme: dark pastel
--- Rich dark tones with lavender accents from the Mocha palette.
--- Based on https://github.com/catppuccin/nvim
return themes.define({
  renderer = "border",
  highlights = {
    -- mantle bg, overlay2 fg
    WildestDefault = { bg = "#181825", fg = "#9399b2" },
    -- surface0 bg, text fg
    WildestSelected = { bg = "#313244", fg = "#cdd6f4", bold = true },
    -- text accent on mantle bg
    WildestAccent = { bg = "#181825", fg = "#cdd6f4", bold = true },
    -- text accent on surface0 bg
    WildestSelectedAccent = { bg = "#313244", fg = "#cdd6f4", bold = true, underline = true },
    -- mantle bg, seamless border
    WildestBorder = { bg = "#181825", fg = "#181825" },
    -- mantle bg, overlay2 fg
    WildestPrompt = { bg = "#181825", fg = "#9399b2" },
    -- text cursor
    WildestPromptCursor = { bg = "#cdd6f4", fg = "#181825" },
    WildestSpinner = { fg = "#cdd6f4" },
    WildestScrollbar = { bg = "#181825" },
    WildestScrollbarThumb = { bg = "#313244" },
  },
  renderer_opts = {
    border = "rounded",
    left = { " " },
    right = { " " },
  },
})

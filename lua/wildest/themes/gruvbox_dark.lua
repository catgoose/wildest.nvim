local themes = require("wildest.themes")

--- Gruvbox Dark theme: warm retro dark
--- Earthy tones with aqua accents on dark soil.
--- Based on https://github.com/ellisonleao/gruvbox.nvim
return themes.define({
  renderer = "border",
  highlights = {
    -- bg3 bg, fg1 fg
    WildestDefault = { bg = "#504945", fg = "#ebdbb2" },
    -- aqua bg, bg3 fg (inverted selection)
    WildestSelected = { bg = "#83a598", fg = "#504945", bold = true },
    -- aqua accent on bg3
    WildestAccent = { bg = "#504945", fg = "#83a598", bold = true },
    -- aqua accent on aqua bg (bright fg)
    WildestSelectedAccent = { bg = "#83a598", fg = "#504945", bold = true, underline = true },
    -- bg3 bg, bg4 border
    WildestBorder = { bg = "#504945", fg = "#665c54" },
    -- bg3 bg, fg1 fg
    WildestPrompt = { bg = "#504945", fg = "#ebdbb2" },
    -- aqua cursor
    WildestPromptCursor = { bg = "#83a598", fg = "#504945" },
    WildestSpinner = { fg = "#83a598" },
    WildestScrollbar = { bg = "#504945" },
    WildestScrollbarThumb = { bg = "#665c54" },
  },
  renderer_opts = {
    border = "rounded",
    left = { " " },
    right = { " " },
  },
})

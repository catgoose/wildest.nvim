local themes = require("wildest.themes")

--- Rose Pine Dawn theme: light variant
--- Warm parchment base with teal accents.
--- Based on https://github.com/rose-pine/neovim (dawn variant)
return themes.define({
  renderer = "border",
  highlights = {
    -- surface bg, subtle fg
    WildestDefault = { bg = "#fffaf3", fg = "#797593" },
    -- overlay bg, subtle fg
    WildestSelected = { bg = "#f2e9e1", fg = "#797593", bold = true },
    -- pine accent on surface
    WildestAccent = { bg = "#fffaf3", fg = "#56949f", bold = true },
    -- pine accent on overlay
    WildestSelectedAccent = { bg = "#f2e9e1", fg = "#56949f", bold = true, underline = true },
    -- surface bg, muted border
    WildestBorder = { bg = "#fffaf3", fg = "#9893a5" },
    -- surface bg, subtle fg
    WildestPrompt = { bg = "#fffaf3", fg = "#797593" },
    -- pine cursor
    WildestPromptCursor = { bg = "#56949f", fg = "#fffaf3" },
    WildestSpinner = { fg = "#56949f" },
    WildestScrollbar = { bg = "#fffaf3" },
    WildestScrollbarThumb = { bg = "#9893a5" },
  },
  renderer_opts = {
    border = "rounded",
  },
})

local themes = require("wildest.themes")

--- Catppuccin Frappe theme: medium-dark pastel
--- Dusky blue-grey tones with soft lavender accents.
--- Based on https://github.com/catppuccin/nvim (frappe variant)
return themes.define({
  renderer = "border",
  highlights = {
    -- mantle bg, overlay2 fg
    WildestDefault = { bg = "#292c3c", fg = "#949cbb" },
    -- surface0 bg, text fg
    WildestSelected = { bg = "#414559", fg = "#c6d0f5", bold = true },
    -- text accent on mantle bg
    WildestAccent = { bg = "#292c3c", fg = "#c6d0f5", bold = true },
    -- text accent on surface0 bg
    WildestSelectedAccent = { bg = "#414559", fg = "#c6d0f5", bold = true, underline = true },
    -- mantle bg, seamless border
    WildestBorder = { bg = "#292c3c", fg = "#292c3c" },
    -- mantle bg, overlay2 fg
    WildestPrompt = { bg = "#292c3c", fg = "#949cbb" },
    -- text cursor
    WildestPromptCursor = { bg = "#c6d0f5", fg = "#292c3c" },
    WildestSpinner = { fg = "#c6d0f5" },
    WildestScrollbar = { bg = "#292c3c" },
    WildestScrollbarThumb = { bg = "#414559" },
  },
  renderer_opts = {
    border = "rounded",
    left = { " " },
    right = { " " },
  },
})

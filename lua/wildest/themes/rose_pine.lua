local themes = require("wildest.themes")

--- Rose Pine theme: dark with muted tones
--- Soft dark palette with foam accents.
--- Based on https://github.com/rose-pine/neovim
return themes.define({
  renderer = "border",
  highlights = {
    -- surface bg, subtle fg
    WildestDefault = { bg = "#1f1d2e", fg = "#908caa" },
    -- overlay bg, subtle fg
    WildestSelected = { bg = "#26233a", fg = "#908caa", bold = true },
    -- foam accent on surface
    WildestAccent = { bg = "#1f1d2e", fg = "#9ccfd8", bold = true },
    -- foam accent on overlay
    WildestSelectedAccent = { bg = "#26233a", fg = "#9ccfd8", bold = true, underline = true },
    -- surface bg, muted border
    WildestBorder = { bg = "#1f1d2e", fg = "#6e6a86" },
    -- surface bg, subtle fg
    WildestPrompt = { bg = "#1f1d2e", fg = "#908caa" },
    -- foam cursor
    WildestPromptCursor = { bg = "#9ccfd8", fg = "#1f1d2e" },
    WildestSpinner = { fg = "#9ccfd8" },
    WildestScrollbar = { bg = "#1f1d2e" },
    WildestScrollbarThumb = { bg = "#6e6a86" },
  },
  renderer_opts = {
    border = "rounded",
    left = { " " },
    right = { " " },
  },
})

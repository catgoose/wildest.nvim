local themes = require("wildest.themes")

--- Rose Pine Moon theme: darker moon-tinted variant
--- Deeper purple base with the same soft foam accents.
--- Based on https://github.com/rose-pine/neovim (moon variant)
return themes.define({
  renderer = "border",
  highlights = {
    -- surface bg, subtle fg
    WildestDefault = { bg = "#2a273f", fg = "#908caa" },
    -- overlay bg, subtle fg
    WildestSelected = { bg = "#393552", fg = "#908caa", bold = true },
    -- foam accent on surface
    WildestAccent = { bg = "#2a273f", fg = "#9ccfd8", bold = true },
    -- foam accent on overlay
    WildestSelectedAccent = { bg = "#393552", fg = "#9ccfd8", bold = true, underline = true },
    -- surface bg, muted border
    WildestBorder = { bg = "#2a273f", fg = "#6e6a86" },
    -- surface bg, subtle fg
    WildestPrompt = { bg = "#2a273f", fg = "#908caa" },
    -- foam cursor
    WildestPromptCursor = { bg = "#9ccfd8", fg = "#2a273f" },
    WildestSpinner = { fg = "#9ccfd8" },
    WildestScrollbar = { bg = "#2a273f" },
    WildestScrollbarThumb = { bg = "#6e6a86" },
  },
  renderer_opts = {
    border = "rounded",
    left = { " " },
    right = { " " },
  },
})

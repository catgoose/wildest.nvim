local themes = require("wildest.themes")

--- Catppuccin Latte theme: light pastel
--- Warm light tones with deep ink accents.
--- Based on https://github.com/catppuccin/nvim (latte variant)
return themes.define({
  renderer = "border",
  highlights = {
    -- mantle bg, overlay1 fg
    WildestDefault = { bg = "#e6e9ef", fg = "#7c7f93" },
    -- surface0 bg, text fg
    WildestSelected = { bg = "#ccd0da", fg = "#4c4f69", bold = true },
    -- text accent on mantle bg
    WildestAccent = { bg = "#e6e9ef", fg = "#4c4f69", bold = true },
    -- text accent on surface0 bg
    WildestSelectedAccent = { bg = "#ccd0da", fg = "#4c4f69", bold = true, underline = true },
    -- mantle bg, seamless border
    WildestBorder = { bg = "#e6e9ef", fg = "#e6e9ef" },
    -- mantle bg, overlay1 fg
    WildestPrompt = { bg = "#e6e9ef", fg = "#7c7f93" },
    -- text cursor
    WildestPromptCursor = { bg = "#4c4f69", fg = "#e6e9ef" },
    WildestSpinner = { fg = "#4c4f69" },
    WildestScrollbar = { bg = "#e6e9ef" },
    WildestScrollbarThumb = { bg = "#ccd0da" },
  },
  renderer_opts = {
    border = "rounded",
    left = { " " },
    right = { " " },
  },
})

local themes = require("wildest.themes")

--- Kanagawa Wave theme: the default heart-warming kanagawa
--- Deep ink backgrounds with warm autumn accents.
--- Based on https://github.com/rebelot/kanagawa.nvim
return themes.define({
  renderer = "border",
  highlights = {
    -- sumiInk4 bg, fujiWhite fg
    WildestDefault = { bg = "#2A2A37", fg = "#DCD7BA" },
    -- waveBlue1 bg, fujiWhite fg
    WildestSelected = { bg = "#223249", fg = "#DCD7BA", bold = true },
    -- carpYellow accent on default bg
    WildestAccent = { bg = "#2A2A37", fg = "#E6C384", bold = true },
    -- carpYellow accent on selected bg
    WildestSelectedAccent = { bg = "#223249", fg = "#E6C384", bold = true, underline = true },
    -- sumiInk3 bg, sumiInk6 fg for border
    WildestBorder = { bg = "#1F1F28", fg = "#54546D" },
    -- sumiInk4 bg, oldWhite fg for prompt
    WildestPrompt = { bg = "#2A2A37", fg = "#C8C093" },
    -- crystalBlue cursor
    WildestPromptCursor = { bg = "#7E9CD8", fg = "#1F1F28" },
    WildestSpinner = { fg = "#7E9CD8" },
    -- scrollbar: sumiInk4 bg for bar, sumiInk6 fg for thumb
    WildestScrollbar = { bg = "#2A2A37" },
    WildestScrollbarThumb = { bg = "#54546D" },
  },
  renderer_opts = {
    border = "rounded",
  },
})

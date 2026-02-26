local themes = require("wildest.themes")

--- Dracula theme: classic dark
--- Dark purple-grey base with cyan accents.
--- Based on https://github.com/Mofiqul/dracula.nvim
return themes.define({
  renderer = "border",
  highlights = {
    -- bgdark bg, fg fg
    WildestDefault = { bg = "#21222C", fg = "#F8F8F2" },
    -- selection bg, fg fg
    WildestSelected = { bg = "#44475A", fg = "#F8F8F2", bold = true },
    -- cyan accent on bgdark
    WildestAccent = { bg = "#21222C", fg = "#8BE9FD", bold = true },
    -- cyan accent on selection
    WildestSelectedAccent = { bg = "#44475A", fg = "#8BE9FD", bold = true, underline = true },
    -- bgdark bg, comment border
    WildestBorder = { bg = "#21222C", fg = "#6272A4" },
    -- bgdark bg, fg fg
    WildestPrompt = { bg = "#21222C", fg = "#F8F8F2" },
    -- cyan cursor
    WildestPromptCursor = { bg = "#8BE9FD", fg = "#21222C" },
    WildestSpinner = { fg = "#8BE9FD" },
    WildestScrollbar = { bg = "#21222C" },
    WildestScrollbarThumb = { bg = "#44475A" },
  },
  renderer_opts = {
    border = "rounded",
    left = { " " },
    right = { " " },
  },
})

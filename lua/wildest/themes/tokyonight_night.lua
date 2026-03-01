local themes = require("wildest.themes")

--- TokyoNight Night theme: deep dark neon
--- Deep midnight blue with cyan accents.
--- Based on https://github.com/folke/tokyonight.nvim (night variant)
return themes.define({
  renderer = "border",
  highlights = {
    -- bg_dark bg, fg fg
    WildestDefault = { bg = "#16161e", fg = "#c0caf5" },
    -- bg_highlight bg, fg fg
    WildestSelected = { bg = "#33354a", fg = "#c0caf5", bold = true },
    -- cyan accent on bg_dark
    WildestAccent = { bg = "#16161e", fg = "#2ac3de", bold = true },
    -- cyan accent on bg_highlight
    WildestSelectedAccent = { bg = "#33354a", fg = "#2ac3de", bold = true, underline = true },
    -- bg_dark bg, muted cyan border
    WildestBorder = { bg = "#16161e", fg = "#29a4b9" },
    -- bg_dark bg, fg fg
    WildestPrompt = { bg = "#16161e", fg = "#c0caf5" },
    -- cyan cursor
    WildestPromptCursor = { bg = "#2ac3de", fg = "#16161e" },
    WildestSpinner = { fg = "#2ac3de" },
    WildestScrollbar = { bg = "#16161e" },
    WildestScrollbarThumb = { bg = "#33354a" },
  },
  renderer_opts = {
    border = "rounded",
  },
})

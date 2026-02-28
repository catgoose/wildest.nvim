local themes = require("wildest.themes")

--- Kanagawa Dragon theme: for late-night sessions
--- Darker, warmer variant with muted earth tones.
--- Based on https://github.com/rebelot/kanagawa.nvim (dragon variant)
return themes.define({
  renderer = "border",
  highlights = {
    -- dragonBlack4 bg, dragonWhite fg
    WildestDefault = { bg = "#282727", fg = "#c5c9c5" },
    -- dragonBlack5 bg, dragonWhite fg
    WildestSelected = { bg = "#393836", fg = "#c5c9c5", bold = true },
    -- dragonYellow accent
    WildestAccent = { bg = "#282727", fg = "#c4b28a", bold = true },
    -- dragonYellow on selected
    WildestSelectedAccent = { bg = "#393836", fg = "#c4b28a", bold = true, underline = true },
    -- dragonBlack3 bg, dragonBlack6 fg
    WildestBorder = { bg = "#181616", fg = "#625e5a" },
    -- dragonBlack4 bg, dragonGray fg
    WildestPrompt = { bg = "#282727", fg = "#a6a69c" },
    -- dragonOrange cursor
    WildestPromptCursor = { bg = "#b6927b", fg = "#181616" },
    WildestSpinner = { fg = "#b6927b" },
  },
  renderer_opts = {
    border = "rounded",
  },
})

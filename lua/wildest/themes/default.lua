local themes = require("wildest.themes")

--- Default theme: uses standard Neovim Pmenu highlight groups
--- Clean and simple, inherits your colorscheme's popup menu colors.
return themes.define({
  renderer = "popupmenu",
  highlights = {
    WildestDefault = { link = "Pmenu" },
    WildestSelected = { link = "PmenuSel" },
    WildestAccent = { link = "PmenuMatch" },
    WildestSelectedAccent = { link = "PmenuMatchSel" },
  },
  renderer_opts = {},
})

-- Author: Magnus Naessan Gaarder
return {
  "folke/flash.nvim",
  event = "VeryLazy",
  opts = {},
  -- NOTE: this takes over `s`/`S` in normal/visual/operator-pending mode
  -- (vanilla `s` = substitute-char, rarely needed once you have ciw/cw).
  -- `r`/`R` are only remapped inside operator-pending mode, so plain `r`
  -- (replace char) and `R` (Replace mode) in normal mode are untouched.
  keys = {
    { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash jump" },
    { "S", mode = { "n", "x", "o" }, function() require("flash").treesitter() end, desc = "Flash treesitter jump" },
    { "r", mode = "o", function() require("flash").remote() end, desc = "Remote flash" },
    { "R", mode = { "o", "x" }, function() require("flash").treesitter_search() end, desc = "Treesitter search" },
  },
}

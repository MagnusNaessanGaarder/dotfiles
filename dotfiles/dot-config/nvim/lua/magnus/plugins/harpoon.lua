-- Author: Magnus Naessan Gaarder
return {
  "ThePrimeagen/harpoon",
  branch = "harpoon2",
  dependencies = { "nvim-lua/plenary.nvim" },
  -- Pin a small set of files and jump straight to any of them, no fuzzy
  -- search needed. Complements Telescope (open-anything) and bufferline
  -- (cycle-through-everything-open) with "instant jump to the 4 files I'm
  -- actually working on right now".
  keys = {
    { "<leader>a", function() require("harpoon"):list():add() end, desc = "Harpoon: add file" },
    {
      "<C-e>",
      function()
        local harpoon = require("harpoon")
        harpoon.ui:toggle_quick_menu(harpoon:list())
      end,
      desc = "Harpoon: toggle quick menu",
    },
    { "<leader>1", function() require("harpoon"):list():select(1) end, desc = "Harpoon: jump to file 1" },
    { "<leader>2", function() require("harpoon"):list():select(2) end, desc = "Harpoon: jump to file 2" },
    { "<leader>3", function() require("harpoon"):list():select(3) end, desc = "Harpoon: jump to file 3" },
    { "<leader>4", function() require("harpoon"):list():select(4) end, desc = "Harpoon: jump to file 4" },
  },
  config = function()
    require("harpoon"):setup()
  end,
}

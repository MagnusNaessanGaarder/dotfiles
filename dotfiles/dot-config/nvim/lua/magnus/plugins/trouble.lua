-- Author: Magnus Naessan Gaarder
return {
  "folke/trouble.nvim",
  cmd = "Trouble",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  opts = {},
  -- <leader>x is already the Debug (dap) group, so Trouble lives under <leader>q.
  keys = {
    { "<leader>qd", "<cmd>Trouble diagnostics toggle<cr>", desc = "Diagnostics (workspace)" },
    { "<leader>qD", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", desc = "Diagnostics (buffer)" },
    { "<leader>qq", "<cmd>Trouble qflist toggle<cr>", desc = "Quickfix list" },
    { "<leader>ql", "<cmd>Trouble loclist toggle<cr>", desc = "Location list" },
  },
}

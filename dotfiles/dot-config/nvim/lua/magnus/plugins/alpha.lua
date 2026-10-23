-- Maintained by Magnus Naessan Gaarder, based on work by Filip R. Spanne
return {
  "goolord/alpha-nvim",
  event = "VimEnter",
  cond = function()
    return vim.fn.argc() == 0
  end,
  config = function()
    local alpha = require("alpha")
    local dashboard = require("alpha.themes.dashboard")

    dashboard.section.header.val = {
      "                                                     ",
      "  ███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗ ",
      "  ████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║ ",
      "  ██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║ ",
      "  ██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║ ",
      "  ██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║ ",
      "  ╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝ ",
      "                   Magnus Edition                    ",
    }

    dashboard.section.buttons.val = {
      dashboard.button("e", "  New File", "<cmd>ene<CR>"),
      dashboard.button("f", "  Find File", "<cmd>Telescope find_files<CR>"),
      dashboard.button("r", "  Recent Files", "<cmd>Telescope oldfiles<CR>"),
      dashboard.button("s", "  Find Word", "<cmd>Telescope live_grep<CR>"),
      dashboard.button("t", "  File Explorer", "<cmd>lua require('oil').toggle_float(vim.fn.getcwd())<CR>"),
      dashboard.button("g", "  LazyGit", "<cmd>LazyGit<CR>"),
      dashboard.button("q", "  Quit", "<cmd>qa<CR>"),
    }

    alpha.setup(dashboard.opts)

    vim.api.nvim_create_autocmd("FileType", {
      pattern = "alpha",
      callback = function()
        vim.opt_local.foldenable = false
        vim.opt_local.cursorline = false
      end,
    })
  end,
}

-- Maintained by Magnus Naessan Gaarder, based on work by Filip R. Spanne
return {
  "echasnovski/mini.indentscope",
  event = "BufReadPost",
  opts = {
    symbol = "|",
    options = { try_as_border = true },
  },
  init = function()
    vim.api.nvim_create_autocmd("FileType", {
      pattern = { "help", "lazy", "mason", "oil" },
      callback = function()
        vim.b.miniindentscope_disable = true
      end,
    })
  end,
}

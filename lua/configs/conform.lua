local options = {
  formatters_by_ft = {
    lua = { "stylua" },
    css = { "prettier" },
    html = { "prettier" },
    c = { "clang_format" },
    cpp = { "clang_format" },
  },

}

return options

return {
  {
    "stevearc/conform.nvim",
    event = 'BufWritePre', -- uncomment for format on save
    opts = require "configs.conform",
  },
  -- These are some examples, uncomment them if you want to see them work!
  {
    "neovim/nvim-lspconfig",
    config = function()
      require "configs.lspconfig"
    end,
  },
  {
    "ellisonleao/glow.nvim",
    ft = "markdown",
    config = function()
      require("glow").setup({
        border = "shadow",
        pager = false,
        width = 80,
        height = 100,
        width_ratio = 0.7,
        height_ratio = 0.7,
        })
          end,
        },
    {
    'chomosuke/typst-preview.nvim',
    lazy = false, -- or ft = 'typst'
    version = '1.*',
    opts = {}, -- lazy.nvim will implicitly calls `setup {}`
  },
  {
      "3rd/image.nvim",
      ft = { "markdown", "vimwiki" },
      build = false, -- so that it doesn't build the rock https://github.com/3rd/image.nvim/issues/91#issuecomment-2453430239
      opts = {
          backend = "kitty",
          processor = "magick_cli",
          integrations = {
            markdown = {
              enabled = true,
              download_remote_images = true,
              filetypes = { "markdown", "vimwiki" }, -- markdown extensions (ie. quarto) can go here
            },
            typst = { enabled = false },
            asciidoc = { enabled = false },
            neorg = { enabled = false },
            syslang = { enabled = false },
          },
      },
  },
  -- test new blink
  { import = "nvchad.blink.lazyspec" },
  -- Override blink-cmp keymaps
  {
    "saghen/blink.cmp",
    opts = {
      keymap = {
        preset = "default",
        ["<CR>"] = { "accept", "fallback" }, -- Accept if selected, else newline
        ["<Tab>"] = { "select_next", "fallback" },
        ["<S-Tab>"] = { "select_prev", "fallback" },
        ["<C-e>"] = { "cancel" },
      },
      completion = {
        list = {
          selection = { preselect = false, auto_insert = false },
        },
      },
    }
  },
  
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "vim", "lua", "vimdoc",
        "html", "css", "markdown", "markdown_inline",
      },
    },
  },
}

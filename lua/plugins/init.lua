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
  -- test new blink
  { import = "nvchad.blink.lazyspec" },
  -- Override blink-cmp keymaps
  {
    "saghen/blink.cmp",
    opts = {
      keymap = {
        preset = "default",
        ["<CR>"] = {}, -- Disable Enter for completion
        ["<C-y>"] = { "accept" }, -- Accept with Ctrl+Y
        ["<Tab>"] = { "select_next", "fallback" },
        ["<S-Tab>"] = { "select_prev", "fallback" },
        ["<C-e>"] = { "cancel" },
      },
    }
  },
  
  (function()
    local devdocs_order = { "c", "python~3.14", "rust", "html", "css", "lua~5.1" }

    return {
    "maskudo/devdocs.nvim",
    lazy = false,
    keys = {
      {
        "gK",
        mode = "n",
        function()
          local devdocs = require("devdocs")
          local installedDocs = devdocs.GetInstalledDocs()
          local pickers = require("telescope.pickers")
          local finders = require("telescope.finders")
          local conf = require("telescope.config").values
          local actions = require("telescope.actions")
          local action_state = require("telescope.actions.state")
          local entry_display = require("telescope.pickers.entry_display")

          vim.api.nvim_set_hl(0, "DevDocsNumber", { fg = "#e5c07b", bold = true })

          local displayer = entry_display.create({
            separator = " ",
            items = { { width = 3 }, { remaining = true } },
          })

          table.sort(installedDocs, function(a, b)
            local ai = vim.fn.index(devdocs_order, a)
            local bi = vim.fn.index(devdocs_order, b)
            if ai == -1 then ai = 999 end
            if bi == -1 then bi = 999 end
            return ai < bi
          end)

          local function open_selected(prompt_bufnr)
            actions.close(prompt_bufnr)
            local selected = action_state.get_selected_entry()
            if not selected then return end
            local docDir = devdocs.GetDocDir(selected.value)
            vim.schedule(function()
              require("telescope.builtin").find_files({ cwd = docDir })
            end)
          end

          pickers.new({}, {
            prompt_title = "DevDocs",
            initial_mode = "normal",
            finder = finders.new_table({
              results = installedDocs,
              entry_maker = function(entry)
                local idx = vim.fn.index(installedDocs, entry) + 1
                return {
                  value = entry,
                  ordinal = entry,
                  display = function()
                    return displayer({
                      { idx .. ".", "DevDocsNumber" },
                      entry,
                    })
                  end,
                }
              end,
            }),
            sorter = conf.generic_sorter({}),
            attach_mappings = function(prompt_bufnr, map)
              actions.select_default:replace(function()
                open_selected(prompt_bufnr)
              end)
              for i = 1, 9 do
                map("n", tostring(i), function()
                  local picker = action_state.get_current_picker(prompt_bufnr)
                  picker:set_selection(i - 1)
                  open_selected(prompt_bufnr)
                end)
              end
              return true
            end,
          }):find()
        end,
        desc = "DevDocs search",
      },
      { "<leader>di", "<cmd>DevDocs install<cr>", mode = "n", desc = "DevDocs install" },
      { "<leader>dd", "<cmd>DevDocs delete<cr>", mode = "n", desc = "DevDocs delete" },
    },
    opts = {
      ensure_installed = devdocs_order,
    },
  }
  end)(),

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

require "nvchad.autocmds"
local autocmd = vim.api.nvim_create_autocmd

-- Typst writing optimizations
autocmd("FileType", {
  pattern = "typst",
  callback = function()
    -- Essential for writing
    vim.opt_local.wrap = true
    vim.opt_local.linebreak = true
    vim.opt_local.breakindent = true
    vim.opt_local.spell = true
    vim.opt_local.spelllang = "en_us"
    
    -- Writing-friendly editing
    vim.opt_local.textwidth = 0        -- No hard line breaks
    vim.opt_local.wrapmargin = 0       -- No automatic wrapping
    vim.opt_local.formatoptions:remove("t") -- Don't auto-wrap text
    
    -- Better for prose
    vim.opt_local.conceallevel = 2     -- Hide markup syntax when not on line
    vim.opt_local.concealcursor = "nc" -- Hide in normal/command mode
    
    -- Indentation for structured content
    vim.opt_local.expandtab = true
    vim.opt_local.tabstop = 2
    vim.opt_local.shiftwidth = 2
    vim.opt_local.softtabstop = 2
  end,
})

-- Markdown for comparison/other writing
autocmd("FileType", {
  pattern = { "markdown", "text", "tex" },
  callback = function()
    vim.opt_local.wrap = true
    vim.opt_local.linebreak = true
    vim.opt_local.breakindent = true
    vim.opt_local.spell = true
    vim.opt_local.textwidth = vim.fn.winwidth(0) - 5
    vim.opt_local.formatoptions:append("t") -- auto wrap text
    vim.opt_local.conceallevel = 2
  end,
})

-- Auto-save for writing files (super helpful for essays!)
autocmd({ "TextChanged", "TextChangedI" }, {
  pattern = { "*.typ", "*.md", "*.tex", "*.txt" },
  callback = function()
    if vim.bo.modified and not vim.bo.readonly and vim.fn.expand("%") ~= "" then
      vim.cmd("silent! write")
    end
  end,
})

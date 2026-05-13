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

    -- Auto-continue list markers on Enter/o/O
    vim.opt_local.formatoptions:append("r") -- after Enter in insert mode
    vim.opt_local.formatoptions:append("o") -- after o/O in normal mode
    vim.opt_local.comments = "://,b:+,b:-"   -- recognize //, +, and - as leaders
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
    vim.opt_local.textwidth = 0
    vim.opt_local.formatoptions:append("t") -- auto wrap text
    vim.opt_local.conceallevel = 2
  end,
})

-- Auto-save for writing files (helpful for essays)
autocmd({ "InsertLeave" }, {
  pattern = { "*.typ", "*.md", "*.tex", "*.txt" },
  callback = function()
    if vim.bo.modified and not vim.bo.readonly and vim.fn.expand("%") ~= "" then
      vim.cmd("silent! write")
    end
  end,
})


-- autocmd("BufWritePost", {
--   pattern = "*.typ",
--   callback = function()
--     vim.cmd("silent! make")
--     vim.cmd("cwindow")
--   end,
-- })

local undo_augroup = vim.api.nvim_create_augroup("SaneUndo", { clear = true })

vim.api.nvim_create_autocmd("InsertEnter", {
  group = undo_augroup,
  pattern = "*",
  callback = function()
    -- Keys that will break the undo sequence
    local keymaps = { ".", ",", "!", "?", ";", ":" }
    
    for _, key in ipairs(keymaps) do
      vim.keymap.set("i", key, key .. "<C-g>u", {
        silent = true,
        buffer = true,
        desc = "Break undo sequence"
      })
    end
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = "python",
  callback = function()
    vim.opt_local.makeprg = "python3 %"
    vim.opt_local.errorformat = "%f:%l:%m"
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = { "c", "cpp" },
  callback = function()
    local ft = vim.bo.filetype
    local has_makefile = vim.fn.filereadable("Makefile") == 1 or vim.fn.filereadable("makefile") == 1

    if has_makefile then
      vim.opt_local.makeprg = "make"
    else
      if ft == "c" then
        -- C files
        vim.opt_local.makeprg = "gcc -Wall -Wextra -g -std=c17 % -o %<"
      else
        -- C++ files default to g++
        vim.opt_local.makeprg = "g++ -Wall -Wextra -g -std=c++20 % -o %<"
      end
    end

    -- good enough errorformat for both gcc/g++ and clang/clang++
    vim.opt_local.errorformat =
      "%f:%l:%c: %t%*[^:]: %m," ..  -- gcc 
      "%f:%l: %m," ..               -- simpler 
      "%f:%l:%c: %m"                -- clang 

    -- keymaps 
    vim.keymap.set("n", "<leader>mk", "<cmd>make<CR><cmd>cwindow<CR>",
      { buffer = true, desc = "Make / compile" })

    vim.keymap.set("n", "<leader>mr", function()
      local exe = vim.fn.expand("%<")
      vim.cmd("botright split | terminal ./" .. exe)
      vim.bo.bufhidden = "wipe"
    end, { buffer = true, desc = "Run compiled binary" })

    vim.keymap.set("n", "<leader>gc", function()
      if has_makefile then
        vim.notify("makeprg is 'make' (Makefile present), toggle has no effect", vim.log.levels.WARN)
        return
      end
      local mp = vim.opt_local.makeprg:get()
      -- check longer names first so "clang++" isn't partially matched by "g++"
      local swaps = {
        { "clang++", "g++" },
        { "g++",     "clang++" },
        { "clang",   "gcc" },
        { "gcc",     "clang" },
      }
      for _, pair in ipairs(swaps) do
        local old, new = pair[1], pair[2]
        if mp:find(old, 1, true) then
          mp = mp:gsub(old:gsub("%+", "%%+"), new, 1)
          vim.opt_local.makeprg = mp
          vim.notify("Compiler: " .. new, vim.log.levels.INFO)
          return
        end
      end
    end, { buffer = true, desc = "Toggle gcc/clang compiler" })
  end,
})

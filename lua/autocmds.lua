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

-- DevDocs buffer enhancements
local devdocs_dir = vim.fn.stdpath('data') .. '/devdocs/docs'

local function decode_entities(s)
  return s:gsub('&lt;', '<'):gsub('&gt;', '>'):gsub('&amp;', '&'):gsub('&quot;', '"'):gsub('&#39;', "'")
end

local function clean_devdocs_links(bufnr)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local content = table.concat(lines, "\n")

  -- Collapse multi-line <a> opening tags (attributes often span multiple lines)
  for _ = 1, 5 do
    content = content:gsub('(<a[^>]*)\n([^>]*>)', '%1 %2')
  end

  -- <a href="URL"><code>TEXT</code></a>  →  [`TEXT`](URL)
  content = content:gsub('<a href="([^"]*)"[^>]*><code>([^<]*)</code></a>', '[`%2`](%1)')
  -- <a href="URL">TEXT</a>  →  [TEXT](URL)
  content = content:gsub('<a href="([^"]*)"[^>]*>([^<]*)</a>', '[%2](%1)')

  -- cppreference: function declaration tables
  content = content:gsub('<table class="t%-dcl%-begin">[%s%S]-</table>', function(tbl)
    local parts = {}
    local header = tbl:match('Defined in header%s*<code>([^<]*)</code>')
    if header then
      table.insert(parts, '_Defined in header `' .. decode_entities(header) .. '`_')
    end
    for lang, code in tbl:gmatch('<pre[^>]*data%-language="([^"]*)"[^>]*>%s*<code>([%s%S]-)</code>%s*</pre>') do
      table.insert(parts, '```' .. lang .. '\n' .. decode_entities(code) .. '\n```')
    end
    return table.concat(parts, '\n\n')
  end)

  -- cppreference: "See also" tables
  content = content:gsub('<table class="t%-dsc%-begin">[%s%S]-</table>', function(tbl)
    local rows = {}
    for row in tbl:gmatch('<tr class="t%-dsc">([%s%S]-)</tr>') do
      local tds = {}
      for td in row:gmatch('<td[^>]*>([%s%S]-)</td>') do
        td = td:gsub('<br ?/?>', ' ')
        td = td:gsub('<code>([^<]*)</code>', '`%1`')
        td = td:gsub('<[^>]+>', '')
        td = decode_entities(td):gsub('%s+', ' '):gsub('^%s*(.-)%s*$', '%1')
        if td ~= '' then table.insert(tds, td) end
      end
      if #tds >= 2 then
        table.insert(rows, '- ' .. tds[1] .. ' — ' .. tds[2])
      elseif #tds == 1 then
        table.insert(rows, '- ' .. tds[1])
      end
    end
    if #rows == 0 then return '' end
    return '\n**See also**\n\n' .. table.concat(rows, '\n')
  end)

  -- Decode remaining entities and strip leftover HTML tags
  content = decode_entities(content):gsub('<[^>]+>', '')

  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, vim.split(content, "\n", { plain = true }))
  vim.bo[bufnr].modified = false
end

local function follow_devdocs_link()
  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2] + 1

  local link_url
  local pos = 1
  while pos <= #line do
    local s, e, _, url = line:find('%[(.-)%]%((.-)%)', pos)
    if not s then break end
    if col >= s and col <= e then
      link_url = url
      break
    end
    pos = e + 1
  end

  if not link_url then
    vim.notify("No link under cursor", vim.log.levels.INFO)
    return
  end

  if link_url:match('^https?://') then
    vim.fn.jobstart({ 'xdg-open', link_url }, { detach = true })
    return
  end

  -- Internal devdocs link e.g. ../library/stdtypes#list.sort
  local current_dir = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ':h')
  local file_part = link_url:match('^(.-)#') or link_url
  local target = vim.fn.simplify(current_dir .. '/' .. file_part .. '.md')

  if vim.fn.filereadable(target) == 1 then
    vim.cmd('edit ' .. vim.fn.fnameescape(target))
  else
    vim.notify('DevDocs: not found: ' .. target, vim.log.levels.WARN)
  end
end

autocmd('BufReadPost', {
  pattern = devdocs_dir .. '/**/*.md',
  callback = function(ev)
    clean_devdocs_links(ev.buf)
    vim.keymap.set('n', 'gf', follow_devdocs_link, { buffer = ev.buf, desc = 'Follow DevDocs link' })
  end,
})

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

require "nvchad.mappings"

-- add yours here

local map = vim.keymap.set

map("n", ";", ":", { desc = "CMD enter command mode" })
map("i", "jk", "<ESC>")

-- map({ "n", "i", "v" }, "<C-s>", "<cmd> w <cr>")

map("n", "<leader>tp", ":TypstPreview<CR>", { desc = "Typst Preview" })

-- This function safely stops LSP clients on any Neovim version
local function stop_lsp()
  local msg = "No active LSP clients for this buffer."
  local level = vim.log.levels.INFO

  -- Modern Neovim API (>= 0.8)
  if vim.lsp.stop then
    local clients = vim.lsp.get_clients { bufnr = 0 }
    if #clients > 0 then
      for _, client in ipairs(clients) do
        vim.lsp.stop(client.id)
      end
      msg = "LSP stopped for current buffer."
      level = vim.log.levels.WARN
    end
  -- Legacy Neovim API (< 0.8)
  elseif vim.lsp.stop_client then
    local clients = vim.lsp.get_active_clients { bufnr = 0 }
    if #clients > 0 then
      vim.lsp.stop_client(clients)
      msg = "LSP stopped for current buffer (legacy)."
      level = vim.log.levels.WARN
    end
  else
    msg = "Could not find a function to stop LSP clients."
    level = vim.log.levels.ERROR
  end

  vim.notify(msg, level)
end

-- Add this mapping to stop LSP in the current buffer
map("n", "<leader>ls", stop_lsp, { desc = "LSP Stop" })

map("n", "<leader>td", function()
  local current = vim.diagnostic.config().virtual_text
  vim.diagnostic.config { virtual_text = not current }
  vim.notify("Diagnostic virtual text: " .. (current and "OFF" or "ON"), vim.log.levels.INFO)
end, { desc = "Toggle diagnostic virtual text" })
map("n", "<leader>sr", function()
  require("telescope.builtin").lsp_references()
end, { desc = "LSP References (Telescope)" })

map("n", "<leader>fm", function()
  require("conform").format({ timeout_ms = 500, lsp_fallback = true })
end, { desc = "Format buffer" })


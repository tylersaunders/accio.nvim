local query = require('nvim-treesitter.query')
local configs = require "nvim-treesitter.configs"

local M = {}

-- Setup keymaps from the config.
function M.attach(bufnr, _)
  local config = configs.get_module("accio")

  for command, mapping in pairs(config.keymaps) do
    local cmd = string.format(":%s<CR>", command)
    vim.api.nvim_buf_set_keymap(
      bufnr, "n", mapping, cmd, {silent = true, noremap = true}
    )
  end
end

-- Clear keymaps from the config.
function M.detach(bufnr)
  local config = configs.get_module("accio")

  for _, mapping in pairs(config.keymaps) do
    vim.api.nvim_buf_del_keymap(bufnr, "n", mapping)
  end
end

-- Find the node that matches the query string at the current cursor position.
-- query_string: treesitter capture group, beginning with @
-- buffer? ( optional ): defaults to the current buffer if no buffer provided.
-- returns the node under cursor if it is found.
function M.find_at_cursor(query_string, buffer)
  local bufnr = buffer or vim.api.nvim_get_current_buf()
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  row = row - 1 -- row is 0 based, api returns 1 based.

  local function filter_function(match)
    local range = { match.node:range() }

    -- range[1] row of start
    -- range[2] col of start
    -- range[3] row of end
    -- range[4] col of end

    -- Find the closest array where the start is either at the cursor or
    -- the cursor is already inside the array.
    return range[1] == row and range[2] <= col

  end

  local function scoring_function(match)
    _, matchcol, _ = match.node:start()

    -- score by the closest array to the current column.
    return matchcol - col

  end

  local match = query.find_best_match(bufnr, query_string, "accio", filter_function, scoring_function)
  return match and match.node

end

return M

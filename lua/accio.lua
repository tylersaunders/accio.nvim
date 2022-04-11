local queries = require('nvim-treesitter.query')
local default_config = require('accio.defaults')
local internal = require('accio.internal')
local ts_utils = require('nvim-treesitter.ts_utils')

local M = {}

M.config = default_config

function M.setup(config)
  M.config = setmetatable(config, {__index = default_config})
end

function M.init()
  require('nvim-treesitter').define_modules({
    accio = {
      -- Can be overriden by User.
      enable = true,
      module_path = 'accio.internal',
      is_supported = function(lang)
        return queries.get_query(lang, 'accio') ~= nil
      end,
      keymaps = {
        AccioPivotArray = "<leader>ap",
      }
    }
  })
end

function M.pivot_array()

  local buffer = vim.api.nvim_get_current_buf()
    local array_at_cursor = internal.find_at_cursor("@array-list", buffer)

    if not array_at_cursor then
      return
    end

    local arrayLine, arrayStartCol, _, arrayEndCol = array_at_cursor:range()

    local currentIndent = vim.fn.indent(arrayLine+1)
    local emptySpace = " "

    local arrayValues = {}

    -- Loop through all the child nodes of the array
    for child_node in array_at_cursor:iter_children() do
      -- Look at name nodes to find the arrayValues
      if child_node:named() then
        table.insert(arrayValues,
          -- Add the current currentIndent and the current shiftwidth before the value.
          -- (So that the spacing appears correct when we write the line later.)
          emptySpace:rep(currentIndent + vim.fn.shiftwidth())
          ..
          ts_utils.get_node_text(child_node, buffer)[1]
          ..
          -- TODO: Rather than hardcode the seperator, make this per language config.
          ",")
      end
    end

    local currentLine = vim.api.nvim_get_current_line()

    -- Keep everything up to the start of the Array node including the opening bracket.
    local newLine = currentLine:sub(0, arrayStartCol + 1)

    -- Grab everything at the end point of the array (inclusive) so that it
    -- pivots with the rest of the values.
    local lastLine = emptySpace:rep(currentIndent) .. currentLine:sub(arrayEndCol)
    table.insert(arrayValues, lastLine)

    -- Rewrite current line
    vim.api.nvim_set_current_line(newLine)
    -- Pivot values + remaining code on the original line.
    vim.fn.append(arrayLine + 1, arrayValues)
end

return M

local butterfish = {}
local basePath = vim.fn.expand("$HOME") .. "/butterfish.nvim/sh/"

-- [ ] Prompt with the file as context
-- [ ] Fix the error on the current line
-- [ ] Fill in a function
-- [ ] Rewrite selected text
-- [ ] Add a comment explaining the selected line / block

local run_command = function(command)
  local job_id = vim.fn.jobstart(command, {
    on_stdout = function(job_id, data)
      vim.schedule(function()
        -- vim.api.nvim_buf_set_lines(0, -1, -1, false, data)
        -- insert text at cursor position, don't adjust indent, move cursor to end
        vim.cmd("undojoin")
        vim.api.nvim_put(data, 'c', { append = true }, true)
      end)
    end,

    on_stderr = function(job_id, data)
      vim.schedule(function()
        print("Job " .. job_id .. " errored with: ")
        for key, value in pairs(data) do
          print(key, value)
        end
      end)
    end,
  })
  
  -- print("Job ID: " .. job_id)
end

local escape_code = function(text)
  return text:gsub("'", "'\\''")
end

-- Enter an LLM prompt and write the response at the cursor
-- Script: prompt.sh
-- Args: filetype (language), prompt
butterfish.prompt = function(userPrompt)
  local filetype = vim.bo.filetype
  local command = basePath .. "prompt.sh " .. filetype .. " '" .. escape_code(userPrompt) .. "'"
  run_command(command)
end

-- Enter an LLM prompt and write the response at the cursor, including the open
-- file as context
-- Script: fileprompt.sh
-- Args: file path, prompt
butterfish.file_prompt = function(userPrompt)
  local filetype = vim.bo.filetype
  local filepath = vim.fn.expand("%:p")
  local command = basePath .. "fileprompt.sh " .. filepath .. " '" .. escape_code(userPrompt) .. "'"
  run_command(command)
end

-- Rewrite the selected text given instructions from the prompt
-- Args:
--   start_range    start of visual line range
--   end_range      end of visual line range
--   userPrompt     prompt to send to LLM
-- Script: rewrite.sh filetype selected_text prompt
butterfish.rewrite = function(start_range, end_range, userPrompt)
  local filetype = vim.bo.filetype
  local lines = vim.api.nvim_buf_get_lines(0, start_range - 1, end_range, false)
  local selectedText = table.concat(lines, "\n")
  local command = basePath .. "rewrite.sh " .. filetype .. " '" .. escape_code(selectedText) .. "' '" .. escape_code(userPrompt) .. "'"

  if vim.fn.exists(":Commentary") then
    -- If the commentary plugin is installed, use it to comment out the selection
    vim.cmd("'<,'>Commentary")
    -- Move the cursor to the end of the range
    vim.api.nvim_win_set_cursor(0, {end_range, 0})
  else
    -- We don't know where the cursor is, so move it to the end of the selection
    vim.api.nvim_feedkeys(
      vim.api.nvim_replace_termcodes("'>", true, true, true), "n", true)
  end

  -- Insert a new line below current line
  vim.cmd("undojoin")
  vim.api.nvim_feedkeys(
    vim.api.nvim_replace_termcodes("A<CR><ESC>", true, true, true), "n", true)

  -- Clear out the current line, this is necessary because we may have just
  -- commented out the line above, which may extend down to the newline we added
  vim.cmd("undojoin")
  vim.api.nvim_feedkeys(
    vim.api.nvim_replace_termcodes("_d$", true, true, true), "n", true)
  run_command(command)
end

-- Add a comment above the current line or block explaining it
-- Args:
--  start_range    start of visual line range
--  end_range      end of visual line range
-- Script: comment.sh filepath selected_text
butterfish.comment = function(start_range, end_range)
  local filepath = vim.fn.expand("%:p")
  local lines = vim.api.nvim_buf_get_lines(0, start_range - 1, end_range, false)
  local selectedText = table.concat(lines, "\n")
  local command = basePath .. "comment.sh " .. filepath .. " '" .. escape_code(selectedText) .. "'"

  -- Move to the beginning of the range
  vim.api.nvim_win_set_cursor(0, {start_range, 0})
  -- Add a new line above the current line
  vim.api.nvim_feedkeys(
    vim.api.nvim_replace_termcodes("O<ESC>", true, true, true), "n", true)

  run_command(command)
end


-- Expose the function to Neovim by creating a command
vim.cmd("command! -nargs=1 BFPrompt lua require'butterfish'.prompt(<q-args>)")
vim.cmd("command! -nargs=1 BFFilePrompt lua require'butterfish'.file_prompt(<q-args>)")
vim.cmd("command! -range -nargs=* BFRewrite :lua require'butterfish'.rewrite(<line1>, <line2>, <q-args>)")
vim.cmd("command! -range -nargs=* BFComment :lua require'butterfish'.comment(<line1>, <line2>)")

return butterfish


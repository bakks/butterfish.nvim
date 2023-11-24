local butterfish = {}
local basePath = vim.fn.expand("$HOME") .. "/butterfish.nvim/sh/"

-- [ ] Prompt with the file as context
-- [ ] Fix the error on the current line
-- [ ] Fill in a function
-- [ ] Rewrite selected text
-- [ ] Add a comment explaining the selected line / block
-- [ ] Ask a question about the selected line / block and write to comment


local color_to_change = "User1"
local active_color = "197"

local run_command = function(command)
  -- get current hi Statusline guibg color
  local original_hl = vim.api.nvim_get_hl_by_name(color_to_change, false).background
  -- set status bar to pink while running
  vim.cmd("hi User1 ctermbg=" .. active_color)

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

    on_exit = function()
      --reset status bar
      vim.cmd("hi " .. color_to_change .. " ctermbg=" .. original_hl)
    end,
  })
  
  -- print("Job ID: " .. job_id)
end

-- Define a function 'keys' that takes a single argument 'k'
-- Use neovim API to feed keys to the user interface
-- Convert the keycodes for visual mode end to ensure correct input
local keys = function(mode, k)
  vim.api.nvim_feedkeys(
    vim.api.nvim_replace_termcodes(k, true, true, true), mode, true)
end


-- Define a function that takes a text input and escapes single quotes by
-- adding a backslash before them
local escape_code = function(text)
  return text:gsub("'", "'\\''")
end

-- Enter an LLM prompt and write the response at the cursor
-- Script: prompt.sh
-- Args: filetype (language), prompt
butterfish.prompt = function(userPrompt)
  -- Get the current filetype of the buffer
  local filetype = vim.bo.filetype
  -- Create a command by concatenating the base path, script name, filetype, and escaped user prompt
  local command = basePath .. "prompt.sh " .. filetype .. " '" .. escape_code(userPrompt) .. "'"
  -- Execute the command by passing it to the run_command function
  run_command(command)
end

-- Enter an LLM prompt and write the response at the cursor, including the open
-- file as context
-- Script: fileprompt.sh
-- Args: file path, prompt
butterfish.file_prompt = function(userPrompt)
  -- Get the current filetype of the buffer
  local filetype = vim.bo.filetype
  -- Get the full path of the current file
  local filepath = vim.fn.expand("%:p")
  -- Create a command by concatenating the base path, script name, file path, and escaped user prompt
  local command = basePath .. "fileprompt.sh " .. filepath .. " '" .. escape_code(userPrompt) .. "'"
  -- Execute the command by passing it to the run_command function
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
    keys("n", "'>")
  end

  -- Insert a new line below current line
  vim.cmd("undojoin")
  keys("n", "A<CR><ESC>")

  -- Clear out the current line, this is necessary because we may have just
  -- commented out the line above, which may extend down to the newline we added
  vim.cmd("undojoin")
  keys("n", "_d$")

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
  keys("n", "O<ESC>")

  run_command(command)
end

-- Explain a line or block of code in detail
-- - If a single line, move up and create a newline like in butterfish.comment()
-- - If a block, remove the block
-- - Then call explain.sh
-- Script: explain.sh language selected_text
butterfish.explain = function(start_range, end_range)
  local filepath = vim.fn.expand("%:p")
  local lines = vim.api.nvim_buf_get_lines(0, start_range - 1, end_range, false)
  local selectedText = table.concat(lines, "\n")
  local command = basePath .. "explain.sh " .. filepath .. " '" .. escape_code(selectedText) .. "'"

  -- If a block of code, comment out the block or move to end
  if start_range ~= end_range then
    --vim.api.nvim_buf_set_lines(0, start_range - 1, end_range, false, {})
    if vim.fn.exists(":Commentary") then
      -- If the commentary plugin is installed, use it to comment out the selection
      vim.cmd("'<,'>Commentary")
      -- Move the cursor to the end of the range
      vim.api.nvim_win_set_cursor(0, {end_range, 0})
    else
      -- We don't know where the cursor is, so move it to the end of the selection
      keys("n", ",>")
    end

    -- Insert a new line below current line
    vim.cmd("undojoin")
    keys("n", "A<CR><ESC>")

    -- Clear out the current line, this is necessary because we may have just
    -- commented out the line above, which may extend down to the newline we added
    vim.cmd("undojoin")
    keys("n", "_d$")
  else
    -- If a single line, move up and create a newline
    -- Move to the beginning of the range
    vim.api.nvim_win_set_cursor(0, {start_range, 0})
    -- Add a new line above the current line
    keys("n", "O<ESC>")
  end

  run_command(command)
end


-- Attempt to fix the error on the current line
-- - Fetches the error message from the current line
-- - Fetches the 5 lines before and after the current line
-- - Comments out the current line
-- - Adds a new line below the current line
-- - Sends the error message to LLM
-- - Inserts the response at the cursor
-- Script: fix.sh filepath error_message
butterfish.fix = function()
  -- Get the current line number
  local line_number = vim.api.nvim_win_get_cursor(0)[1]
  -- Get the full path of the current file
  local filepath = vim.fn.expand("%:p")

  -- Safely retrieve the error message from line diagnostics
  local line_diagnostics = vim.lsp.diagnostic.get_line_diagnostics()
  local error_message = (line_diagnostics and line_diagnostics[line_number] and line_diagnostics[line_number][1] and line_diagnostics[line_number][1].message) or nil

  -- Get the 5 lines before and after the current line
  local context_start = math.max(0, line_number - 6)
  local context_end = line_number + 5
  local context_lines = vim.api.nvim_buf_get_lines(0, context_start, context_end, false)
  local context = table.concat(context_lines, "\n")

  -- Comment out the current line
  -- Check if Commentary plugin is installed
  if vim.fn.exists(":Commentary") then
    keys("n", ":" .. line_number .. "Commentary<CR>")
  end

  -- Add a new line below the current line
  keys("n", "A<CR><ESC>")

  -- Create a command to send the error message to LLM
  local command = basePath .. "fix.sh " .. filepath .. " '" .. escape_code(error_message) .. "' '" .. escape_code(context) .. "'"

  -- Send the command to LLM and insert the response at the cursor
  run_command(command)
end


-- Commands for each function
vim.cmd("command! -nargs=1 BFPrompt lua require'butterfish'.prompt(<q-args>)")
vim.cmd("command! -nargs=1 BFFilePrompt lua require'butterfish'.file_prompt(<q-args>)")
vim.cmd("command! -range -nargs=* BFRewrite :lua require'butterfish'.rewrite(<line1>, <line2>, <q-args>)")
vim.cmd("command! -range -nargs=* BFComment :lua require'butterfish'.comment(<line1>, <line2>)")
vim.cmd("command! -range -nargs=* BFExplain :lua require'butterfish'.explain(<line1>, <line2>)")
vim.cmd("command! BFFix lua require'butterfish'.fix()")

return butterfish


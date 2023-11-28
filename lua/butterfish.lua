-- butterfish.nvim
--   github.com/bakks/butterfish.nvim
--
-- This is a Neovim plugin for writing code with the help of large language
-- models. This file defines commands that can be called from Neovim, the
-- commands will stream LLM output to the current buffer. Each command has
-- a corresponding shell script which sets up the prompt and calls the LLM.

local butterfish = {}
local basePath = vim.fn.expand("$HOME") .. "/butterfish.nvim/sh/"
local color_to_change = "User1"
local active_color = "197"

local run_command = function(command, callback)
  -- get current highlight color
  local original_hl = vim.api.nvim_get_hl_by_name(color_to_change, false).background
  -- set status bar to pink while running
  vim.cmd("hi " .. color_to_change .. " ctermbg=" .. active_color)

  local job_id = vim.fn.jobstart(command, {
    on_stdout = function(job_id, data)
      vim.schedule(function()
        -- undojoin to prevent undoing the command
        vim.cmd("undojoin")
        -- insert text at cursor position, don't adjust indent, move cursor to end
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

    on_exit = function(job_id, exit_code, event_type)
      vim.schedule(function()
        -- call callback now that the child process is done
        if callback then
          callback()
        end
        --reset status bar
        vim.cmd("hi " .. color_to_change .. " ctermbg=" .. original_hl)
      end)
    end,
  })
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

-- Remove empty lines from the cursor line up until the first non-empty line
-- - Do a loop
-- - Get the current line
-- - If the line is empty, delete it
-- - If the line is not empty, break
local clean_up_empty_lines = function()
  -- Get the current line number
  local line_number = vim.api.nvim_win_get_cursor(0)[1]

  -- Start a loop that will continue until it hits a non-empty line
  while true do
    -- Get the text of the current line
    local line_text = vim.api.nvim_buf_get_lines(0, line_number - 1, line_number, false)[1]

    -- If the line is empty or only contains whitespace, delete it
    if line_text == nil or line_text:match("^%s*$") then
      vim.api.nvim_buf_set_lines(0, line_number - 1, line_number, false, {})
    else
      -- If the line is not empty, break the loop
      break
    end

    -- Decrement the line number to move up one line
    line_number = line_number - 1

    -- If we've reached the top of the file, break the loop
    if line_number == 0 then
      break
    end
  end
end

-- If the current line has text, create a new line below it and clear it out
-- if necessary
local move_to_clear_line = function()
  -- Get the current line number
  local line_number = vim.api.nvim_win_get_cursor(0)[1]

  -- Get the text of the current line
  local line_text = vim.api.nvim_buf_get_lines(0, line_number - 1, line_number, false)[1]

  -- If the line is not empty, create a new line below it and clear it out
  if line_text ~= nil and line_text ~= "" then
    -- Insert a new line below current line
    keys("n", "A<CR><ESC>")

    -- Clear out the current line, this is necessary because we may have just
    -- commented out the line above, which may extend down to the newline we added
    keys("n", "_d$<ESC>")
  end
end

-- Enter an LLM prompt and write the response at the cursor
-- Script: prompt.sh
-- Args: filetype (language), prompt
butterfish.prompt = function(userPrompt)
  -- Get the current filetype of the buffer
  local filetype = vim.bo.filetype
  -- Create a command by concatenating the base path, script name, filetype, and escaped user prompt
  local command = basePath .. "prompt.sh " .. filetype .. " '" .. escape_code(userPrompt) .. "'"

  move_to_clear_line()

  -- Execute the command by passing it to the run_command function
  run_command(command)
end

-- Enter an LLM prompt and write the response at the cursor, including the open
-- file as context
-- Script: fileprompt.sh filepath prompt
butterfish.file_prompt = function(userPrompt)
  -- Get the current filetype of the buffer
  local filetype = vim.bo.filetype
  -- Get the full path of the current file
  local filepath = vim.fn.expand("%:p")
  -- Create a command by concatenating the base path, script name, file path, and escaped user prompt
  local command = basePath .. "fileprompt.sh " .. filepath .. " '" .. escape_code(userPrompt) .. "'"

  move_to_clear_line()

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

  move_to_clear_line()

  run_command(command, clean_up_empty_lines)
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

  keys("n", " <BS><ESC>")
  -- Move to the beginning of the range
  vim.api.nvim_win_set_cursor(0, {start_range, 0})
  -- Add a new line above the current line
  keys("n", "O<ESC>")
  -- Clear out the current line, this is necessary because we may have just
  -- commented out the line above, which may extend down to the newline we added
  keys("n", "_d$<ESC>")

  run_command(command, clean_up_empty_lines)
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

    move_to_clear_line()
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
  local filetype = vim.bo.filetype

  -- Safely retrieve the error message from line diagnostics
  local line_diagnostics = vim.lsp.diagnostic.get_line_diagnostics()
  local error_message = (line_diagnostics and line_diagnostics[1] and line_diagnostics[1].message) or nil

  -- If there is no error message, return
  if error_message == nil then
    print("No error message found")
    return
  end

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

  move_to_clear_line()

  -- Create a command to send the error message to LLM
  local command = basePath .. "fix.sh " .. filetype .. " '" .. escape_code(error_message) .. "' '" .. escape_code(context) .. "'"

  -- Send the command to LLM and insert the response at the cursor
  run_command(command)
end

-- Implement the next block of code based on the previous lines
-- - Get the current line number
-- - Get the previous 150 lines
-- - Call implement.sh
-- Script: implement.sh previous_lines
butterfish.implement = function()
  -- Get the current line number
  local line_number = vim.api.nvim_win_get_cursor(0)[1]
  -- Get the file type
  local filetype = vim.bo.filetype
  -- Get the 150 lines before the current line
  local context_start = math.max(0, line_number - 150)
  local context_end = line_number - 1
  local context_lines = vim.api.nvim_buf_get_lines(0, context_start, context_end, false)
  local context = table.concat(context_lines, "\n")

  local command = basePath .. "implement.sh " .. filetype .. " '" .. escape_code(context) .. "'"

  move_to_clear_line()
  run_command(command)
end

-- Commands for each function
vim.cmd("command! -nargs=1 BFPrompt lua require'butterfish'.prompt(<q-args>)")
vim.cmd("command! -nargs=1 BFFilePrompt lua require'butterfish'.file_prompt(<q-args>)")
vim.cmd("command! -range -nargs=* BFRewrite :lua require'butterfish'.rewrite(<line1>, <line2>, <q-args>)")
vim.cmd("command! -range -nargs=* BFComment :lua require'butterfish'.comment(<line1>, <line2>)")
vim.cmd("command! -range -nargs=* BFExplain :lua require'butterfish'.explain(<line1>, <line2>)")
vim.cmd("command! BFFix lua require'butterfish'.fix()")
vim.cmd("command! BFImplement lua require'butterfish'.implement()")

return butterfish


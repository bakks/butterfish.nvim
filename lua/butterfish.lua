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

local original_hl = ""

local set_status_bar = function()
  -- get current highlight color
  original_hl = vim.api.nvim_get_hl_by_name(color_to_change, false).background
  -- set status bar to pink while running
  vim.cmd("hi " .. color_to_change .. " ctermbg=" .. active_color)
end

local reset_status_bar = function()
  --reset status bar
  vim.cmd("hi " .. color_to_change .. " ctermbg=" .. original_hl)
end

local run_command = function(command, callback)
  set_status_bar()

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
        reset_status_bar()
      end)
    end,
  })

  return job_id
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

-- Create empty line after current line or block
local move_down_to_clear_line = function(start_range, end_range)
  -- if a block
  if start_range ~= end_range then
    -- go to end of block
    vim.api.nvim_win_set_cursor(0, {end_range, 0})
  end

  -- Get the current line number
  local line_number = vim.api.nvim_win_get_cursor(0)[1]

  -- Get the text of the current line
  local line_text = vim.api.nvim_buf_get_lines(0, line_number - 1, line_number, false)[1]

  -- If the line is not empty, create a new line below it and clear it out
  if line_text ~= nil and line_text ~= "" then
    -- Insert a new line below current line
    keys("n", "A<CR><ESC>")

    -- Clear out the current line in case text like a comment was
    -- auto-inserted
    keys("n", "_d$<ESC>")
  end
end

-- Create empty line before current line or block
local move_up_to_clear_line = function(start_range, end_range)
  -- if a block
  if start_range ~= end_range then
    -- go to end of block
    vim.api.nvim_win_set_cursor(0, {start_range, 0})
  end

  -- Get the current line number
  local line_number = vim.api.nvim_win_get_cursor(0)[1]

  -- Get the text of the current line
  local line_text = vim.api.nvim_buf_get_lines(0, line_number - 1, line_number, false)[1]

  -- If the line is not empty, create a new line below it and clear it out
  if line_text ~= nil and line_text ~= "" then
    -- Insert a new line below current line
    keys("n", "O<ESC>")

    -- Clear out the current line in case text like a comment was
    -- auto-inserted
    keys("n", "_d$<ESC>")
  end
end

local comment_line_or_block = function(start_range, end_range)
  if not vim.fn.exists(":Commentary") then
    return
  end

  -- If a block of code
  if start_range ~= end_range then
    vim.cmd("'<,'>Commentary")
  else
    -- If a single line
    vim.cmd("Commentary")
  end
end

local comment_current_line = function()
  if vim.fn.exists(":Commentary") then
    keys("n", ":Commentary<CR>")
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

  move_down_to_clear_line()

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

  move_down_to_clear_line()

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

  comment_line_or_block(start_range, end_range)
  move_down_to_clear_line(start_range, end_range)

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

  move_up_to_clear_line(start_range, end_range)
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

  move_up_to_clear_line(start_range, end_range)
  run_command(command)
end

-- Ask a question about the current line or block
-- This will move above the line or block and create a new line
-- It will add "Question: <prompt>" to the new line and comment it out
-- Script: question.sh filepath selected_text prompt
butterfish.question = function(start_range, end_range, user_prompt)
  local filepath = vim.fn.expand("%:p")
  local lines = vim.api.nvim_buf_get_lines(0, start_range - 1, end_range, false)
  local selectedText = table.concat(lines, "\n")
  local command = basePath .. "question.sh " .. filepath .. " '" .. escape_code(selectedText) .. "' '" .. user_prompt .. "'"

  move_up_to_clear_line(start_range, end_range)

  -- Add Question: <prompt> to the new line and comment it out
  keys("n", "iQuestion: " .. user_prompt .. "<ESC>")
  comment_current_line()

  -- Add Answer: to a new line below the current line
  keys("n", "oAnswer:  <ESC>")
  comment_current_line()
  keys("n", "A<ESC>")

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

  move_down_to_clear_line()

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
  local context_end = line_number
  local context_lines = vim.api.nvim_buf_get_lines(0, context_start, context_end, false)
  local context = table.concat(context_lines, "\n")

  local command = basePath .. "implement.sh " .. filetype .. " '" .. escape_code(context) .. "'"

  move_down_to_clear_line()
  run_command(command)
end

-- Locate a hammer.sh script and return the absolute path
-- Start in the current directory and move up until we find a hammer.sh script
local find_hammer_script = function()
  local hammer_script = "hammer.sh"
  local current_dir = vim.fn.expand("%:p:h")
  local hammer_script_path = current_dir .. "/" .. hammer_script

  while true do
    if vim.fn.filereadable(hammer_script_path) == 1 then
      return hammer_script_path
    end

    if current_dir == "/" then
      return nil
    end

    current_dir = vim.fn.fnamemodify(current_dir, ":h")
    hammer_script_path = current_dir .. "/" .. hammer_script
  end
end

local hammer_header = "butterfish::hammer"


local commentify = function(data)
  -- Get the commentstring and extract the leader
  local commentstring = vim.api.nvim_buf_get_option(0, 'commentstring')
  local commentleader = string.match(commentstring, "^.*%%s")
  commentleader = string.gsub(commentleader, "%%s", "")

  -- if data is more than one line, add comment leader the later lines
  if #data > 1 then
    for i = 2, #data do
      data[i] = commentleader .. data[i]
    end
  end

  return data
end

-- A function to convert an object/table to a string, even if it contains
-- nested tables
local object_tree_to_string
object_tree_to_string = function(object, indent)
  -- If the object is a string, return it
  if type(object) == "string" then
    return object
  end

  -- If the object is a table, convert it to a string
  if type(object) == "table" then
    -- If the object is empty, return an empty string
    if next(object) == nil then
      return ""
    end

    -- If the object is a list, convert it to a string
    if #object > 0 then
      local string_list = {}
      for _, value in ipairs(object) do
        table.insert(string_list, object_tree_to_string(value, indent))
      end
      return table.concat(string_list, "\n")
    end

    -- If the object is a map, convert it to a string
    local string_map = {}
    for key, value in pairs(object) do
      table.insert(string_map, key .. ": " .. object_tree_to_string(value, indent))
    end
    return table.concat(string_map, "\n")
  end

  -- If the object is not a string or a table, return an empty string
  return ""
end

local p = function(str)
  vim.api.nvim_put({"", str}, 'c', { append = true }, true)
end


local hammer_original_window = nil
local hammer_buffer = nil
local hammer_window = nil

-- Function to create a new split window, create a buffer
function hammer_create_split()
  if hammer_buffer == nil then
    -- Create a new buffer and get its buffer number
    hammer_buffer = vim.api.nvim_create_buf(false, true)
  else
    -- Clear the buffer
    vim.api.nvim_buf_set_lines(hammer_buffer, 0, -1, false, {})
  end

  hammer_original_window = vim.api.nvim_get_current_win()

  if hammer_window == nil or not vim.api.nvim_win_is_valid(hammer_window) then
    -- Split the window horizontally with new split on the bottom
    vim.cmd("split")
    vim.cmd("wincmd J")

    -- Get the current window
    hammer_window = vim.api.nvim_get_current_win()

    -- Set the current window's buffer to the new buffer
    vim.api.nvim_win_set_buf(hammer_window, hammer_buffer)
  end

end

function hammer_append(text)
  if hammer_buffer == nil then
    return
  end

  to_add = text

  if type(text) == "string" then
    to_add = {text}
  end

  -- switch to hammer window
  vim.api.nvim_set_current_win(hammer_window)

  -- vim.api.nvim_put(to_add, 'c', { append = true }, true)
  vim.api.nvim_put(to_add, 'c', true, true)
end

function hammer_append_line(text)
  hammer_append({text, ""})
end


local hammer_step2 = function(status)
  if status == 0 then
    -- new line below
    vim.schedule(function()
      hammer_append("Hammer succeeded")
    end)
    reset_status_bar()
    return
  end

  vim.api.nvim_set_current_win(hammer_original_window)

  -- write file to disk (the original buffer, not the hammer buffer)
  vim.cmd("w!")

  -- Now we run the plugin hammer script, which preps and then runs
  -- a double prompt, meaning first it asks for a fix plan, that
  -- should return a function call, and it should reference a specific
  -- function in this call. We find the appropriate and then rewrite
  -- that given the output of the 2nd prompting
  local filepath = vim.fn.expand("%:p")
  local filetype = vim.bo.filetype

  vim.api.nvim_set_current_win(hammer_window)

  local command = basePath .. "hammer.sh " .. filetype .. " " .. filepath .. " '" .. escape_code(hammerlog) .. "'"
  local found_function = false

  local job_id = vim.fn.jobstart(command, {
    on_stdout = function(job_id, data)
      vim.schedule(function()
        hammer_append(data)
      end)
    end,

    on_stderr = function(job_id, data)
      vim.schedule(function()
        hammer_append(data)
      end)
    end,

    on_exit = function(job_id, exit_code, event_type)
      vim.schedule(function()
        -- swap back to original window and reload
        vim.api.nvim_set_current_win(hammer_original_window)
        vim.cmd("e!")

        hammer_append("Hammer script exited with " .. exit_code)
        reset_status_bar()
      end)
    end,
  })
end


local hammer_step = function()
  -- set formatoptions to ensure comment continues on next line with setlocal fo+=ro
  vim.cmd("setlocal fo+=ro")

  -- Comment the current line
  move_down_to_clear_line()

  keys("n", "i" .. hammer_header .. "<ESC>")

  if vim.fn.exists(":Commentary") then
    keys("n", ":Commentary<CR>")
  end

  -- new line below
  keys("n", "o <ESC>")

  set_status_bar()
  local status = -1

  -- look for hammer.sh in the current directory and up
  local hammer_script_path = find_hammer_script()
  if hammer_script_path == nil then
    vim.api.nvim_err_writeln("Could not find hammer.sh, add it to the base dir of this project")
    reset_status_bar()
    return
  end

  hammerlog = ""

  -- This runs user-defined hammer script, the assumption
  -- is that it will be in the current directory or in a dir up the
  -- file tree, e.g. in the base dir
  -- The hammer script should return non-zero if there is more work
  -- and it should output debugging info, like build errors or test
  -- failures
  local job_id = vim.fn.jobstart(hammer_script_path, {
    on_stdout = function(job_id, data)
      vim.schedule(function()
        hammer_append(data)
        hammerlog = hammerlog .. table.concat(data, "\n")
      end)
    end,

    on_stderr = function(job_id, data)
      vim.schedule(function()
        hammer_append(data)
        hammerlog = hammerlog .. table.concat(data, "\n")
      end)
    end,

    on_exit = function(job_id, exit_code, event_type)
      to_print = status_text
      vim.schedule(function()
        status_text = "status: " .. exit_code
        hammer_append_line(status_text)
        hammer_step2(exit_code)
      end)
    end,
  })
end

-- Hammer mode loops the LM until it reaches an end condition. The end
-- condition is defined in hammer.sh in the base path, i.e. it returns non-zero
-- if not met. For example, you could set hammer.sh to run tests, when it runs
-- it produces first compiler errors, which the LM fixes, then it produces test
-- failures, which the LM fixes, then hammer.sh exits with 0 when all tests pass.
-- Loop steps:
--  - Run hammer.sh, get the exit code and output
--    - If exit code is 0, exit
--  - Add / update hammer annotation
--  - Send file content and hammer.sh output to LM, ask for a fix plan,
--    explanation, and location (function level)
--  - Send file content and fix plan to LM, ask to rewrite the function
butterfish.hammer = function()
  hammer_create_split()
  hammer_append("Hammer mode started")
  hammer_step()
end

-- Commands for each function
vim.cmd("command! -nargs=1 BFPrompt lua require'butterfish'.prompt(<q-args>)")
vim.cmd("command! -nargs=1 BFFilePrompt lua require'butterfish'.file_prompt(<q-args>)")
vim.cmd("command! -range -nargs=* BFRewrite :lua require'butterfish'.rewrite(<line1>, <line2>, <q-args>)")
vim.cmd("command! -range -nargs=* BFComment :lua require'butterfish'.comment(<line1>, <line2>)")
vim.cmd("command! -range -nargs=* BFExplain :lua require'butterfish'.explain(<line1>, <line2>)")
vim.cmd("command! -range -nargs=* BFQuestion :lua require'butterfish'.question(<line1>, <line2>, <q-args>)")
vim.cmd("command! BFFix lua require'butterfish'.fix()")
vim.cmd("command! BFImplement lua require'butterfish'.implement()")
vim.cmd("command! BFHammer lua require'butterfish'.hammer()")

return butterfish


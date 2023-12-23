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
local original_hl_toggle = false

local set_status_bar = function()
  if original_hl_toggle then
    return
  end

  -- get current highlight color
  original_hl = vim.api.nvim_get_hl_by_name(color_to_change, false).background
  -- set status bar to pink while running
  vim.cmd("hi " .. color_to_change .. " ctermbg=" .. active_color)

  original_hl_toggle = true
end

local reset_status_bar = function()
  --reset status bar
  vim.cmd("hi " .. color_to_change .. " ctermbg=" .. original_hl)
  original_hl_toggle = false
end

-- Function to get line range based on mode
local function get_line_range(range_start, range_end)
  if range_start == nil or range_end == nil then
    return vim.api.nvim_win_get_cursor(0)[1]
  end

  return range_start .. "-" .. range_end
end


-- Define a function that takes a text input and escapes single quotes by
-- adding a backslash before them
local escape_code = function(text)
  if text == nil then
    return ""
  end
  return text:gsub("'", "'\\''")
end

-- Call a command with the standard arguments, return the job id, call the
-- callback when the job is done
-- Args:
--  command     name of the script to run
--  user_prompt  prompt to send to LLM
--  callback    function to call when the job is done
-- Script: command.sh filetype filepath line_range prompt
--  filetype    filetype of the current buffer
--  filepath    full path of the current file
--  line_range  line number or line range
--  prompt      prompt to send to LLM
--
-- For example, to call the prompt.sh script:
-- command("prompt.sh", "What is the meaning of life?", function() print("done") end)
-- This will call the prompt.sh script like:
--   prompt.sh go main.go 42 'What is the meaning of life?'
butterfish.command = function(command, user_prompt, range_start, range_end, callback)
  local filetype = vim.bo.filetype
  local filepath = vim.fn.expand("%:p")
  local line_range = get_line_range(range_start, range_end)

  local shell_command = basePath ..
    "/" .. command ..
    " " .. filetype ..
    " " .. filepath ..
    " " .. line_range ..
    " '" .. escape_code(user_prompt) .. "'"

  set_status_bar()

  -- write the current file to disk
  vim.cmd("w!")
  first = true

  local job_id = vim.fn.jobstart(shell_command, {
    on_stdout = function(job_id, data)
      vim.schedule(function()
        -- undojoin to prevent undoing the command
        if not first then
          vim.cmd("undojoin")
        else
          first = false
        end
        -- insert text at cursor position, don't adjust indent, move cursor to end
        vim.api.nvim_put(data, 'c', true, true)
      end)
    end,

    on_stderr = function(job_id, data)
      vim.schedule(function()
        -- undojoin to prevent undoing the command
        if not first then
          vim.cmd("undojoin")
        else
          first = false
        end
        -- insert text at cursor position, don't adjust indent, move cursor to end
        vim.api.nvim_put(data, 'c', true, true)
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
    keys("n", "o<ESC>")

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
-- Args:
--   user_prompt    prompt added by user from command, will be sent to LM
butterfish.prompt = function(user_prompt)
  move_down_to_clear_line()

  -- Execute the command
  butterfish.command("prompt.sh", user_prompt)
end

-- Enter an LLM prompt and write the response at the cursor, including the open
-- Args:
--   user_prompt    prompt added by user from command, will be sent to LM
butterfish.file_prompt = function(user_prompt)
  move_down_to_clear_line()

  -- Execute the command
  butterfish.command("fileprompt.sh", user_prompt)
end

-- Rewrite the selected text given instructions from the prompt
-- Args:
--   start_range    start of visual line range
--   end_range      end of visual line range
--   user_prompt     prompt to send to LLM
butterfish.rewrite = function(start_range, end_range, user_prompt)
  move_down_to_clear_line(start_range, end_range)

  butterfish.command("rewrite.sh", user_prompt, start_range, end_range, clean_up_empty_lines)

  -- The above call is async, we put this after so that we comment out the block
  -- after the file save but before any results are streamed back
  comment_line_or_block(start_range, end_range)
end

-- Add a comment above the current line or block explaining it
butterfish.comment = function(start_range, end_range)
  move_up_to_clear_line()
  butterfish.command("comment.sh", nil, start_range, end_range)
end

-- Explain a line or block of code in detail
-- - If a single line, move up and create a newline like in butterfish.comment()
-- - If a block, remove the block
-- - Then call explain.sh
butterfish.explain = function(start_range, end_range)
  move_up_to_clear_line(start_range, end_range)
  butterfish.command("explain.sh", nil, start_range, end_range)
end


-- Ask a question about the current line or block
-- This will move above the line or block and create a new line
-- It will add "Question: <prompt>" to the new line and comment it out
butterfish.question = function(start_range, end_range, user_prompt)
  move_up_to_clear_line(start_range, end_range)

  -- Add Question: <prompt> to the new line and comment it out
  keys("n", "iQuestion: " .. user_prompt .. "<ESC>")
  comment_current_line()
  move_down_to_clear_line()

  butterfish.command("question.sh", user_prompt, start_range, end_range)
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

  -- Safely retrieve the error message from line diagnostics
  local line_diagnostics = vim.lsp.diagnostic.get_line_diagnostics()
  local error_message = (line_diagnostics and line_diagnostics[1] and line_diagnostics[1].message) or nil

  -- If there is no error message, return
  if error_message == nil then
    print("No error message found")
    return
  end

  -- Get the 5 lines before and after the current line
  local context_start = math.max(1, line_number - 6)
  local context_end = line_number + 5

  move_down_to_clear_line()

  butterfish.command("fix.sh", error_message, context_start, context_end)
  comment_line_or_block(line_number, line_number)
end

-- Implement the next block of code based on the previous lines
-- - Get the current line number
-- - Get the previous 150 lines
-- - Call implement.sh
-- Script: implement.sh previous_lines
butterfish.implement = function()
  move_down_to_clear_line()
  butterfish.command("implement.sh", nil, context_end)
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


-- Define a HammerContext class
local SplitContext = {}
SplitContext.__index = SplitContext

-- Constructor for SplitContext
function SplitContext.new()
  local self = setmetatable({}, SplitContext)
  self.buffer = nil
  self.window = nil
  self.original_window = nil
  return self
end

-- Create a new split window, create a buffer
function SplitContext:create_split()
  if self.buffer == nil then
    -- Create a new buffer and get its buffer number
    self.buffer = vim.api.nvim_create_buf(false, true)
  else
    -- Clear the buffer
    vim.api.nvim_buf_set_lines(self.buffer, 0, -1, false, {})
  end

  self.original_window = vim.api.nvim_get_current_win()

  if self.window == nil or not vim.api.nvim_win_is_valid(self.window) then
    -- Split the window horizontally with new split on the bottom
    vim.cmd("split")
    vim.cmd("wincmd J")

    -- Get the current window
    self.window = vim.api.nvim_get_current_win()

    -- Set the current window's buffer to the new buffer
    vim.api.nvim_win_set_buf(self.window, self.buffer)
  end
end

-- Append text to the buffer
function SplitContext:append(text)
  if self.buffer == nil then
    return
  end

  local to_add = text

  if type(text) == "string" then
    to_add = {text}
  end

  -- Switch to hammer window
  vim.api.nvim_set_current_win(self.window)

  vim.api.nvim_put(to_add, 'c', true, true)
end

-- Append text as a new line in the buffer
function SplitContext:append_line(text)
  self:append({text, ""})
end

-- Switch to the hammer window
function SplitContext:switch_to_window()
  vim.api.nvim_set_current_win(self.window)
end

-- SplitContext method to switch back to the original window
function SplitContext:switch_to_original_window()
  vim.api.nvim_set_current_win(self.original_window)
end


local hammer_ttl = 0
local hammer_split_context = nil
local hammer_step1 = nil

-- Hammer step two checks the output of the project hammer.sh script and
-- if it has a nonzero exit then it runs the plugin hammer.sh script to
-- invoke the LM
local hammer_step2 = function(status)
  if status == 0 then
    reset_status_bar()
    hammer_split_context:append("Hammer succeeded")
    return
  end

  hammer_split_context:switch_to_original_window()

  -- write file to disk (the original buffer, not the hammer buffer)
  vim.cmd("w!")

  -- Now we run the plugin hammer script which asks the LM for a fix plan
  -- based on the failure in the hammer.sh log
  local filepath = vim.fn.expand("%:p")
  local filetype = vim.bo.filetype

  hammer_split_context:switch_to_window()

  local command = basePath .. "hammer.sh " ..
    filetype .. " " ..
    filepath .. " " ..
    "1 " .. -- dummy line range
    "'" .. escape_code(hammerlog) .. "'"

  local found_function = false

  local job_id = vim.fn.jobstart(command, {
    on_stdout = function(job_id, data)
      vim.schedule(function()
        hammer_split_context:append(data)
      end)
    end,

    on_stderr = function(job_id, data)
      vim.schedule(function()
        hammer_split_context:append(data)
      end)
    end,

    on_exit = function(job_id, exit_code, event_type)
      vim.schedule(function()
        -- swap back to original window and reload
        hammer_split_context:switch_to_original_window()
        vim.cmd("e!")

        hammer_step1()
      end)
    end,
  })
end

-- Hammer step one locates the project's hammer.sh script and runs it
hammer_step1 = function()
  -- If TTL has hit 0 then stop
  if hammer_ttl == 0 then
    vim.schedule(function()
      hammer_split_context:append("Hammer hit loop limit")
      reset_status_bar()
    end)
    return
  end

  hammer_ttl = hammer_ttl - 1

  set_status_bar()

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
  vim.fn.jobstart(hammer_script_path, {
    on_stdout = function(job_id, data)
      vim.schedule(function()
        hammer_split_context:append(data)
        hammerlog = hammerlog .. table.concat(data, "\n")
      end)
    end,

    on_stderr = function(job_id, data)
      vim.schedule(function()
        hammer_split_context:append(data)
        hammerlog = hammerlog .. table.concat(data, "\n")
      end)
    end,

    on_exit = function(job_id, exit_code, event_type)
      to_print = status_text
      vim.schedule(function()
        status_text = "status: " .. exit_code
        hammer_split_context:append_line(status_text)
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
--  - Send file content and hammer.sh output to LM, ask for fixes, returned and applied as LM tools
--  - File is saved and reloaded
butterfish.hammer = function()
  hammer_ttl = 5 -- Loop a max of 5 times

  if hammer_split_context == nil then
    hammer_split_context = SplitContext.new()
  end

  hammer_split_context:create_split()
  hammer_split_context:append_line("Hammer mode started")
  hammer_step1()
end

edit_split = nil

-- Function to edit the current buffer using LLM
butterfish.edit = function(prompt)
  -- Write the current buffer to disk
  vim.cmd("w!")

  -- Set status bar to indicate the operation
  set_status_bar()

  -- Get the current file path and file type
  local filepath = vim.fn.expand("%:p")
  local filetype = vim.bo.filetype

  -- Create a command to send to the LLM for editing the current buffer
  local command = basePath ..
    "edit.sh " ..
    filetype .. " " ..
    filepath .. " " ..
    "1 " .. -- dummy line range
    "'" .. escape_code(prompt) .. "'"

  if edit_split == nil then
    edit_split = SplitContext.new()
  end
  edit_split:create_split()
  edit_split:append_line("Editing " .. filepath)

  vim.fn.jobstart(command, {
    on_stdout = function(job_id, data)
      vim.schedule(function()
        edit_split:append(data)
      end)
    end,

    on_stderr = function(job_id, data)
      vim.schedule(function()
        edit_split:append(data)
      end)
    end,

    on_exit = function(job_id, exit_code, event_type)
      vim.schedule(function()
        -- swap back to original window and reload
        edit_split:switch_to_original_window()
        vim.cmd("e!")
        reset_status_bar()
      end)
    end,
  })
end

-- Commands for each function
vim.cmd("command! -nargs=* BFPrompt lua require'butterfish'.prompt(<q-args>)")
vim.cmd("command! -nargs=* BFFilePrompt lua require'butterfish'.file_prompt(<q-args>)")
vim.cmd("command! -range -nargs=* BFRewrite :lua require'butterfish'.rewrite(<line1>, <line2>, <q-args>)")
vim.cmd("command! -range -nargs=* BFComment :lua require'butterfish'.comment(<line1>, <line2>)")
vim.cmd("command! -range -nargs=* BFExplain :lua require'butterfish'.explain(<line1>, <line2>)")
vim.cmd("command! -range -nargs=* BFQuestion :lua require'butterfish'.question(<line1>, <line2>, <q-args>)")
vim.cmd("command! BFFix lua require'butterfish'.fix()")
vim.cmd("command! BFImplement lua require'butterfish'.implement()")
vim.cmd("command! -nargs=* BFEdit lua require'butterfish'.edit(<q-args>)")
vim.cmd("command! BFHammer lua require'butterfish'.hammer()")

return butterfish


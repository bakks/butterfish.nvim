-- butterfish.nvim
--   github.com/bakks/butterfish.nvim
--
-- This is a Neovim plugin for writing code with the help of large language
-- models. This file defines commands that can be called from Neovim, the
-- commands will stream LLM output to the current buffer. Each command has
-- a corresponding shell script which sets up the prompt and calls the LLM.

local butterfish = {}

-- Default LM settings, these are passed to the LLM scripts, but note that
-- the scripts can override these settings
butterfish.lm_base_path = "https://api.openai.com/v1"
butterfish.lm_smart_model = "gpt-5.4"

-- When running, Butterfish will record the current color and then run
-- :hi [active_color_group] ctermbg=[active_color_cterm] guibg=[active_color_gui]
-- This will be reset when the command is done
butterfish.active_color_group = "StatusLine"
butterfish.active_color_cterm = "197"
butterfish.active_color_gui = "#ff33cc"

-- get path to this script
local function get_script_path()
  local str = debug.getinfo(2, "S").source:sub(2)
  return str:match("(.*/)")
end

-- Where to look for bash scripts that are used to call the LLM
-- This can be customized to use your own scripts
butterfish.script_dir = get_script_path() .. "../../bin/"

local original_hl = ""
local original_hl_toggle = false
local active_jobs = {}
local cancelled_jobs = {}
local active_job_count = 0
local job_buffers = {}
local job_states = {}
local locked_buffers = {}
local stream_ns = vim.api.nvim_create_namespace("butterfish_stream")

local highlight_exists = function(group)
  local exists = vim.fn.hlexists(group)
  return exists == 1
end

local set_status_bar = function()
  -- if we've already set status bar, return
  if original_hl_toggle then
    return
  end

  -- if the highlight group doesn't exist, return
  if vim.fn.hlexists(butterfish.active_color_group) == 0 then
    return
  end

  -- get current highlight color
  original_hl = vim.api.nvim_get_hl_by_name(butterfish.active_color_group, true)

  -- set status bar to pink while running
  vim.cmd("hi " .. butterfish.active_color_group ..
    " ctermbg=" .. butterfish.active_color_cterm ..
    " guibg=" .. butterfish.active_color_gui)

  original_hl_toggle = true
end

local reset_status_bar = function()
  -- if the highlight group doesn't exist, return
  if vim.fn.hlexists(butterfish.active_color_group) == 0 then
    return
  end

  --reset status bar
  local cleaned_original_hl = {
    ctermbg = original_hl.ctermbg, guibg = original_hl.guibg}
  vim.api.nvim_set_hl(0, butterfish.active_color_group, cleaned_original_hl)
  original_hl_toggle = false
end

local lock_buffer = function(bufnr)
  if bufnr == nil or not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end

  local state = locked_buffers[bufnr]
  if state == nil then
    state = {
      count = 0,
      modifiable = vim.bo[bufnr].modifiable,
    }
    locked_buffers[bufnr] = state
    vim.bo[bufnr].modifiable = false
  end
  state.count = state.count + 1
end

local unlock_buffer = function(bufnr)
  if bufnr == nil then
    return
  end

  local state = locked_buffers[bufnr]
  if state == nil then
    return
  end

  state.count = state.count - 1
  if state.count <= 0 then
    if vim.api.nvim_buf_is_valid(bufnr) then
      vim.bo[bufnr].modifiable = state.modifiable
    end
    locked_buffers[bufnr] = nil
  end
end

local with_temporary_modifiable = function(bufnr, fn)
  local state = locked_buffers[bufnr]
  if state ~= nil and vim.api.nvim_buf_is_valid(bufnr) then
    vim.bo[bufnr].modifiable = true
  end

  local ok, err = pcall(fn)

  if state ~= nil and vim.api.nvim_buf_is_valid(bufnr) then
    vim.bo[bufnr].modifiable = false
  end

  if not ok then
    vim.api.nvim_err_writeln("Butterfish write failed: " .. tostring(err))
  end
end

local create_stream_state = function(bufnr)
  if bufnr == nil or not vim.api.nvim_buf_is_valid(bufnr) then
    return nil
  end

  local cursor = vim.api.nvim_win_get_cursor(0)
  local mark_id = vim.api.nvim_buf_set_extmark(
    bufnr,
    stream_ns,
    cursor[1] - 1,
    cursor[2],
    { right_gravity = true })

  return {
    bufnr = bufnr,
    mark_id = mark_id,
  }
end

local dispose_stream_state = function(state)
  if state == nil or state.bufnr == nil or state.mark_id == nil then
    return
  end
  if not vim.api.nvim_buf_is_valid(state.bufnr) then
    return
  end
  pcall(vim.api.nvim_buf_del_extmark, state.bufnr, stream_ns, state.mark_id)
end

local get_stream_position = function(state)
  if state == nil or state.bufnr == nil or state.mark_id == nil then
    return nil, nil
  end
  if not vim.api.nvim_buf_is_valid(state.bufnr) then
    return nil, nil
  end

  local pos = vim.api.nvim_buf_get_extmark_by_id(state.bufnr, stream_ns, state.mark_id, {})
  if pos == nil or #pos < 2 then
    return nil, nil
  end

  return pos[1], pos[2]
end

local append_stream_data = function(state, data)
  if state == nil or data == nil or #data == 0 then
    return
  end

  local row, col = get_stream_position(state)
  if row == nil or col == nil then
    return
  end

  vim.api.nvim_buf_set_text(state.bufnr, row, col, row, col, data)
end

local get_cleanup_target = function(state)
  if state ~= nil then
    local row, _ = get_stream_position(state)
    if row ~= nil then
      return state.bufnr, row + 1
    end
  end

  return 0, vim.api.nvim_win_get_cursor(0)[1]
end

local track_job_started = function(job_id, bufnr, state)
  if job_id == nil or job_id <= 0 then
    return false
  end
  if not active_jobs[job_id] then
    active_jobs[job_id] = true
    active_job_count = active_job_count + 1
  end
  job_buffers[job_id] = bufnr
  job_states[job_id] = state
  lock_buffer(bufnr)
  return true
end

local track_job_finished = function(job_id)
  local bufnr = job_buffers[job_id]
  local state = job_states[job_id]
  job_buffers[job_id] = nil
  job_states[job_id] = nil
  dispose_stream_state(state)
  unlock_buffer(bufnr)

  if active_jobs[job_id] then
    active_jobs[job_id] = nil
    active_job_count = active_job_count - 1
  end
  cancelled_jobs[job_id] = nil
  if active_job_count <= 0 then
    active_job_count = 0
    reset_status_bar()
  end
end

-- Function to get line range based on mode
local function get_line_range(range_start, range_end)
  if range_start == nil or range_end == nil then
    return vim.api.nvim_win_get_cursor(0)[1]
  end

  return range_start .. "-" .. range_end
end

local ensure_buffer_available = function()
  local bufnr = vim.api.nvim_get_current_buf()
  if locked_buffers[bufnr] ~= nil then
    vim.api.nvim_err_writeln("Butterfish request already running for this buffer. Use :BFCancel to stop it.")
    return false
  end
  return true
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
--
-- The commands called here should accept the following arguments:
--  filetype    filetype of the current buffer
--  filepath    full path of the current file
--  line_range  line number or line range
--  prompt      prompt to send to LLM
--  model       model to use, if nil then use the default
--  basepath    LM service URL, if nil then use the default
--
-- For example, to call the prompt.sh script:
-- command("prompt.sh", "What is the meaning of life?", 41, 42, function() print("done") end)
-- This will call the prompt.sh script like:
--   prompt go main.go 41-42 'What is the meaning of life?' [default model] [default basepath]
butterfish.command = function(
  command,      -- name of the script to run, will look in script_dir
  user_prompt,  -- prompt to send to LLM
  range_start,  -- start of visual line range
  range_end,    -- end of visual line range
  callback,     -- function to call when the job is done
  model,        -- model to use, if nil then use the default
  basepath,     -- LM service URL, if nil then use the default
  first_action) -- if this is the first action in a sequence, don't undojoin

  if first_action == nil then
    first_action = true
  end

  local filetype = vim.bo.filetype
  local filepath = vim.fn.expand("%:p")
  local bufnr = vim.api.nvim_get_current_buf()
  local line_range = get_line_range(range_start, range_end)

  if model == nil then
    model = butterfish.lm_smart_model
  end

  if basepath == nil then
    basepath = butterfish.lm_base_path
  end

  local shell_command = butterfish.script_dir ..
    "/" .. command ..
    " " .. filetype ..
    " " .. filepath ..
    " " .. line_range ..
    " '" .. escape_code(user_prompt) .. "'" ..
    " '" .. model .. "'" ..
    " '" .. basepath .. "'"

  set_status_bar()

  -- write the current file to disk
  vim.cmd("silent noautocmd w!")
  local state = create_stream_state(bufnr)

  local stream_chunk_is_empty = function(data)
    if data == nil or #data == 0 then
      return true
    end
    for _, line in ipairs(data) do
      if line ~= "" then
        return false
      end
    end
    return true
  end

  local job_id = vim.fn.jobstart(shell_command, {
    on_stdout = function(job_id, data)
      vim.schedule(function()
        if cancelled_jobs[job_id] then
          return
        end
        if stream_chunk_is_empty(data) then
          return
        end

        -- undojoin to prevent undoing the command
        with_temporary_modifiable(bufnr, function()
          if not vim.api.nvim_buf_is_valid(bufnr) then
            return
          end
          vim.api.nvim_buf_call(bufnr, function()
            if not first_action then
              -- undojoin can fail if vim undo state changed; keep streaming anyway
              pcall(vim.cmd, "undojoin")
            end
            append_stream_data(job_states[job_id], data)
            first_action = false
          end)
        end)
      end)
    end,

    on_stderr = function(job_id, data)
      vim.schedule(function()
        if cancelled_jobs[job_id] then
          return
        end
        if stream_chunk_is_empty(data) then
          return
        end

        with_temporary_modifiable(bufnr, function()
          if not vim.api.nvim_buf_is_valid(bufnr) then
            return
          end
          vim.api.nvim_buf_call(bufnr, function()
            -- undojoin to prevent undoing the command
            if not first_action then
              -- undojoin can fail if vim undo state changed; keep streaming anyway
              pcall(vim.cmd, "undojoin")
            end
            append_stream_data(job_states[job_id], data)
            first_action = false
          end)
        end)
      end)
    end,

    on_exit = function(job_id, exit_code, event_type)
      vim.schedule(function()
        local was_cancelled = cancelled_jobs[job_id] == true

        -- call callback now that the child process is done, unless cancelled
        if callback and not was_cancelled and exit_code == 0 then
          with_temporary_modifiable(bufnr, function()
            callback(job_states[job_id])
          end)
        end
        track_job_finished(job_id)
      end)
    end,
  })

  if not track_job_started(job_id, bufnr, state) then
    dispose_stream_state(state)
    reset_status_bar()
  end

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
local clean_up_empty_lines = function(state)
  local bufnr, line_number = get_cleanup_target(state)

  -- Start a loop that will continue until it hits a non-empty line
  while true do
    -- Get the text of the current line
    local line_text = vim.api.nvim_buf_get_lines(bufnr, line_number - 1, line_number, false)[1]

    -- If the line is empty or only contains whitespace, delete it
    if line_text == nil or line_text:match("^%s*$") then
      vim.api.nvim_buf_set_lines(bufnr, line_number - 1, line_number, false, {})
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

-- If called with a range, move down to the end of the range, then if that
-- line is not empty, create a new line below it and clear it out.
-- If called without a range do that from the current cursor position.
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
  local made_change = false
  if line_text ~= nil and line_text ~= "" then
    -- Insert a blank line below current line and place cursor there.
    vim.api.nvim_buf_set_lines(0, line_number, line_number, false, {""})
    vim.api.nvim_win_set_cursor(0, {line_number + 1, 0})
    made_change = true
  end

  return made_change
end

-- If called with a range, move up to the beginning of the range, then if that
-- line is not empty, create a new line above it and clear it out.
-- If called without a range do that from the current cursor position.
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

  -- If the line is not empty, create a new line above it and clear it out
  local made_change = false
  if line_text ~= nil and line_text ~= "" then
    -- Insert a blank line above current line and place cursor there.
    vim.api.nvim_buf_set_lines(0, line_number - 1, line_number - 1, false, {""})
    vim.api.nvim_win_set_cursor(0, {line_number, 0})
    made_change = true
  end

  return made_change
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

-- Remove the current line only if it is empty/whitespace.
-- Used after streaming commands that might or might not leave a trailing newline.
local delete_current_line_if_empty = function(state)
  local bufnr, line_number = get_cleanup_target(state)
  local line_text = vim.api.nvim_buf_get_lines(bufnr, line_number - 1, line_number, false)[1]
  if line_text == nil or line_text:match("^%s*$") then
    vim.api.nvim_buf_set_lines(bufnr, line_number - 1, line_number, false, {})
  end
end

-- Enter an LLM prompt and write the response at the cursor
-- Args:
--   start_range    start of visual line range
--   end_range      end of visual line range
--   user_prompt    prompt added by user from command, will be sent to LM
butterfish.prompt = function(start_range, end_range, user_prompt)
  if not ensure_buffer_available() then
    return
  end
  local made_change = move_down_to_clear_line(start_range, end_range)

  -- Execute the command
  butterfish.command(
    "prompt",
    user_prompt,
    start_range,
    end_range,
    nil,
    butterfish.lm_smart_model,
    nil,
    not made_change)
end

-- Enter an LLM prompt and write the response at the cursor, including the open
-- Args:
--   start_range    start of visual line range
--   end_range      end of visual line range
--   user_prompt    prompt added by user from command, will be sent to LM
butterfish.file_prompt = function(start_range, end_range, user_prompt)
  if not ensure_buffer_available() then
    return
  end
  local made_change = move_down_to_clear_line(start_range, end_range)

  -- Execute the command
  butterfish.command(
    "fileprompt",
    user_prompt,
    start_range,
    end_range,
    nil,
    butterfish.lm_smart_model,
    nil,
    not made_change)
end


-- Rewrite the selected text given instructions from the prompt
-- Args:
--   start_range    start of visual line range
--   end_range      end of visual line range
--   user_prompt    prompt to send to LLM
butterfish.rewrite = function(start_range, end_range, user_prompt)
  if not ensure_buffer_available() then
    return
  end
  local made_change = move_down_to_clear_line(start_range, end_range)

  butterfish.command(
    "rewrite",
    user_prompt,
    start_range,
    end_range,
    clean_up_empty_lines,
    butterfish.lm_smart_model,
    nil,
    not made_change)

  -- The above call is async, we put this after so that we comment out the block
  -- after the file save but before any results are streamed back
  with_temporary_modifiable(vim.api.nvim_get_current_buf(), function()
    comment_line_or_block(start_range, end_range)
  end)
end

-- Add a comment above the current line or block explaining it
butterfish.comment = function(start_range, end_range)
  if not ensure_buffer_available() then
    return
  end
  local made_change = move_up_to_clear_line(start_range, end_range)

  butterfish.command(
    "comment",
    nil,
    start_range,
    end_range,
    delete_current_line_if_empty, -- trim trailing blank line if present
    nil,
    nil,
    not made_change) -- this is not the first action in a sequence, don't undojoin
end

-- Explain a line or block of code in detail
-- - If a single line, move up and create a newline like in butterfish.comment()
-- - If a block, remove the block
-- - Then call explain
butterfish.explain = function(start_range, end_range)
  if not ensure_buffer_available() then
    return
  end
  local made_change = move_up_to_clear_line(start_range, end_range)
  butterfish.command(
    "explain",
    nil,
    start_range,
    end_range,
    delete_current_line_if_empty, -- trim trailing blank line if present
    nil,
    nil,
    not made_change) -- this is not the first action in a sequence, don't undojoin
end


-- Ask a question about the current line or block
-- This will move above the line or block and create a new line
-- It will add "Question: <prompt>" to the new line and comment it out
butterfish.question = function(start_range, end_range, user_prompt)
  if not ensure_buffer_available() then
    return
  end
  move_up_to_clear_line(start_range, end_range)

  -- Add Question: <prompt> to the new line and comment it out
  keys("n", "iQuestion: " .. user_prompt .. "<ESC>")
  comment_current_line()
  move_down_to_clear_line()

  butterfish.command(
    "question",
    user_prompt,
    start_range,
    end_range,
    delete_current_line_if_empty, -- trim trailing blank line if present
    nil,
    nil,
    false) -- this is not the first action in a sequence, don't undojoin
end


-- Attempt to fix the error on the current line
-- - Fetches the error message from the current line
-- - Fetches the 5 lines before and after the current line
-- - Comments out the current line
-- - Adds a new line below the current line
-- - Sends the error message to LLM
-- - Inserts the response at the cursor
butterfish.fix = function()
  if not ensure_buffer_available() then
    return
  end
  -- Get the current line number
  local line_number = vim.api.nvim_win_get_cursor(0)[1]

  -- Safely retrieve the error message from line diagnostics
  local line_diagnostics = vim.diagnostic.get(0, { lnum = line_number - 1 })
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

  butterfish.command("fix", error_message, context_start, context_end, nil, butterfish.lm_smart_model)
  with_temporary_modifiable(vim.api.nvim_get_current_buf(), function()
    comment_line_or_block(line_number, line_number)
  end)
end

-- Implement the next block of code based on the previous lines
-- - Get the current line number
-- - Get the previous 150 lines
-- - Call implement
butterfish.implement = function()
  if not ensure_buffer_available() then
    return
  end
  move_down_to_clear_line()
  butterfish.command("implement", nil, nil, nil)
end

local trim_trailing_empty_lines = function(lines)
  while #lines > 0 and lines[#lines] == "" do
    table.remove(lines, #lines)
  end
  return lines
end

-- Function to edit the current buffer using LLM
butterfish.edit = function(start_range, end_range, prompt)
  if not ensure_buffer_available() then
    return
  end
  -- Write the current buffer to disk
  vim.cmd("silent noautocmd w!")

  -- Set status bar to indicate the operation
  set_status_bar()

  -- Get the current file path and file type
  local filepath = vim.fn.expand("%:p")
  local filetype = vim.bo.filetype
  local bufnr = vim.api.nvim_get_current_buf()
  local line_range = get_line_range(start_range, end_range)
  local replace_start = start_range
  local replace_end = end_range

  if replace_start == nil or replace_end == nil then
    local current_line = vim.api.nvim_win_get_cursor(0)[1]
    replace_start = current_line
    replace_end = current_line
  end

  -- Create a command to send to the LLM for editing the current buffer
  local command = butterfish.script_dir ..
    "edit " ..
    filetype .. " " ..
    filepath .. " " ..
    line_range .. " " ..
    " '" .. escape_code(prompt) .. "'" ..
    " '" .. butterfish.lm_smart_model .. "'" ..
    " '" .. butterfish.lm_base_path .. "'"

  local stdout_lines = {}
  local stderr_lines = {}

  local job_id = vim.fn.jobstart(command, {
    stdout_buffered = true,
    stderr_buffered = true,

    on_stdout = function(job_id, data)
      if data == nil then
        return
      end
      for _, line in ipairs(data) do
        table.insert(stdout_lines, line)
      end
    end,

    on_stderr = function(job_id, data)
      if data == nil then
        return
      end
      for _, line in ipairs(data) do
        table.insert(stderr_lines, line)
      end
    end,

    on_exit = function(job_id, exit_code, event_type)
      vim.schedule(function()
        local was_cancelled = cancelled_jobs[job_id] == true
        if was_cancelled then
          track_job_finished(job_id)
          return
        end

        local replacement_lines = trim_trailing_empty_lines(stdout_lines)
        local error_lines = trim_trailing_empty_lines(stderr_lines)

        if exit_code ~= 0 then
          local stderr_text = table.concat(error_lines, "\n")
          if stderr_text == "" then
            stderr_text = "BFEdit failed with exit code " .. exit_code
          end
          vim.api.nvim_err_writeln(stderr_text)
          track_job_finished(job_id)
          return
        end

        if #replacement_lines == 0 then
          vim.api.nvim_err_writeln("BFEdit failed: empty model response")
          track_job_finished(job_id)
          return
        end

        with_temporary_modifiable(bufnr, function()
          if not vim.api.nvim_buf_is_valid(bufnr) then
            return
          end
          vim.api.nvim_buf_set_lines(bufnr, replace_start - 1, replace_end, false, replacement_lines)
        end)
        track_job_finished(job_id)
      end)
    end,
  })

  if not track_job_started(job_id, bufnr) then
    reset_status_bar()
  end
end

-- Cancel all active Butterfish jobs.
-- If silent is true, suppress "no active job" / "cancelled N jobs" messages.
butterfish.cancel = function(silent)
  local cancelled_count = 0
  for job_id, _ in pairs(active_jobs) do
    cancelled_jobs[job_id] = true
    vim.fn.jobstop(job_id)
    cancelled_count = cancelled_count + 1
  end

  if not silent then
    if cancelled_count == 0 then
      print("No active Butterfish job")
    else
      print("Cancelled " .. cancelled_count .. " Butterfish job(s)")
    end
  end

  return cancelled_count
end

-- Commands for each function
vim.cmd("command! -range -nargs=* BFPrompt :lua require'butterfish'.prompt(<line1>, <line2>, <q-args>)")
vim.cmd("command! -range -nargs=* BFFilePrompt :lua require'butterfish'.file_prompt(<line1>, <line2>, <q-args>)")
vim.cmd("command! -range -nargs=* BFRewrite :lua require'butterfish'.rewrite(<line1>, <line2>, <q-args>)")
vim.cmd("command! -range -nargs=* BFComment :lua require'butterfish'.comment(<line1>, <line2>)")
vim.cmd("command! -range -nargs=* BFExplain :lua require'butterfish'.explain(<line1>, <line2>)")
vim.cmd("command! -range -nargs=* BFQuestion :lua require'butterfish'.question(<line1>, <line2>, <q-args>)")
vim.cmd("command! BFFix lua require'butterfish'.fix()")
vim.cmd("command! BFImplement lua require'butterfish'.implement()")
vim.cmd("command! -range -nargs=* BFEdit :lua require'butterfish'.edit(<line1>, <line2>, <q-args>)")
vim.cmd("command! BFCancel lua require'butterfish'.cancel()")

return butterfish

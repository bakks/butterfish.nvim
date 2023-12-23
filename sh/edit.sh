#!/bin/bash

# edit.sh
# Calls the butterfish edit command, to edit a code file based on a
# prompt, using the full file as context. Edits come from LM tool use
# which replaces a range of lines with given text. There can be multiple
# edits for a single call.
# Arguments:
#   $1: filetype, e.g. go, py, js
#   $2: filepath, the path to the file to edit
#   $3: cursor (not used)
#   $4: prompt, the user's requested edits
# Output: Edits the file directly plus streams LM communication to stdout
# Example: ./hammer.sh go foobar.go
# butterfish.nvim command: :BFHammer

# This is a script for butterfish.nvim, it accepts arguments from the plugin
# constructs language model prompts, and calls Butterfish to generate a response
# using the OpenAI API. You can modify this script to change the prompt or
# swap in a different language model.

# Source common.sh from the same directory as this script
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

parse_arguments "$@"

model="gpt-4-1106-preview"
temperature=0.5

$butterfish edit -vLi -m "$model" -T "$temperature" --no-color --no-backticks "$filepath" "$prompt"


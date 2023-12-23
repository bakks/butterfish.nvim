#!/bin/bash

# edit.sh
# Arguments:
#   - filetype: the programming language of the file, e.g. go, py, js
#   - filepath: the path to the file to edit
# Output: xxxx
# Example: ./hammer.sh go foobar.go
# butterfish.nvim command: :BFHammer

# This is a script for butterfish.nvim, it accepts arguments from the plugin
# constructs language model prompts, and calls Butterfish to generate a response
# using the OpenAI API. You can modify this script to change the prompt, or
# swap in a different language model.

# Source common.sh from the same directory as this script
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

parse_arguments "$@"

model="gpt-4-1106-preview"
temperature=0.5

$butterfish edit -vLi -m "$model" -T "$temperature" --no-color --no-backticks "$filepath" "$prompt"


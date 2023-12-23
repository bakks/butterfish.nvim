#!/bin/bash

# hammer.sh
# Given output from a build or test command, attempt to fix the code
# Arguments:
#   $1: filetype, e.g. go, py, js
#   $2: filepath, the path to the file to edit
#   $3: cursor (not used)
#   $4: prompt, i.e. additional input, could be provided by the user or the plugin
# Output: Edits the given code in place, streams LM communication to stdout
# Example: ./hammer.sh go main.go 1 "Syntax error on line 10"
# butterfish.nvim command: :BFHammer

# This is a script for butterfish.nvim, it accepts arguments from the plugin
# constructs language model prompts, and calls Butterfish to generate a response
# using the OpenAI API. You can modify this script to change the prompt or
# swap in a different language model.

# Source common.sh from the same directory as this script
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

parse_arguments "$@"

prompt="I'm editing $filetype code but getting a failure. The code is close to working, edit it based on what you think my intentions are and what would be correct and working code. For example, if the problem is a syntax error, attempt to fix the syntax problem with a minimum of changes. If the problem is a test failure, try to fix the code that is causing the test failure.

\"\"\"
$prompt
\"\"\""

echo "Editing $filepath"

model="gpt-4-1106-preview"
temperature=0.5

$butterfish edit -vLi -m "$model" -T "$temperature" --no-color --no-backticks "$filepath" "$prompt"


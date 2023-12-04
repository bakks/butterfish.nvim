#!/bin/bash

# hammer.sh
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

filetype=$1
filepath=$2
hammerlog=$3
fullprompt="$errblock"$'\n\n'"That is a block of $filetype code, there is an error on the middle line. The error is: '$errmsg'. Rewrite the middle line (and only the middle line) to fix the error."

sysmsg="You are helping an expert programmer write code. Respond only with code, add succinct comments above functions and other important parts. Assume the code will be within an existing file, so don't respond with the package name or imports."

prompt1="This is a file of $filetype code. Your job is to edit it to fix the following build and test output:\n$hammerlog\n\n. In this step you can edit a specific function, call edit_function() with a specific function and a complete and detailed plan for the edits you will make."
prompt2="Using the file, the build and test output, and the plan, edit the the specific function. Only edit the target function, and only respond with code from that function."

$HOME/butterfish/bin/butterfish doubleprompt -vL -m 'gpt-3.5-turbo-1106' -T 0.5 --no-color --no-backticks --functions $HOME/butterfish.nvim/edit_function.json -p "$prompt1" -P "$prompt2" < $filepath


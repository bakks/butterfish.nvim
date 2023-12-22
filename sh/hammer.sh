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

prompt="This is a file of $filetype code, it has a problem. Your job is to edit it to fix the following build and test output:

\"\"\"
$hammerlog
\"\"\"

In this step you can edit a specific function, call edit() to make a change."

echo "Editing $filepath"

$HOME/butterfish/bin/butterfish edit -vLi -m gpt-4-1106-preview -T 0.5 --no-color --no-backticks "$filepath" "$prompt"


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

prompt="I'm editing $filetype code but getting a failure. The code is close to working, edit it based on what you think my intentions are and what would be correct and working code. For example, if the problem is a syntax error, attempt to fix the syntax problem with a minimum of changes. If the problem is a test failure, try to fix the code that is causing the test failure.

\"\"\"
$hammerlog
\"\"\""

echo "Editing $filepath"

$butterfish edit -vLi -m gpt-4-1106-preview -T 0.5 --no-color --no-backticks "$filepath" "$prompt"


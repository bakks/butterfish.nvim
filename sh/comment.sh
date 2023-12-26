#!/bin/bash

# comment.sh
# Generates a comment for a line or block of code
# Arguments:
#   $1: filetype, e.g. go, py, js
#   $2: filepath, the path to the file to edit
#   $3: cursor, either a line number (42) or a range (42-45)
#   $4: prompt (not used)
#   $5: model, the language model to use
#   $6: base path, the base url for the language model, e.g. https://api.openai.com/v1
# Output: Generates a comment appropriate for the code line/block in question,
#        streams it to stdout
# Example: ./comment.sh go ./foo.go 5-10
# butterfish.nvim command: :BFComment

# This is a script for butterfish.nvim, it accepts arguments from the plugin
# constructs language model prompts, and calls Butterfish to generate a response
# using the OpenAI API. You can modify this script to change the prompt or
# swap in a different language model.

# Source common.sh from the same directory as this script
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

parse_arguments "$@"

fullprompt="$filecontents

That is a code file, below is a block of code from that file, please explain the behavior of this code, be precise and very succinct. You must comment out the answer in the style of the language. Do not repeat the code, write a comment.

\"\"\"
$fileblock
\"\"\"
"

sysmsg="You are helping an expert programmer write code. Respond only with code, add succinct comments above functions and other important parts. Assume the code will be within an existing file, so don't respond with the package name or imports."

lm_command "$sysmsg" "$fullprompt"



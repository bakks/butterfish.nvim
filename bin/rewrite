#!/bin/bash

# rewrite.sh
# Given the content of a code file and a specific block of code from
# that file, rewrite the block of code.
# Arguments:
#   $1: filetype
#   $2: filepath
#   $3: cursor, either a line number (42) or a range (42-45)
#   $4: prompt, i.e. additional input, could be provided by the user or the plugin
# Output: Rewrites the given code with comments explaining each line, streams
#         it to stdout
# Example: ./rewrite.sh go ./main.go 5-10 "Simplify this function"
# butterfish.nvim command: :BFRewrite <prompt>

# This is a script for butterfish.nvim, it accepts arguments from the plugin
# constructs language model prompts, and calls Butterfish to generate a response
# using the OpenAI API. You can modify this script to change the prompt, or
# swap in a different language model.

# Source common.sh from the same directory as this script
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

parse_arguments "$@"

fullprompt="\"\"\"
$fileblock
\"\"\"

Rewrite that $filetype code with this instruction: $prompt"

sysmsg="You are helping an expert programmer write code. Respond only with code, add succinct comments above functions and other important parts. Assume the code will be within an existing file, so don't respond with the package name or imports."

lm_command "$sysmsg" "$fullprompt"


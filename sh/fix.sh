#!/bin/bash

# fix.sh
# Arguments:
#   - filetype: the programming language of the file, e.g. go, py, js
#   - codeblock: a block of code to find and fix a single-line error in
# Output: Identifies an error in a block of code, rewrites the line in
#        question, streams it to stdout
# Example: ./fix.sh go "a := 1 + 2\nb := 1 + '2'\nc := 5 + 6"
# butterfish.nvim command: :BFFix

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

That is a block of $filetype code, there is an error on the middle line. The error is: '$prompt'. Rewrite the middle line (and only the middle line) to fix the error."

sysmsg="You are helping an expert programmer write code. Respond only with code, add succinct comments above functions and other important parts. Assume the code will be within an existing file, so don't respond with the package name or imports."

lm_command "$sysmsg" "$fullprompt"


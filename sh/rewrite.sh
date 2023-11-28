#!/bin/bash

# rewrite.sh
# Arguments:
#   - filetype: the programming language of the file, e.g. go, py, js
#   - codeblock: code line/block to rewrite
#   - prompt: instructions for rewriting the code
# Output: Rewrites the given code with comments explaining each line, streams
#         it to stdout
# Example: ./rewrite.sh go "a := 1 + 2 + 3 + 4.0" "Simplify this expression"
# butterfish.nvim command: :BFRewrite <prompt>

# This is a script for butterfish.nvim, it accepts arguments from the plugin
# constructs language model prompts, and calls Butterfish to generate a response
# using the OpenAI API. You can modify this script to change the prompt, or
# swap in a different language model.

# Source common.sh from the same directory as this script
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# accept the prompt as the first argument
filetype=$1
block=$2
prompt=$3
fullprompt="$block"$'\n\n'"Rewrite that $filetype code (and only that code) based on this instruction: $prompt"

sysmsg="You are helping an expert programmer write code. Respond only with code, add succinct comments above functions and other important parts. Assume the code will be within an existing file, so don't respond with the package name or imports."

lm_command "$sysmsg" "$fullprompt"


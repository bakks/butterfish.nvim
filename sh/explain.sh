#!/bin/bash

# explain.sh
# Arguments:
#   - filepath: unix file path, can be relative
#   - codeblock: code block to explain
# Output: Rewrites the given code with comments explaining each line, streams
#         it to stdout
# Example: ./explain.sh ./foo.go "func fibo(n int) int {\n"
# butterfish.nvim command: :BFExplain

# This is a script for butterfish.nvim, it accepts arguments from the plugin
# constructs language model prompts, and calls Butterfish to generate a response
# using the OpenAI API. You can modify this script to change the prompt, or
# swap in a different language model.

# Source common.sh from the same directory as this script
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# accept the prompt as the first argument
filepath=$1
block=$2
filecontents=$(cat $filepath)
fullprompt="$filecontents"$'\n\n'"That is a code file, below is code from that file, the user wants a detailed explanation of that code. Rewrite the code below with a detailed explanation above each line. For example, there should be a comment above each function explaining what each argument means, like 'foo(\nbar int  - directs how many\n)'. If multiple functions are wrapped/called on the same line you should describe each separately."$'\n\n'"$block"

sysmsg="You are helping an expert programmer write code. Respond only with code, add succinct comments above functions and other important parts. Assume the code will be within an existing file, so don't respond with the package name or imports."

lm_command "$sysmsg" "$fullprompt"



#!/bin/bash

# comment.sh
# Arguments:
#   - filepath: unix file path, can be relative
#   - codeblock: code block to generate a comment for
# Output: Generates a comment appropriate for the code line/block in question,
#        streams it to stdout
# Example: ./comment.sh ./foo.go "func fibo(n int) int {\n"
# butterfish.nvim command: :BFComment

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
fullprompt="$filecontents"$'\n\n'"That is a code file, below is a block of code from that file, please explain the behavior of this code, be precise and very succinct. You must comment out the answer in the style of the language. Do not repeat the code, write a comment."$'\n\n'"$block"

sysmsg="You are helping an expert programmer write code. Respond only with code, add succinct comments above functions and other important parts. Assume the code will be within an existing file, so don't respond with the package name or imports."

lm_command "$sysmsg" "$fullprompt"



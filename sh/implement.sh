#!/bin/bash

# implement.sh
# Arguments:
#   - filetype: the programming language of the file, e.g. go, py, js
#   - codeblock: the code leading up to the block we want to implement
# Output: Generates a block completion using GPT-4, meaning given preceding code
#        it will generate the next block of code, streams it to stdout
# Example: ./implement.sh go "func fibo(n int) int {\n"
# butterfish.nvim command: :BFImplement

# This is a script for butterfish.nvim, it accepts arguments from the plugin
# constructs language model prompts, and calls Butterfish to generate a response
# using the OpenAI API. You can modify this script to change the prompt, or
# swap in a different language model.

# Source common.sh from the same directory as this script
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

filetype=$1
codeblock=$2
fullprompt="$codeblock"$'\n\n'"That is a block of $filetype code, your job is to implement the next block. For example if it ends with a function declaration, implement that function. If it ends half-way through a function, finish the function. Complete the code."

sysmsg="You are helping an expert programmer write code. Respond only with code, add succinct comments above functions and other important parts. Assume the code will be within an existing file, so don't respond with the package name or imports."

lm_command "$sysmsg" "$fullprompt" gpt-4


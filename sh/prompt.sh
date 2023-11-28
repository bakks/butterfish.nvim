#!/bin/bash

# prompt.sh
# Arguments:
#   - filetype: the programming language of the file, e.g. go, py, js
#   - prompt: the prompt to send to LLM
# Output: Streams a response by printing to stdout
# Example: ./prompt.sh go "A function that returns a string 'hello world'"
# butterfish.nvim command: :BFPrompt <prompt>

# This is a script for butterfish.nvim, it accepts arguments from the plugin
# constructs language model prompts, and calls Butterfish to generate a response
# using the OpenAI API. You can modify this script to change the prompt, or
# swap in a different language model.

# Source common.sh from the same directory as this script
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

filetype=$1
prompt=$2

sysmsg="You are helping an expert programmer write code. Respond only with code, add succinct comments above functions and other important parts. Assume the code will be within an existing file, so don't respond with the package name or imports. Assume the programming language is $filetype"

lm_command "$sysmsg" "$prompt"


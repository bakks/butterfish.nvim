#!/bin/bash

# prompt.sh
# Run a simple LM prompt, which requests output in a specific
# programming language but does not provide any context.
# Arguments:
#   $1: filetype, e.g. go, py, js
#   $2: filepath (not used)
#   $3: cursor (not used)
#   $4: prompt, i.e. additional input, could be provided by the user or the plugin
#   $5: model, the language model to use
#   $6: base path, the base url for the language model, e.g. https://api.openai.com/v1
# Output: Streams a response by printing to stdout
# Example: ./prompt.sh go ./main.go 30 "Add function that returns a string 'hello world'"
# butterfish.nvim command: :BFPrompt <prompt>

# This is a script for butterfish.nvim, it accepts arguments from the plugin
# constructs language model prompts, and calls Butterfish to generate a response
# using the OpenAI API. You can modify this script to change the prompt or
# swap in a different language model.

# Source common.sh from the same directory as this script
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

parse_arguments "$@"

sysmsg="You are helping an expert programmer write code. Respond only with code, add succinct comments above functions and other important parts. Assume the code will be within an existing file, so don't respond with the package name or imports. Assume the programming language is $filetype"

lm_command "$sysmsg" "$prompt"

